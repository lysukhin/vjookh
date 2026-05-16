/// Accumulates the in-progress word from a keystroke stream.
///
/// In-memory only — never persisted (privacy invariant). Pure: no system
/// APIs. The system adapter translates raw events into `Event` values.
public struct KeystrokeBuffer {
    public enum Event: Equatable {
        case character(Character)
        case boundary    // space / punctuation / return — completes the word
        case backspace
        case reset       // focus change / caret move — abandon the word
    }

    public private(set) var currentWord: String = ""

    public init() {}

    /// Feed one event. Returns the completed word when `boundary` finalizes a
    /// non-empty word, otherwise `nil`.
    @discardableResult
    public mutating func handle(_ event: Event) -> String? {
        switch event {
        case .character(let c):
            currentWord.append(c)
            return nil
        case .boundary:
            defer { currentWord = "" }
            return currentWord.isEmpty ? nil : currentWord
        case .backspace:
            if !currentWord.isEmpty { currentWord.removeLast() }
            return nil
        case .reset:
            currentWord = ""
            return nil
        }
    }
}
