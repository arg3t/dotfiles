import AppKit

// NSSlider ignores the scroll wheel by default, which makes fine-grained
// values annoying to hit by dragging a tiny knob. This nudges the value one
// step per wheel tick.
//
// Continuous sliders fire their action per tick, matching what dragging
// does. Non-continuous ones (the EQ bands and the ambient level are
// deliberately commit-on-mouse-up so a drag doesn't spray the RFCOMM
// channel) coalesce instead: the knob moves immediately for feedback, and
// the action fires once — on the gesture's end phase when the trackpad
// reports one, or after a short quiet period for mice with discrete wheels.
final class ScrollableSlider: NSSlider {
    private static let commitDelay: TimeInterval = 0.25
    private var commitTimer: Timer?
    private var pendingCommit = false

    override func scrollWheel(with event: NSEvent) {
        guard isEnabled else {
            super.scrollWheel(with: event)
            return
        }

        if event.deltaY != 0 {
            let step: Double = event.deltaY > 0 ? 1 : -1
            let newValue = min(maxValue, max(minValue, doubleValue + step))
            if newValue != doubleValue {
                doubleValue = newValue
                if isContinuous {
                    sendAction(action, to: target)
                } else {
                    pendingCommit = true
                    scheduleCommit()
                }
            }
        }

        // A trackpad ends the gesture with a zero-delta event carrying the
        // .ended phase — commit right away instead of waiting out the timer.
        if pendingCommit,
           event.phase == .ended || event.momentumPhase == .ended {
            commitNow()
        }
    }

    private func scheduleCommit() {
        commitTimer?.invalidate()
        let t = Timer(timeInterval: Self.commitDelay, repeats: false) { [weak self] _ in
            self?.commitNow()
        }
        commitTimer = t
        // .common, not .default: these sliders live inside an open NSMenu,
        // whose event-tracking run loop mode never fires .default timers.
        RunLoop.main.add(t, forMode: .common)
    }

    private func commitNow() {
        commitTimer?.invalidate()
        commitTimer = nil
        guard pendingCommit else { return }
        pendingCommit = false
        sendAction(action, to: target)
    }
}
