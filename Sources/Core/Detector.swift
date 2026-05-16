/// Decides whether a typed token was entered in the wrong keyboard layout.
///
/// Pure: no system APIs. The pipeline supplies the active layout (from the
/// system input source) and the token (from the keystroke buffer).
public struct Detector {
    public enum Layout { case latin, cyrillic }
    public enum Confidence { case none, medium, high }

    public struct Decision: Equatable {
        public let shouldConvert: Bool
        public let confidence: Confidence
        public let reason: String
    }

    /// Tokens at least this long are eligible for auto-conversion.
    private static let minLength = 2

    private let latin: Lexicon
    private let cyrillic: Lexicon
    private let map: LayoutMap

    public init(latin: Lexicon, cyrillic: Lexicon, map: LayoutMap) {
        self.latin = latin
        self.cyrillic = cyrillic
        self.map = map
    }

    public func evaluate(token: String, activeLayout: Layout) -> Decision {
        let core = token.lowercased()

        guard core.count >= Self.minLength,
              !core.contains(where: \.isNumber) else {
            return Decision(shouldConvert: false, confidence: .none, reason: "ineligible-token")
        }

        // Cross-check: not a word in the active layout's language, but its
        // transliteration IS a word in the other language → high confidence.
        switch activeLayout {
        case .latin:
            if latin.contains(core) { break }            // valid English → leave alone
            if cyrillic.contains(map.toCyrillic(core)) {
                return Decision(shouldConvert: true, confidence: .high, reason: "dictionary")
            }
            // Stems-only lexicons miss inflected forms. If the Latin token is
            // implausible English (no vowels — the reliable signal) but its
            // Cyrillic mapping is plausible Russian, convert at medium conf.
            if !Plausibility.looksLikeLatin(core),
               Plausibility.looksLikeCyrillic(map.toCyrillic(core)) {
                return Decision(shouldConvert: true, confidence: .medium, reason: "heuristic")
            }
        case .cyrillic:
            if cyrillic.contains(core) { break }
            if latin.contains(map.toLatin(core)) {
                return Decision(shouldConvert: true, confidence: .high, reason: "dictionary")
            }
            // Reverse direction has no reliable structural signal (see
            // Plausibility doc) — stays dictionary-only by design.
        }

        return Decision(shouldConvert: false, confidence: .none, reason: "no-signal")
    }
}
