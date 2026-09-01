import Foundation
import IOBluetooth
import OSLog

// Sony's proprietary RFCOMM service UUIDs for MDR-v2 and MDR-v1 headphones.
private let sonyServiceUUIDs: [[UInt8]] = [
    [0x95, 0x6C, 0x7B, 0x26, 0xD4, 0x9A, 0x4B, 0xA8,
     0xB0, 0x3F, 0xB1, 0x7D, 0x39, 0x3C, 0xB6, 0xE2],
    [0x96, 0xCC, 0x20, 0x3E, 0x50, 0x68, 0x46, 0xAD,
     0xB3, 0x2D, 0xE3, 0x16, 0xF5, 0xE0, 0x69, 0xBA],
]

private let log = Logger(subsystem: "com.tanat.sonyconnect", category: "bluetooth")

final class BluetoothClient: NSObject {
    enum Status {
        case disconnected
        case searching
        case connecting(deviceName: String)
        case connected(deviceName: String)
        case failed(reason: String)
    }

    var onStatus: ((Status) -> Void)?
    var onData: ((Data) -> Void)?
    // Fires when the headphones' baseband (ACL) link to the Mac comes or
    // goes — independent of whether our SPP control channel is open.
    // Passes (reachable, deviceName?).
    var onReachabilityChange: ((Bool, String?) -> Void)?

    private var channel: IOBluetoothRFCOMMChannel?
    private var device: IOBluetoothDevice?
    private var reconnectTimer: Timer?
    private var suppressAutoReconnect = false
    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotification: IOBluetoothUserNotification?
    private static let reconnectInterval: TimeInterval = 5
    private(set) var status: Status = .disconnected {
        didSet {
            FileLogger.shared.log("bt", "status -> \(status)")
            onStatus?(status)
            switch status {
            case .connected:
                cancelReconnect()
            case .failed:
                scheduleReconnect()
            case .disconnected:
                if !suppressAutoReconnect {
                    scheduleReconnect()
                }
            case .searching, .connecting:
                break
            }
        }
    }

