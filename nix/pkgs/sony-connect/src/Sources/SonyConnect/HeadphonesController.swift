import Foundation

final class HeadphonesController {
    enum NCMode: String {
        case noiseCancelling, ambient, off
    }

    struct EqPreset {
        let id: UInt8
        let name: String
    }

    struct State {
        var isConnected: Bool = false       // SPP control channel is open
        var deviceReachable: Bool = false   // headphones present at the BT (ACL) level
        var touchSensorEnabled: Bool? = nil
        var ncMode: NCMode? = nil
        var speakToChatEnabled: Bool? = nil
        var batteryLevel: Int? = nil
        var batteryCharging: Bool = false
        var eqPresets: [EqPreset] = []
        var eqCurrentPresetId: UInt8? = nil
        var eqBands: [Int] = []
        var autoOffOption: AutoPowerOffOption = .off
        var statusDescription: String = "Disconnected"
        var ambientLevel: Int = 20          // 0...20, meaningful only while ncMode == .ambient
        var ambientFocusOnVoice: Bool = false
    }

    private(set) var state = State() {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    private let bluetooth = BluetoothClient()
    private let parser = SonyFrameParser()
    private let autoOff = AutoPowerOff()
    private let media = MediaController()
    private let audioMonitor = AudioActivityMonitor(nameHints: SupportedDevices.nameHints)
    private let policy: ConnectionPolicy
    private var outgoingSequence: UInt8 = 0
    private var initialized = false
    private var awaitingInitResponse = false
    private var deviceName: String = "headphones"
    private var isXM6: Bool { deviceName.contains("WH-1000XM6") }

    // Sony MDR V1 opcodes (from JADX decompile of Sony Headphones Connect
    // 9.3.0, package com.sony.songpal.tandemfamily.message.mdr.v1.table1).
    // 0xD0..0xD9 = GENERAL_SETTING_* family.
    // Inside GENERAL_SETTING_* payloads, second byte is the "GsInquiredType"
    // = slot identifier: D1 = GS1, D2 = GS2, D3 = GS3.
    // Sony stores TOUCH_PANEL_SETTING in one of these slots, chosen per-firmware.
    private enum Opcode {
        static let initRequest: UInt8 = 0x00
        static let initReply: UInt8 = 0x01
        static let batteryGet: UInt8 = 0x10
        static let batteryRet: UInt8 = 0x11
        static let batteryNotify: UInt8 = 0x13
        static let batterySingleInquiredType: UInt8 = 0x00   // BatteryInquiredType.BATTERY
        static let commonSetPowerOff: UInt8 = 0x22
        static let eqGetCapability: UInt8 = 0x50
        static let eqRetCapability: UInt8 = 0x51
        static let eqGetParam: UInt8 = 0x56
        static let eqRetParam: UInt8 = 0x57
        static let eqSetParam: UInt8 = 0x58
        static let eqNotifyParam: UInt8 = 0x59
        static let eqPresetInquiredType: UInt8 = 0x01        // EqEbbInquiredType.PRESET_EQ
        static let eqPresetCustom: UInt8 = 0xA0              // EqPresetId.CUSTOM
        static let eqPresetUnspecified: UInt8 = 0xFF         // EqPresetId.UNSPECIFIED
        static let powerOffFixedValue: UInt8 = 0x00
        static let powerOffUserOff: UInt8 = 0x01
        static let ncasmGet: UInt8 = 0x66
        static let ncasmRet: UInt8 = 0x67
        static let ncasmSet: UInt8 = 0x68
        static let ncasmNotify: UInt8 = 0x69
        static let ncasmCombinedInquiredType: UInt8 = 0x02   // NOISE_CANCELLING_AND_AMBIENT_SOUND_MODE
        static let gsGetCapability: UInt8 = 0xD0
        static let gsRetCapability: UInt8 = 0xD1
        static let touchSensorGet: UInt8 = 0xD6
        static let touchSensorRet: UInt8 = 0xD7
        static let touchSensorSet: UInt8 = 0xD8
        static let touchSensorNotify: UInt8 = 0xD9
        static let gs1SubId: UInt8 = 0xD1
        static let gs2SubId: UInt8 = 0xD2
        static let gs3SubId: UInt8 = 0xD3
        static let systemGet: UInt8 = 0xF6
        static let systemRet: UInt8 = 0xF7
        static let systemSet: UInt8 = 0xF8
        static let systemNotify: UInt8 = 0xF9
        static let smartTalkingMode: UInt8 = 0x05            // SystemInquiredType.SMART_TALKING_MODE
        static let smartTalkingParamModeOnOff: UInt8 = 0x01
    }

    private var touchPanelSlot: UInt8?
    private var touchPanelIsListType: Bool = false
    private var ncSettingType: UInt8 = 0x02  // device-reported; default DUAL_SINGLE_OFF for WH-1000XM4
    private var asmSettingType: UInt8 = 0x01 // device-reported; default LEVEL_ADJUSTMENT
    private var asmId: UInt8 = 0x00          // ambient mode: 0x00 NORMAL, 0x01 VOICE (Focus on Voice)
    private var currentAmbientLevel: UInt8 = HeadphonesController.maxAmbientLevel  // retained across NC-mode switches
    static let maxAmbientLevel: UInt8 = 20

    init() {
        policy = ConnectionPolicy(audio: audioMonitor)
        bluetooth.onStatus = { [weak self] s in self?.handleStatus(s) }
        bluetooth.onData = { [weak self] data in self?.handleIncoming(data) }
        autoOff.onShouldPowerOff = { [weak self] in self?.sendPowerOff() }
        autoOff.onOptionChanged = { [weak self] option in
            self?.state.autoOffOption = option
        }
        policy.onShouldConnect = { [weak self] in self?.bluetooth.connect() }
        policy.onShouldDisconnect = { [weak self] in
            guard let self = self else { return }
            // If auto-power-off is armed, keep the SPP channel open so its
            // 30-minute idle timer can actually reach the device and send
            // the power-off command. Otherwise the 5-minute battery-saver
            // disconnect would kill the timer first.
            if self.autoOff.isEnabled {
                FileLogger.shared.log("policy", "idle disconnect skipped — auto-power-off armed")
                return
            }
            FileLogger.shared.log("policy", "disconnecting RFCOMM to save headphones battery")
            self.bluetooth.disconnect()
        }
        bluetooth.onReachabilityChange = { [weak self] reachable, name in
            self?.handleReachability(reachable, name: name)
        }
        state.autoOffOption = autoOff.option
        bluetooth.startReachabilityMonitoring()
        policy.start()
    }

    private func handleReachability(_ reachable: Bool, name: String?) {
        if let name = name { deviceName = name }
        state.deviceReachable = reachable
        // Keep the status line consistent with the icon while the SPP
        // channel is closed: "(idle)" when the device is still around,
        // "Disconnected" when it's gone.
        if !state.isConnected {
            state.statusDescription = reachable ? "\(deviceName) (idle)" : "Disconnected"
        }
    }

    var autoOffOption: AutoPowerOffOption {
        get { autoOff.option }
        set { autoOff.option = newValue }
    }

    func powerOff() {
        guard initialized else { return }
        sendPowerOff()
    }

    func connect() {
        // User clicked Reconnect — counts as user activity.
        policy.userActivity()
    }

    // Called when the menu is about to open. The policy treats this as
    // user activity: connects on demand if currently idle-disconnected
    // and pushes back the next idle-disconnect.
    func userActivity() {
        policy.userActivity()
    }

    private func resetSessionState() {
        initialized = false
        awaitingInitResponse = false
        outgoingSequence = 0
        parser.reset()
        touchPanelSlot = nil
        touchPanelIsListType = false
        ncSettingType = 0x02
        asmSettingType = 0x01
        asmId = 0x00
    }

    func toggleTouchSensor() {
        guard initialized else {
            FileLogger.shared.log("cmd", "toggle ignored: not initialized")
            return
        }
        let next = !(state.touchSensorEnabled ?? false)
        sendTouchSensor(enabled: next)
        state.touchSensorEnabled = next
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendTouchSensorGet()
        }
    }

