import Foundation

// Decides when the SPP/RFCOMM channel should be open vs. closed,
// trading a small reconnect latency for headphones battery life.
//
// Connect triggers:   audio playing on the headphones' audio device,
//                     OR user opened the menu / hit Reconnect.
// Disconnect trigger: 5 minutes of no audio AND no user activity.
//
// Drives the lifecycle via two callbacks; the owner wires them to
// BluetoothClient.connect() / .disconnect().
final class ConnectionPolicy {
    static let idleThreshold: TimeInterval = 5 * 60
    static let pollInterval: TimeInterval = 30

    var onShouldConnect: (() -> Void)?
    var onShouldDisconnect: (() -> Void)?

    private let audio: AudioActivityMonitor
    private var timer: Timer?
    private var lastActiveDate = Date()
    private var currentlyConnected = false

    init(audio: AudioActivityMonitor) {
        self.audio = audio
    }

    func start() {
        guard timer == nil else { return }
        lastActiveDate = Date()
        let t = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
        FileLogger.shared.log("policy", "started; idle threshold=\(Int(Self.idleThreshold))s")
        // Initial check ASAP — if audio is already playing on launch, connect now.
        DispatchQueue.main.async { [weak self] in self?.tick() }
    }

    func setCurrentlyConnected(_ connected: Bool) {
        currentlyConnected = connected
        if connected {
            lastActiveDate = Date()
        }
    }

    // Called when the user opens the menu or clicks Reconnect. Counts
    // as fresh activity (keeps the link alive) and triggers a connect
    // if currently idle-disconnected.
    func userActivity() {
        lastActiveDate = Date()
        if !currentlyConnected {
            FileLogger.shared.log("policy", "user activity → request connect")
            onShouldConnect?()
        }
    }

    private func tick() {
        if audio.isActive() {
            lastActiveDate = Date()
            if !currentlyConnected {
                FileLogger.shared.log("policy", "audio active → request connect")
                onShouldConnect?()
            }
        } else if currentlyConnected {
            let idle = Date().timeIntervalSince(lastActiveDate)
            if idle >= Self.idleThreshold {
                FileLogger.shared.log("policy", "idle \(Int(idle))s → request disconnect")
                onShouldDisconnect?()
            }
        }
    }
}
