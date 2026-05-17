import Foundation

/// Computes the exact delete/retype operations for a correction and its undo.
///
/// Pure: this is the bug-prone arithmetic (off-by-one on the separator, undo
/// symmetry) isolated for testing. The synthesizer just executes an `Edit`.
///
/// All planned text is normalized to a single canonical form (NFC). The
/// synthesizer types one event per `Character` and the field deletes one
/// grapheme per backspace, so `deleteCount` is a grapheme count and `insert`
/// is NFC — what we plan then equals what the field ends up holding even when
/// the upstream string arrived decomposed.
public enum EditPlanner {
    public struct Edit: Equatable {
        public let deleteCount: Int
        public let insert: String
    }

    private static func nfc(_ s: String) -> String {
        s.precomposedStringWithCanonicalMapping
    }

    /// The wrong-layout `word` plus the `separator` that committed it have
    /// already landed in the field; replace both with the corrected text.
    public static func correction(
        word: String, separator: String, corrected: String
    ) -> Edit {
        let w = nfc(word), sep = nfc(separator)
        return Edit(deleteCount: w.count + sep.count, insert: nfc(corrected) + sep)
    }

    /// Exact inverse of a previously-applied `correction` edit.
    public static func undo(
        of edit: Edit, originalWord: String, separator: String
    ) -> Edit {
        Edit(deleteCount: edit.insert.count, insert: nfc(originalWord) + nfc(separator))
    }
}
