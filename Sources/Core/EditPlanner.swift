/// Computes the exact delete/retype operations for a correction and its undo.
///
/// Pure: this is the bug-prone arithmetic (off-by-one on the separator, undo
/// symmetry) isolated for testing. The synthesizer just executes an `Edit`.
public enum EditPlanner {
    public struct Edit: Equatable {
        public let deleteCount: Int
        public let insert: String
    }

    /// The wrong-layout `word` plus the `separator` that committed it have
    /// already landed in the field; replace both with the corrected text.
    public static func correction(
        word: String, separator: String, corrected: String
    ) -> Edit {
        Edit(deleteCount: word.count + separator.count, insert: corrected + separator)
    }

    /// Exact inverse of a previously-applied `correction` edit.
    public static func undo(
        of edit: Edit, originalWord: String, separator: String
    ) -> Edit {
        Edit(deleteCount: edit.insert.count, insert: originalWord + separator)
    }
}
