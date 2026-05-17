import CoreGraphics
import Foundation

/// Thin CGEventTap shim. NOT unit-tested (drives real macOS input) — verified
/// via the manual integration checklist. All extractable logic lives in the
/// pure, TDD'd `EventClassifier`.
///
/// Hard requirements designed in:
///  • re-entrancy: every event we synthesize is tagged with `Self.magic` in the
///    `.eventSourceUserData` field; the callback passes those straight through
///    so our own backspaces/retypes never re-enter the pipeline (no infinite loop).
///  • tap auto-disable: macOS disables a tap whose callback is slow or when the
///    user toggles the permission — we re-enable on `.tapDisabledBy*`.
///  • the callback runs on a dedicated thread/runloop so a busy main thread can
///    never cause a tap timeout.
public final class EventTapController {
    /// Marker written into `.eventSourceUserData` on every synthetic event.
    public static let magic: Int64 = 0x766A_6B31  // "vjk1"

    public struct Keystroke {
        public let typed: String
        public let isDelete: Bool
        public let keyCode: Int64
    }

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?   // the tap thread's run loop
    private var thread: Thread?
    private let onKeystroke: (Keystroke) -> Void
    private let onShift: (Bool) -> Void   // true = Shift went down, false = up
    private var shiftDown = false

    public init(
        onKeystroke: @escaping (Keystroke) -> Void,
        onShift: @escaping (Bool) -> Void = { _ in }
    ) {
        self.onKeystroke = onKeystroke
        self.onShift = onShift
    }

    public func start() {
        let thread = Thread { [weak self] in
            guard let self else { return }
            let mask =
                (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
            guard let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mask),
                callback: { _, type, event, refcon in
                    EventTapController.handle(type: type, event: event, refcon: refcon)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) else {
                NSLog("[vjookh] event tap creation failed — Accessibility permission missing?")
                return
            }
            self.tap = tap
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            self.runLoopSource = source
            self.runLoop = CFRunLoopGetCurrent()
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "io.github.vjookh.eventtap"
        thread.start()
        self.thread = thread
    }

    /// Tear down the tap on the *tap thread's* run loop (the source was added
    /// there, not on the caller's run loop) and stop that run loop so the
    /// thread exits instead of leaking.
    public func stop() {
        guard let runLoop else { return }   // not started / already stopped
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        let source = runLoopSource
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) {
            if let source {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }
            CFRunLoopStop(runLoop)
        }
        CFRunLoopWakeUp(runLoop)
        self.tap = nil
        self.runLoopSource = nil
        self.runLoop = nil
        self.thread = nil
    }

    private static func handle(
        type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)

        // OS disabled the tap (slow callback or permission toggled) → re-enable.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let refcon {
                let me = Unmanaged<EventTapController>.fromOpaque(refcon).takeUnretainedValue()
                if let tap = me.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            }
            return pass
        }

        // Ignore our own synthetic events — prevents re-entrancy loops.
        if event.getIntegerValueField(.eventSourceUserData) == EventTapController.magic {
            return pass
        }
        guard let refcon else { return pass }
        let me = Unmanaged<EventTapController>.fromOpaque(refcon).takeUnretainedValue()

        // Track Shift transitions for the double-tap gesture.
        if type == .flagsChanged {
            let down = event.flags.contains(.maskShift)
            if down != me.shiftDown {
                me.shiftDown = down
                me.onShift(down)
            }
            return pass
        }

        guard type == .keyDown else { return pass }

        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        let typed = String(utf16CodeUnits: chars, count: length)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isDelete = keyCode == 51  // kVK_Delete (Backspace)

        me.onKeystroke(Keystroke(typed: typed, isDelete: isDelete, keyCode: keyCode))

        // Observe only — never consume the user's keystroke. Corrections are
        // applied asynchronously by the synthesizer after the boundary commits.
        return pass
    }
}
