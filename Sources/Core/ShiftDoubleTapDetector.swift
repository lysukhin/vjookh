import Foundation

/// Recognizes a "double-tap Shift" gesture from a stream of modifier/other
/// events. Pure + time-injected so it is fully unit-tested; the event-tap
/// adapter just feeds it real events with timestamps.
///
/// A *tap* is Shift-down then Shift-up with no other key in between and a
/// press shorter than `maxTapDuration`. Two taps whose ends are within
/// `window` of each other are a double-tap.
public struct ShiftDoubleTapDetector {
    public enum Event { case modifierDown, modifierUp, otherKey }

    private let window: TimeInterval
    private let maxTapDuration: TimeInterval

    private var downAt: TimeInterval?     // start of a candidate tap
    private var tainted = false           // another key pressed during the press
    private var lastTapEnd: TimeInterval? // end time of the previous clean tap

    public init(window: TimeInterval = 0.30, maxTapDuration: TimeInterval = 0.30) {
        self.window = window
        self.maxTapDuration = maxTapDuration
    }

    /// Returns `true` exactly when a double-tap completes.
    public mutating func feed(_ event: Event, at t: TimeInterval) -> Bool {
        switch event {
        case .otherKey:
            // Any real key cancels the gesture entirely.
            downAt = nil
            tainted = false
            lastTapEnd = nil
            return false

        case .modifierDown:
            downAt = t
            tainted = false
            return false

        case .modifierUp:
            defer { downAt = nil; tainted = false }
            guard let start = downAt, !tainted, t - start <= maxTapDuration else {
                lastTapEnd = nil          // not a clean tap → break any pending pair
                return false
            }
            if let prev = lastTapEnd, t - prev <= window {
                lastTapEnd = nil
                return true               // second clean tap in time → double-tap
            }
            lastTapEnd = t
            return false
        }
    }
}
