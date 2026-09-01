import CoreAudio
import Foundation

// Reads/writes the output volume of the headphones' CoreAudio device.
// For an A2DP Bluetooth sink, macOS forwards this scalar to the device
// as an AVRCP absolute-volume command, so it really moves the volume the
// user hears. Independent of the Sony SPP control channel.
final class VolumeController {
    let nameHints: [String]

    init(nameHints: [String]) {
        self.nameHints = nameHints
    }

    /// Current volume 0…1, or nil if the headphones output device isn't present.
    func currentVolume() -> Float? {
        guard let device = deviceID() else { return nil }
        return readVolume(device)
    }

    func setVolume(_ value: Float) {
        guard let device = deviceID() else { return }
        writeVolume(device, max(0, min(1, value)))
    }

    // MARK: - Device lookup

    private func deviceID() -> AudioDeviceID? {
        for id in allDeviceIDs() {
            guard let name = deviceName(id),
                  nameHints.contains(where: { name.localizedCaseInsensitiveContains($0) }),
                  hasOutputVolume(id) else { continue }
            return id
        }
        return nil
    }

    private func allDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size
        ) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids
        ) == noErr else { return [] }
        return ids
    }

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name) == noErr,
              let cf = name?.takeRetainedValue() else { return nil }
        return cf as String
    }

    private func hasOutputVolume(_ id: AudioDeviceID) -> Bool {
        for element in volumeElements {
            var address = volumeAddress(element)
            if AudioObjectHasProperty(id, &address) { return true }
        }
        return false
    }

    // MARK: - Volume get/set

    // Try the main element first, then per-channel (left/right).
    private let volumeElements: [AudioObjectPropertyElement] =
        [kAudioObjectPropertyElementMain, 1, 2]

    private func volumeAddress(_ element: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
    }

    private func readVolume(_ device: AudioDeviceID) -> Float? {
        var total: Float = 0
        var count = 0
        for element in volumeElements {
            var address = volumeAddress(element)
            guard AudioObjectHasProperty(device, &address) else { continue }
            var vol = Float32(0)
            var size = UInt32(MemoryLayout<Float32>.size)
            if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &vol) == noErr {
                // Main element alone is authoritative — return immediately.
                if element == kAudioObjectPropertyElementMain { return vol }
                total += vol
                count += 1
            }
        }
        return count > 0 ? total / Float(count) : nil
    }

    private func writeVolume(_ device: AudioDeviceID, _ value: Float) {
        var v = Float32(value)
        let size = UInt32(MemoryLayout<Float32>.size)
        // Prefer the main element if it's settable.
        var mainAddr = volumeAddress(kAudioObjectPropertyElementMain)
        if AudioObjectHasProperty(device, &mainAddr), isSettable(device, &mainAddr) {
            AudioObjectSetPropertyData(device, &mainAddr, 0, nil, size, &v)
            return
        }
        for element in [AudioObjectPropertyElement(1), 2] {
            var address = volumeAddress(element)
            if AudioObjectHasProperty(device, &address), isSettable(device, &address) {
                AudioObjectSetPropertyData(device, &address, 0, nil, size, &v)
            }
        }
    }

    private func isSettable(_ device: AudioDeviceID, _ address: inout AudioObjectPropertyAddress) -> Bool {
        var settable: DarwinBoolean = false
        return AudioObjectIsPropertySettable(device, &address, &settable) == noErr && settable.boolValue
    }
}
