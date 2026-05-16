/// Maps a raw keystroke (the Unicode string it produced + whether it was the
/// delete key) into a `KeystrokeBuffer.Event`.
///
/// Pure: the only testable logic extracted from the CGEventTap adapter, so the
/// adapter itself stays a thin, manually-verified shim.
public enum EventClassifier {
    /// Virtual key codes that always denote a word boundary regardless of the
    /// Unicode string the event carries (these keys often deliver none).
    private static let boundaryKeyCodes: Set<Int> = [
        48,  // kVK_Tab
        36,  // kVK_Return
        76,  // kVK_ANSI_KeypadEnter
    ]

    public static func classify(
        typed: String, isDelete: Bool, keyCode: Int
    ) -> KeystrokeBuffer.Event {
        if isDelete { return .backspace }
        if boundaryKeyCodes.contains(keyCode) { return .boundary }
        if typed.isEmpty { return .reset }  // arrows / modifiers / F-keys
        if let c = typed.first, typed.count == 1, c.isLetter {
            return .character(c)
        }
        // whitespace, punctuation, digits, multi-char → word boundary
        return .boundary
    }
}
