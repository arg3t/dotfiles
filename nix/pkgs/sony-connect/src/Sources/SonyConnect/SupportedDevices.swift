import Foundation

// Bluetooth / audio device-name substrings the app matches against.
// Used by BluetoothClient to pick the paired RFCOMM device and by
// AudioActivityMonitor to find the CoreAudio output device.
enum SupportedDevices {
    static let nameHints = ["WH-1000XM3", "WH-1000XM4", "WH-1000XM5", "WH-1000XM6"]
}
