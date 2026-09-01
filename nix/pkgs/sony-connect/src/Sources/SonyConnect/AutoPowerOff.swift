import CoreAudio
import Foundation

// Monitors macOS audio output for "headphones idle" and asks the
// controller to power off the device after a fixed idle threshold.
// Idle = the AudioDeviceID whose name matches the headphones is not
// in the "running somewhere" state (no process is feeding it audio).
// The idle timeouts Sony's own app offers. Raw values match the order the
// v2 protocol indexes them in, so they double as the wire code lookup.
enum AutoPowerOffOption: Int, CaseIterable {
    case off = 0
    case fiveMinutes = 1
    case thirtyMinutes = 2
    case oneHour = 3
    case threeHours = 4
    case whenTakenOff = 5

    var title: String {
        switch self {
        case .off: return "Off"
        case .fiveMinutes: return "After 5 min idle"
        case .thirtyMinutes: return "After 30 min idle"
        case .oneHour: return "After 1 hour idle"
        case .threeHours: return "After 3 hours idle"
        case .whenTakenOff: return "When taken off"
        }
    }

    // Idle threshold for the Mac-side timer. Nil means this option can't be
    // driven from a countdown here — "off" needs none, and "when taken off"
    // relies on the headphones' own wear detection.
    var idleSeconds: TimeInterval? {
        switch self {
        case .off, .whenTakenOff: return nil
        case .fiveMinutes: return 5 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .threeHours: return 3 * 60 * 60
        }
    }

    // Only the headphones can detect being taken off, and there is no
    // verified wear-detection command yet, so that entry stays unlisted.
    static var selectable: [AutoPowerOffOption] {
        allCases.filter { $0 != .whenTakenOff }
    }
}

final class AutoPowerOff {
    static let legacyDefaultsKey = "AutoOffEnabled"
    static let defaultsKey = "AutoOffOption"
    static let pollInterval: TimeInterval = 60

    var onShouldPowerOff: (() -> Void)?
    var onOptionChanged: ((AutoPowerOffOption) -> Void)?

    var option: AutoPowerOffOption {
        get {
            let defaults = UserDefaults.standard
            if let raw = defaults.object(forKey: Self.defaultsKey) as? Int,
               let stored = AutoPowerOffOption(rawValue: raw) {
                return stored
            }
            // Carry over the old on/off preference, which always meant 30 min.
            return defaults.bool(forKey: Self.legacyDefaultsKey) ? .thirtyMinutes : .off
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.defaultsKey)
            onOptionChanged?(newValue)
            if newValue.idleSeconds != nil, isArmed {
                start()
            } else {
                stop()
            }
        }
    }

    var isEnabled: Bool { option != .off }

    private var deviceNameMatch: String = ""
    private var isArmed: Bool = false  // headphones connected + ready
    private var timer: Timer?
    private var lastActiveDate = Date()

    func arm(deviceName: String) {
        deviceNameMatch = deviceName
        isArmed = true
        lastActiveDate = Date()
        if option.idleSeconds != nil {
            start()
        }
    }

    func disarm() {
        isArmed = false
        stop()
    }

    private func start() {
        stop()
        guard let threshold = option.idleSeconds else { return }
        lastActiveDate = Date()
        FileLogger.shared.log("autoOff", "armed; threshold=\(Int(threshold))s, poll=\(Int(Self.pollInterval))s")
        let t = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isArmed, let threshold = option.idleSeconds else { return }
        let running = isAudioActive()
        if running {
            lastActiveDate = Date()
        } else {
            let idle = Date().timeIntervalSince(lastActiveDate)
            if idle >= threshold {
                FileLogger.shared.log("autoOff", "idle \(Int(idle))s exceeds threshold, requesting power-off")
                lastActiveDate = Date()  // avoid retriggering before disconnect
                onShouldPowerOff?()
            }
        }
    }

    private func isAudioActive() -> Bool {
        guard !deviceNameMatch.isEmpty else { return false }
        for id in audioDeviceIDs() {
            guard let name = audioDeviceName(id),
                  name.localizedCaseInsensitiveContains(deviceNameMatch) else { continue }
            if audioDeviceRunning(id) {
                return true
            }
        }
        return false
    }

    private func audioDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size
        ) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &ids
        )
        guard status == noErr else { return [] }
        return ids
    }

    private func audioDeviceName(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name)
        guard status == noErr, let cf = name?.takeRetainedValue() else { return nil }
        return cf as String
    }

    private func audioDeviceRunning(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &running) == noErr else {
            return false
        }
        return running != 0
    }
}