    // Begin watching the paired headphones' baseband connection so the UI
    // can reflect "device present" vs. "device off/out of range" even while
    // our SPP channel is intentionally closed for battery saving.
    func startReachabilityMonitoring() {
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(aclDeviceConnected(_:device:))
        )
        if let target = targetPairedDevice(), target.isConnected() {
            registerDisconnect(for: target)
            onReachabilityChange?(true, target.name)
        } else {
            onReachabilityChange?(false, nil)
        }
    }

    func isTargetDeviceConnected() -> Bool {
        targetPairedDevice()?.isConnected() ?? false
    }

    private func targetPairedDevice() -> IOBluetoothDevice? {
        guard let raw = IOBluetoothDevice.pairedDevices() else { return nil }
        let devices = raw.compactMap { $0 as? IOBluetoothDevice }
        return devices.first { isTargetDevice($0) && $0.isConnected() } ?? devices.first { isTargetDevice($0) }
    }

    private func isTargetDevice(_ device: IOBluetoothDevice) -> Bool {
        let name = device.name ?? ""
        return SupportedDevices.nameHints.contains { name.contains($0) }
    }

    private func registerDisconnect(for device: IOBluetoothDevice) {
        disconnectNotification?.unregister()
        disconnectNotification = device.register(
            forDisconnectNotification: self,
            selector: #selector(aclDeviceDisconnected(_:device:))
        )
    }

    @objc private func aclDeviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard isTargetDevice(device) else { return }
        FileLogger.shared.log("bt", "ACL connected: \(device.name ?? "?")")
        registerDisconnect(for: device)
        onReachabilityChange?(true, device.name)
        // Replace a pending connection to an offline paired headset with the
        // headset that has just connected.
        if self.device?.isConnected() == false {
            connect()
        }
    }

    @objc private func aclDeviceDisconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard isTargetDevice(device) else { return }
        FileLogger.shared.log("bt", "ACL disconnected: \(device.name ?? "?")")
        onReachabilityChange?(false, device.name)
    }

    func connect() {
        suppressAutoReconnect = false
        cancelReconnect()
        if case .connected = status { return }

        guard let target = targetPairedDevice() else {
            status = .failed(reason: "Sony headphones not paired")
            return
        }
        if device?.addressString == target.addressString {
            switch status {
            case .connecting, .searching:
                return
            case .disconnected, .failed, .connected:
                break
            }
        }

        let previousChannel = channel
        channel = nil
        device = target
        previousChannel?.close()
        status = .searching

        let name = target.name ?? target.addressString ?? "Sony headphones"
        status = .connecting(deviceName: name)

        if findServiceAndOpen(device: target) { return }

        log.info("Service record not cached; performing SDP query")
        if target.performSDPQuery(self) != kIOReturnSuccess {
            status = .failed(reason: "SDP query failed to start")
        }
    }

    func disconnect() {
        suppressAutoReconnect = true
        cancelReconnect()
        channel?.close()
        channel = nil
        device = nil
        status = .disconnected
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        let t = Timer(timeInterval: Self.reconnectInterval, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.attemptReconnect()
        }
        reconnectTimer = t
        RunLoop.main.add(t, forMode: .common)
        FileLogger.shared.log("bt", "reconnect scheduled in \(Int(Self.reconnectInterval))s")
    }

    private func cancelReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func attemptReconnect() {
        switch status {
        case .connected, .connecting, .searching:
            return
        case .disconnected, .failed:
            FileLogger.shared.log("bt", "reconnect attempt")
            connect()
        }
    }

    func send(_ data: Data) {
        guard let channel = channel else {
            FileLogger.shared.log("bt", "send: NO CHANNEL")
            return
        }
        FileLogger.shared.hex("tx", data)
        var bytes = [UInt8](data)
        let result = bytes.withUnsafeMutableBufferPointer { buffer -> IOReturn in
            guard let base = buffer.baseAddress else { return kIOReturnNoMemory }
            return channel.writeSync(base, length: UInt16(buffer.count))
        }
        if result != kIOReturnSuccess {
            FileLogger.shared.log("bt", "writeSync failed: \(result)")
        }
    }

    @discardableResult
    private func findServiceAndOpen(device: IOBluetoothDevice) -> Bool {
        for bytes in sonyServiceUUIDs {
            let uuid = IOBluetoothSDPUUID(bytes: bytes, length: bytes.count)
            guard let record = device.getServiceRecord(for: uuid) else { continue }
            FileLogger.shared.log("bt", "Sony service found: \(record.getServiceName() ?? "?")")

            var channelID: BluetoothRFCOMMChannelID = 0
            guard record.getRFCOMMChannelID(&channelID) == kIOReturnSuccess else {
                status = .failed(reason: "Service record has no RFCOMM channel")
                return false
            }
            FileLogger.shared.log("bt", "RFCOMM channel id = \(channelID)")

            var openedChannel: IOBluetoothRFCOMMChannel?
            guard device.openRFCOMMChannelSync(&openedChannel,
                                               withChannelID: channelID,
                                               delegate: self) == kIOReturnSuccess,
                  let openedChannel else {
                status = .failed(reason: "RFCOMM channel open failed")
                return false
            }
            channel = openedChannel
            status = .connected(deviceName: device.name ?? "Sony headphones")
            return true
        }
        FileLogger.shared.log("bt", "Sony service UUID not found in cached SDP records")
        return false
    }
}

extension BluetoothClient {
    @objc func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        guard status == kIOReturnSuccess, let device = device else {
            self.status = .failed(reason: "SDP query failed: \(status)")
            return
        }
        guard device.addressString == self.device?.addressString else {
            FileLogger.shared.log("bt", "ignoring stale SDP result: \(device.name ?? "?")")
            return
        }
        if !findServiceAndOpen(device: device) {
            self.status = .failed(reason: "Sony service UUID not advertised by device")
        }
    }
}

extension BluetoothClient: IOBluetoothRFCOMMChannelDelegate {
    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        guard let channel, rfcommChannel === channel else {
            FileLogger.shared.log("bt", "ignoring stale RFCOMM open")
            return
        }
        if error != kIOReturnSuccess {
            status = .failed(reason: "RFCOMM open failed: \(error)")
            self.channel = nil
            return
        }
        let name = rfcommChannel.getDevice()?.name ?? "Sony headphones"
        status = .connected(deviceName: name)
    }

    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!,
                           data dataPointer: UnsafeMutableRawPointer!,
                           length dataLength: Int) {
        guard rfcommChannel === channel else { return }
        let data = Data(bytes: dataPointer, count: dataLength)
        FileLogger.shared.hex("rx", data)
        onData?(data)
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        guard rfcommChannel === channel else { return }
        channel = nil
        status = .disconnected
    }
}
