import Core
import CoreGraphics
import Foundation

/// Applies a correction by synthesizing keystrokes: delete the wrongly-typed
/// run, then type the corrected text. Universal across native/Electron/
/// terminal/web (the only mechanism that works everywhere).
///
/// Every synthesized event is tagged with `EventTapController.magic` in
/// `.eventSourceUserData` so our own tap ignores it (no re-entrancy loop).
/// Posting happens off the tap thread.
public final class InputSynthesizer {
    private let source = CGEventSource(stateID: .combinedSessionState)
    private let queue = DispatchQueue(label: "io.github.vjookh.synth")
    private let backspaceKey: CGKeyCode = 51  // kVK_Delete

    public init() {}

    /// Execute a planned edit (delete N, then type the replacement).
    public func apply(_ edit: EditPlanner.Edit) {
        replace(deleteCount: edit.deleteCount, with: edit.insert)
    }

    /// Delete `deleteCount` characters, then type `replacement`.
    /// Both halves are tagged; a tiny inter-event delay lets the target app
    /// keep up (fast apps drop coalesced synthetic events otherwise).
    public func replace(deleteCount: Int, with replacement: String) {
        queue.async { [self] in
            for _ in 0..<deleteCount {
                postKey(backspaceKey, down: true)
                postKey(backspaceKey, down: false)
                usleep(1_500)
            }
            for scalar in replacement.unicodeScalars {
                postUnicode(scalar)
                usleep(1_500)
            }
        }
    }

    private func tag(_ event: CGEvent?) {
        event?.setIntegerValueField(.eventSourceUserData, value: EventTapController.magic)
    }

    private func postKey(_ key: CGKeyCode, down: Bool) {
        let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
        tag(event)
        event?.post(tap: .cgSessionEventTap)
    }

    private func postUnicode(_ scalar: Unicode.Scalar) {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return }
        var utf16 = Array(String(scalar).utf16)
        down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        tag(down); tag(up)
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }
}
