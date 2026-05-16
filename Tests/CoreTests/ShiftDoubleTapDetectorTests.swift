import XCTest
@testable import Core

final class ShiftDoubleTapDetectorTests: XCTestCase {
    // A "tap" = Shift down then up with no other key, quickly. Two taps within
    // the window → recognized.
    func test_twoQuickTapsTrigger() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        XCTAssertFalse(d.feed(.modifierDown, at: 0.00))
        XCTAssertFalse(d.feed(.modifierUp, at: 0.05))   // first tap complete
        XCTAssertFalse(d.feed(.modifierDown, at: 0.10))
        XCTAssertTrue(d.feed(.modifierUp, at: 0.15))     // second tap → trigger
    }

    func test_secondTapTooLateDoesNotTrigger() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        _ = d.feed(.modifierDown, at: 0.00)
        _ = d.feed(.modifierUp, at: 0.05)
        _ = d.feed(.modifierDown, at: 0.50)
        XCTAssertFalse(d.feed(.modifierUp, at: 0.55))    // gap 0.45 > window
    }

    func test_otherKeyBetweenTapsResets() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        _ = d.feed(.modifierDown, at: 0.00)
        _ = d.feed(.modifierUp, at: 0.05)
        _ = d.feed(.otherKey, at: 0.08)                  // interrupts the sequence
        _ = d.feed(.modifierDown, at: 0.10)
        XCTAssertFalse(d.feed(.modifierUp, at: 0.15))
    }

    // Shift held as a modifier (Shift+letter for a capital) is not a tap.
    func test_shiftHeldWithOtherKeyIsNotATap() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        _ = d.feed(.modifierDown, at: 0.00)
        _ = d.feed(.otherKey, at: 0.02)                  // capital letter
        _ = d.feed(.modifierUp, at: 0.04)                // not a clean tap
        _ = d.feed(.modifierDown, at: 0.06)
        XCTAssertFalse(d.feed(.modifierUp, at: 0.09))
    }

    func test_singleTapDoesNotTrigger() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        _ = d.feed(.modifierDown, at: 0.00)
        XCTAssertFalse(d.feed(.modifierUp, at: 0.05))
    }

    // A held-too-long Shift is not a tap (down → up exceeding maxTapDuration).
    func test_slowSinglePressIsNotATap() {
        var d = ShiftDoubleTapDetector(window: 0.30, maxTapDuration: 0.30)
        _ = d.feed(.modifierDown, at: 0.00)
        _ = d.feed(.modifierUp, at: 0.50)                // 0.5s press, not a tap
        _ = d.feed(.modifierDown, at: 0.55)
        XCTAssertFalse(d.feed(.modifierUp, at: 0.58))
    }
}
