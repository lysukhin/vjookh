/// Cheap structural heuristics: does a token *look like* a word in a given
/// script? Used as a medium-confidence signal when a token is in neither
/// dictionary (e.g. an inflected word the stems-only lexicon misses), so the
/// detector can still catch wrong-layout typing without a positive dict hit.
///
/// Conservative by design: a token is implausible only if it has **no vowel**
/// in the given script. This is the one reliably-separable signal —
/// Russian typed in the EN layout maps to a Latin string with essentially no
/// `aeiouy` (e.g. `приветом` → `ghbdtnjv`). The reverse direction (English in
/// the RU layout) is NOT reliably vowel-poor, so detecting it stays
/// dictionary-only; do not add a structural check there.
public enum Plausibility {
    private static let latinVowels = Set("aeiouy")
    private static let cyrillicVowels = Set("аеёиоуыэюя")

    private static func hasVowel(_ token: String, from vowels: Set<Character>) -> Bool {
        token.lowercased().contains(where: vowels.contains)
    }

    public static func looksLikeLatin(_ token: String) -> Bool {
        hasVowel(token, from: latinVowels)
    }

    public static func looksLikeCyrillic(_ token: String) -> Bool {
        hasVowel(token, from: cyrillicVowels)
    }
}