    func setNCMode(_ mode: NCMode) {
        guard initialized else { return }
        sendNcasmSet(mode: mode)
        state.ncMode = mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendNcasmGet()
        }
    }

    func setAmbientLevel(_ level: Int) {
        guard initialized else { return }
        let clamped = UInt8(clamping: min(max(level, 0), Int(Self.maxAmbientLevel)))
        currentAmbientLevel = clamped
        state.ambientLevel = Int(clamped)
        guard state.ncMode == .ambient else { return }
        sendNcasmSet(mode: .ambient)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendNcasmGet()
        }
    }

    func setAmbientFocusOnVoice(_ enabled: Bool) {
        guard initialized else { return }
        asmId = enabled ? 0x01 : 0x00
        state.ambientFocusOnVoice = enabled
        guard state.ncMode == .ambient else { return }
        sendNcasmSet(mode: .ambient)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendNcasmGet()
        }
    }

    func toggleSpeakToChat() {
        guard initialized else { return }
        let next = !(state.speakToChatEnabled ?? false)
        sendSpeakToChat(enabled: next)
        state.speakToChatEnabled = next
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendSpeakToChatGet()
        }
    }

    func setEqPreset(_ id: UInt8) {
        guard initialized else { return }
        sendPayload([Opcode.eqSetParam, isXM6 ? 0x00 : Opcode.eqPresetInquiredType, id, 0x00],
                    label: "EQ SET preset=0x\(String(format: "%02X", id))")
        state.eqCurrentPresetId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendEqGet()
        }
    }

    func setEqBands(_ bands: [Int]) {
        guard initialized, !bands.isEmpty else { return }
        let offset = isXM6 && bands.count == 10 ? 6 : 10
        var payload: [UInt8] = [Opcode.eqSetParam,
                                isXM6 ? 0x00 : Opcode.eqPresetInquiredType,
                                isXM6 ? Opcode.eqPresetCustom : Opcode.eqPresetUnspecified,
                                UInt8(bands.count)]
        payload.append(contentsOf: bands.map { UInt8(clamping: $0 + offset) })
        sendPayload(payload, label: "EQ SET custom bands=\(bands)")
        state.eqCurrentPresetId = Opcode.eqPresetCustom
        state.eqBands = bands
    }

    private func sendTouchSensor(enabled: Bool) {
        let slot = touchPanelSlot ?? Opcode.gs1SubId  // best guess if not yet discovered
        let settingType: UInt8 = touchPanelIsListType ? 0x02 : 0x01
        sendPayload([Opcode.touchSensorSet, slot, settingType,
                     enabled ? 0x01 : 0x00],
                    label: "TouchSensor SET=\(enabled ? "ON" : "OFF") slot=\(String(format: "0x%02X", slot)) type=\(settingType == 2 ? "LIST" : "BOOL")")
    }

    private func sendTouchSensorGet() {
        let slot = touchPanelSlot ?? Opcode.gs1SubId
        sendPayload([Opcode.touchSensorGet, slot],
                    label: "TouchSensor GET slot=\(String(format: "0x%02X", slot))")
    }

    private func sendNcasmGet() {
        sendPayload([Opcode.ncasmGet, isXM6 ? 0x19 : Opcode.ncasmCombinedInquiredType],
                    label: "NCASM GET")
    }

    private func sendNcasmSet(mode: NCMode) {
        if isXM6 {
            let level = max(UInt8(1), currentAmbientLevel)
            let payload: [UInt8]
            switch mode {
            case .noiseCancelling: payload = [0x68, 0x19, 0x01, 0x01, 0x00, 0x00, level, 0x00, 0x00]
            case .ambient: payload = [0x68, 0x19, 0x01, 0x01, 0x01, asmId, level, 0x00, 0x00]
            case .off: payload = [0x68, 0x19, 0x01, 0x00, 0x00, 0x00, level, 0x00, 0x00]
            }
            sendPayload(payload, label: "NCASM SET=\(mode.rawValue)")
            return
        }
        let effect: UInt8 = mode == .off ? 0x00 : 0x11
        let ncValue: UInt8 = mode == .noiseCancelling ? 0x02 : 0x00
        let asmLevel: UInt8 = mode == .ambient ? currentAmbientLevel : 0
        sendPayload([Opcode.ncasmSet, Opcode.ncasmCombinedInquiredType, effect, ncSettingType,
                     ncValue, asmSettingType, asmId, asmLevel], label: "NCASM SET=\(mode.rawValue)")
    }

    private func sendSpeakToChatGet() {
        sendPayload([Opcode.systemGet, isXM6 ? 0x0C : Opcode.smartTalkingMode], label: "SpeakToChat GET")
    }

    private func sendSpeakToChat(enabled: Bool) {
        let payload = isXM6
            ? [Opcode.systemSet, 0x0C, enabled ? 0x00 : 0x01, 0x01]
            : [Opcode.systemSet, Opcode.smartTalkingMode, Opcode.smartTalkingParamModeOnOff, enabled ? 0x01 : 0x00]
        sendPayload(payload, label: "SpeakToChat SET=\(enabled ? "ON" : "OFF")")
    }

    private func sendPowerOff() {
        media.pause()
        let payload = isXM6 ? [0x24, 0x03, 0x01] : [Opcode.commonSetPowerOff, Opcode.powerOffFixedValue, Opcode.powerOffUserOff]
        sendPayload(payload, label: "POWER_OFF")
    }

    private func queryGeneralSettingCapabilities() {
        let slots: [UInt8] = [Opcode.gs1SubId, Opcode.gs2SubId, Opcode.gs3SubId]
        for (i, slot) in slots.enumerated() {
            let delay = 0.3 + Double(i) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.sendPayload([Opcode.gsGetCapability, slot, 0x00],
                                  label: "GS GET_CAPABILITY slot=\(String(format: "0x%02X", slot))")
            }
        }
    }

    private func sendInit() {
        if isXM6 {
            completeInit()
            return
        }
        awaitingInitResponse = true
        sendPayload([Opcode.initRequest, 0x00], label: "INIT_REQUEST")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, self.awaitingInitResponse else { return }
            self.sendPayload([0x06, 0x14, 0x01, 0x00, 0x00, 0x00, 0x00], label: "INIT_2_REQUEST")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.awaitingInitResponse, !self.initialized else { return }
            FileLogger.shared.log("state", "INIT timeout — completing anyway")
            self.completeInit()
        }
    }

    private func completeInit() {
        guard !initialized else { return }
        initialized = true
        awaitingInitResponse = false
        state.isConnected = true
        state.statusDescription = "Connected: \(deviceName)"
        FileLogger.shared.log("state", "INIT complete, discovering features")
        if isXM6 {
            state.eqPresets = [
                EqPreset(id: 0x00, name: "Off"), EqPreset(id: 0x30, name: "Heavy"),
                EqPreset(id: 0x31, name: "Clear"), EqPreset(id: 0x32, name: "Hard"),
                EqPreset(id: 0x33, name: "Soft"), EqPreset(id: 0xA0, name: "Custom"),
            ]
            let xm6InitPayloads: [[UInt8]] = [[0x00, 0x00], [0x06, 0x00], [0x22, 0x00],
                                               [0x66, 0x19], [0x56, 0x00], [0xF6, 0x0C]]
            for payload in xm6InitPayloads {
                sendPayload(payload, label: "XM6 INIT")
            }
            autoOff.arm(deviceName: deviceName)
            return
        }
        queryGeneralSettingCapabilities()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.sendNcasmGet() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in self?.sendSpeakToChatGet() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { [weak self] in self?.sendBatteryGet() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { [weak self] in self?.sendEqCapabilityGet() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [weak self] in self?.sendEqGet() }
        autoOff.arm(deviceName: deviceName)
    }

    private func sendBatteryGet() {
        sendPayload([isXM6 ? 0x22 : Opcode.batteryGet, Opcode.batterySingleInquiredType], label: "BATTERY GET")
    }

    private func sendEqCapabilityGet() {
        guard !isXM6 else { return }
        sendPayload([Opcode.eqGetCapability, Opcode.eqPresetInquiredType, 0x00], label: "EQ GET_CAPABILITY")
    }

    private func sendEqGet() {
        sendPayload([Opcode.eqGetParam, isXM6 ? 0x00 : Opcode.eqPresetInquiredType], label: "EQ GET")
    }

    private func sendPayload(_ payload: [UInt8], label: String) {
        // Suppress sends if the BT layer has dropped — avoids a flood of
        // "NO CHANNEL" lines after a mid-init disconnect.
        guard case .connected = bluetooth.status else {
            FileLogger.shared.log("cmd", "skip \(label): not connected")
            return
        }
        let packet = SonyPacket(dataType: .command1,
                                sequence: outgoingSequence,
                                payload: payload)
        outgoingSequence ^= 1
        let hex = payload.map { String(format: "%02X", $0) }.joined(separator: " ")
        FileLogger.shared.log("cmd", "\(label) payload=[\(hex)]")
        bluetooth.send(SonyFraming.encode(packet))
    }

    private func handleStatus(_ status: BluetoothClient.Status) {
        switch status {
        case .disconnected:
            resetSessionState()
            autoOff.disarm()
            policy.setCurrentlyConnected(false)
            state.isConnected = false
            state.touchSensorEnabled = nil
            state.ncMode = nil
            state.speakToChatEnabled = nil
            state.batteryLevel = nil
            state.batteryCharging = false
            state.eqPresets = []
            state.eqCurrentPresetId = nil
            state.eqBands = []
            // Device may still be present (we just closed SPP for battery
            // saving) — reflect that instead of a flat "Disconnected".
            state.statusDescription = state.deviceReachable ? "\(deviceName) (idle)" : "Disconnected"
        case .searching, .connecting:
            // Transient. Don't overwrite the current statusDescription —
            // it lingers as "Disconnected" until we actually succeed.
            // This avoids the misleading "Connecting to WH-1000XM4…"
            // shown while IOBluetooth is timing out an unreachable
            // device.
            state.isConnected = false
            if case let .connecting(name) = status {
                deviceName = name
            }
        case .connected(let name):
            resetSessionState()
            deviceName = name
            policy.setCurrentlyConnected(true)
            state.isConnected = false
            state.deviceReachable = true
            state.statusDescription = "Initializing \(name)..."
            sendInit()
        case .failed:
            resetSessionState()
            autoOff.disarm()
            policy.setCurrentlyConnected(false)
            state.isConnected = false
            state.touchSensorEnabled = nil
            state.ncMode = nil
            state.speakToChatEnabled = nil
            state.batteryLevel = nil
            state.batteryCharging = false
            state.eqPresets = []
            state.eqCurrentPresetId = nil
            state.eqBands = []
            state.statusDescription = state.deviceReachable ? "\(deviceName) (idle)" : "Disconnected"
        }
    }

    private func handleIncoming(_ data: Data) {
        let packets = parser.feed(data)
        for packet in packets {
            let hex = packet.payload.map { String(format: "%02X", $0) }.joined(separator: " ")
            FileLogger.shared.log("packet", "RX type=0x\(String(format: "%02X", packet.dataType.rawValue)) seq=\(packet.sequence) payload=[\(hex)]")
            if packet.dataType != .ack {
                let ack = SonyPacket(dataType: .ack,
                                     sequence: packet.sequence ^ 1,
                                     payload: [])
                bluetooth.send(SonyFraming.encode(ack))
            }
            interpret(packet)
        }
    }

    private func interpret(_ packet: SonyPacket) {
        guard packet.dataType == .command1, let opcode = packet.payload.first else {
            return
        }
        // Canonical V1 INIT_REPLY (0x01 ...) OR any state-dump packet that
        // arrives after we sent INIT_REQUEST both signal "device is ready".
        if awaitingInitResponse {
            completeInit()
        }
        switch opcode {
        case Opcode.gsRetCapability:
            parseGsCapability(packet.payload)
        case Opcode.batteryRet, Opcode.batteryNotify, 0x23, 0x25:
            parseBattery(packet.payload)
        case Opcode.eqRetCapability:
            parseEqCapability(packet.payload)
        case Opcode.eqRetParam, Opcode.eqNotifyParam:
            parseEqParam(packet.payload)
        case Opcode.ncasmRet, Opcode.ncasmNotify:
            parseNcasm(packet.payload)
        case Opcode.systemRet, Opcode.systemNotify:
            parseSystem(packet.payload)
        case Opcode.touchSensorRet:
            if packet.payload.count >= 4 {
                let slot = packet.payload[1]
                let type = packet.payload[2]
                let raw = packet.payload[3]
                FileLogger.shared.log("state", "GS RET slot=\(String(format: "0x%02X", slot)) type=\(type) value=\(String(format: "0x%02X", raw))")
                if slot == (touchPanelSlot ?? 0xFF) {
                    let enabled = raw != 0
                    state.touchSensorEnabled = enabled
                    FileLogger.shared.log("state", "TouchSensor RET = \(enabled ? "ON" : "OFF")")
                }
            }
        case Opcode.touchSensorNotify:
            if packet.payload.count >= 4 {
                let slot = packet.payload[1]
                let raw = packet.payload[3]
                FileLogger.shared.log("state", "GS NTFY slot=\(String(format: "0x%02X", slot)) value=\(String(format: "0x%02X", raw))")
            }
        default:
            break
        }
    }

    private func parseGsCapability(_ payload: [UInt8]) {
        // Format: [D1][slot][stringFormat][nameLen][name...][descLen][desc...][gsSettingType][listData?]
        guard payload.count >= 5 else {
            FileLogger.shared.log("state", "GS RET_CAPABILITY too short")
            return
        }
        let slot = payload[1]
        let nameFormat = payload[2]
        let nameLen = Int(payload[3])
        guard payload.count >= 4 + nameLen + 1 else { return }
        let nameBytes = Array(payload[4..<(4 + nameLen)])
        let name = String(bytes: nameBytes, encoding: .ascii) ?? "<bad>"

        let descLenIdx = 4 + nameLen
        let descLen = Int(payload[descLenIdx])
        let descEnd = descLenIdx + 1 + descLen
        guard payload.count > descEnd else { return }
        let settingType = payload[descEnd]
        let typeName = settingType == 1 ? "BOOLEAN" : settingType == 2 ? "LIST" : "?"

        FileLogger.shared.log("state",
            "GS slot=\(String(format: "0x%02X", slot)) name='\(name)' nameFormat=\(nameFormat) settingType=\(typeName)")

        // ENUM_NAME (format=2) + name="TOUCH_PANEL_SETTING" identifies the slot.
        if nameFormat == 0x02 && name == "TOUCH_PANEL_SETTING" {
            touchPanelSlot = slot
            touchPanelIsListType = (settingType == 2)
            FileLogger.shared.log("state",
                "→ Touch panel discovered at slot \(String(format: "0x%02X", slot)), type=\(typeName)")
            // Now that we know the slot, query the current state.
            sendTouchSensorGet()
        }
    }

    private func parseNcasm(_ payload: [UInt8]) {
        if isXM6, payload.count >= 8, payload[1] == 0x19 {
            let fields = payload.count >= 9 ? Array(payload[3...]) : Array(payload[2...])
            guard fields.count >= 4 else { return }
            let effect = fields[0]
            let mode = effect == 0x00 ? NCMode.off : (fields[1] == 0x01 ? .ambient : .noiseCancelling)
            currentAmbientLevel = max(UInt8(1), fields[3])
            state.ncMode = mode
            state.ambientLevel = Int(currentAmbientLevel)
            state.ambientFocusOnVoice = fields[2] == 0x01
            return
        }
        guard payload.count >= 8, payload[1] == Opcode.ncasmCombinedInquiredType else { return }
        let effect = payload[2]
        ncSettingType = payload[3]
        let ncValue = payload[4]
        asmSettingType = payload[5]
        asmId = payload[6]
        let asmLevel = payload[7]
        if asmLevel > 0 { currentAmbientLevel = asmLevel }
        state.ncMode = effect == 0x00 ? .off : (ncValue != 0x00 ? .noiseCancelling : (asmLevel > 0 ? .ambient : .off))
        state.ambientLevel = Int(currentAmbientLevel)
        state.ambientFocusOnVoice = asmId == 0x01
    }

    private func parseBattery(_ payload: [UInt8]) {
        // RET / NOTIFY for single-battery devices:
        // [0]=opcode 0x11/0x13, [1]=BatteryInquiredType (0=BATTERY),
        // [2]=level (0..100), [3]=charging status (0 no, 1 yes, F0 unknown)
        guard payload.count >= 4,
              payload[1] == Opcode.batterySingleInquiredType else { return }
        let level = Int(payload[2])
        let charging = payload[3] == 0x01
        state.batteryLevel = level
        state.batteryCharging = charging
        FileLogger.shared.log("state", "Battery = \(level)% charging=\(charging)")
    }

    private func parseEqCapability(_ payload: [UInt8]) {
        // [0]=0x51 [1]=inquiredType [2]=bandCount [3]=levelSteps
        // [4]=presetCount, then per preset: [presetId][nameLen][name…]
        guard payload.count >= 5, payload[1] == Opcode.eqPresetInquiredType else { return }
        let presetCount = Int(payload[4])
        var presets: [EqPreset] = []
        var i = 5
        for _ in 0..<presetCount {
            guard i + 1 < payload.count else { break }
            let id = payload[i]
            let nameLen = Int(payload[i + 1])
            let nameStart = i + 2
            let nameEnd = nameStart + nameLen
            guard nameEnd <= payload.count else { break }
            let capName = nameLen > 0
                ? String(bytes: payload[nameStart..<nameEnd], encoding: .utf8)
                : nil
            let name = (capName?.isEmpty == false) ? capName! : Self.fallbackPresetName(id)
            presets.append(EqPreset(id: id, name: name))
            i = nameEnd
        }
        // Drop the USER_SETTING1…5 slots (0xA1–0xA5) — not useful here.
        presets.removeAll { $0.id >= 0xA1 && $0.id <= 0xA5 }
        // Move the manually-editable "Custom" preset to the very end of
        // the list — it's the one the band sliders write to.
        if let idx = presets.firstIndex(where: { $0.id == Opcode.eqPresetCustom }) {
            presets.append(presets.remove(at: idx))
        }
        state.eqPresets = presets
        FileLogger.shared.log("state", "EQ presets: \(presets.map { "\($0.name)=0x\(String(format: "%02X", $0.id))" }.joined(separator: ", "))")
    }

    private func parseEqParam(_ payload: [UInt8]) {
        guard payload.count >= 4, payload[1] == (isXM6 ? 0x00 : Opcode.eqPresetInquiredType) else { return }
        let presetId = payload[2]
        let nBands = Int(payload[3])
        let offset = isXM6 && nBands == 10 ? 6 : 10
        let bands = 4 + nBands <= payload.count
            ? payload[4..<(4 + nBands)].map { Int($0) - offset }
            : []
        state.eqCurrentPresetId = presetId
        state.eqBands = bands
        FileLogger.shared.log("state", "EQ current=0x\(String(format: "%02X", presetId)) bands=\(bands)")
    }

    static func fallbackPresetName(_ id: UInt8) -> String {
        switch id {
        case 0x00: return "Off"
        case 0x01: return "Rock"
        case 0x02: return "Pop"
        case 0x03: return "Jazz"
        case 0x04: return "Dance"
        case 0x05: return "EDM"
        case 0x06: return "R&B / Hip-Hop"
        case 0x07: return "Acoustic"
        case 0x10: return "Bright"
        case 0x11: return "Excited"
        case 0x12: return "Mellow"
        case 0x13: return "Relaxed"
        case 0x14: return "Vocal"
        case 0x15: return "Treble Boost"
        case 0x16: return "Bass Boost"
        case 0x17: return "Speech"
        case 0xA0: return "Custom"
        case 0xA1: return "User 1"
        case 0xA2: return "User 2"
        case 0xA3: return "User 3"
        case 0xA4: return "User 4"
        case 0xA5: return "User 5"
        default: return String(format: "Preset 0x%02X", id)
        }
    }

    private func parseSystem(_ payload: [UInt8]) {
        guard payload.count >= 4 else { return }
        if isXM6, payload[1] == 0x0C {
            state.speakToChatEnabled = payload[2] == 0x00
            return
        }
        guard payload[1] == Opcode.smartTalkingMode else { return }
        state.speakToChatEnabled = payload[3] != 0
    }
}
