import Foundation

/// A word-membership set for one language.
///
/// Case-insensitive O(1) lookup. Pure: no system APIs. (Conceptually the
/// plan's "Dictionary"; renamed to avoid shadowing Swift's `Dictionary`.)
public struct Lexicon {
    private let words: Set<String>

    public init(words: [String]) {
        self.words = Set(words.map { $0.lowercased() })
    }

    /// Accepts plain newline-separated wordlists and hunspell `.dic` files
    /// (`stem/AFFIXFLAGS`, optional morphology fields, leading count line).
    public init(text: String) {
        let parsed = text
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> String? in
                // Take the stem only: stop at affix-flag '/' or any whitespace.
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let word = String(trimmed.prefix { $0 != "/" && !$0.isWhitespace })
                if word.isEmpty { return nil }
                if word.allSatisfy(\.isNumber) { return nil }  // .dic count line
                return word
            }
        self.init(words: parsed)
    }

    public func contains(_ word: String) -> Bool {
        !word.isEmpty && words.contains(word.lowercased())
    }

    public var count: Int { words.count }

    public enum LoadError: Error { case resourceNotFound }

    /// Load a bundled wordlist, e.g. `"ru"` → `Resources/Dictionaries/ru.txt`.
    public static func load(name: String) throws -> Lexicon {
        guard let url = ResourceBundle.url(
            forResource: name, withExtension: "txt", subdirectory: "Resources/Dictionaries"
        ) else { throw LoadError.resourceNotFound }
        return Lexicon(text: try String(contentsOf: url, encoding: .utf8))
    }
}
