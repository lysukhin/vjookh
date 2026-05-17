import XCTest
@testable import Core

final class EditPlannerTests: XCTestCase {
    // After "ghbdtn " committed, the field holds the word + the separator.
    // The correction must delete both and retype corrected word + same separator.
    func test_correctionDeletesWordPlusSeparatorAndRetypesBoth() {
        let edit = EditPlanner.correction(word: "ghbdtn", separator: " ", corrected: "привет")
        XCTAssertEqual(edit.deleteCount, 7)        // 6 letters + 1 separator
        XCTAssertEqual(edit.insert, "привет ")
    }

    func test_correctionPreservesNonSpaceSeparator() {
        let edit = EditPlanner.correction(word: "ghbdtn", separator: ".", corrected: "привет")
        XCTAssertEqual(edit.deleteCount, 7)
        XCTAssertEqual(edit.insert, "привет.")
    }

    func test_correctionWithMultiCharSeparatorCountsScalars() {
        // e.g. a newline-typed boundary captured as a single scalar
        let edit = EditPlanner.correction(word: "ab", separator: "\n", corrected: "фи")
        XCTAssertEqual(edit.deleteCount, 3)
        XCTAssertEqual(edit.insert, "фи\n")
    }

    // Undo must exactly reverse a just-applied correction: delete what we
    // inserted, retype what was originally there.
    func test_undoReversesACorrectionExactly() {
        let edit = EditPlanner.correction(word: "ghbdtn", separator: " ", corrected: "привет")
        let undo = EditPlanner.undo(of: edit, originalWord: "ghbdtn", separator: " ")
        XCTAssertEqual(undo.deleteCount, edit.insert.count)  // delete "привет "
        XCTAssertEqual(undo.insert, "ghbdtn ")
    }

    // #6: the synthesizer types one event per Character and the field deletes
    // one grapheme per backspace, so the planned text must be in a single
    // canonical form (NFC). A decomposed `corrected` (ё = е + U+0308) must be
    // normalized so what we plan == what the field ends up holding.
    func test_correctionNormalizesCorrectedToNFC() {
        let decomposed = "приве\u{0308}т"           // "привёт", ё decomposed
        XCTAssertEqual(decomposed.unicodeScalars.count, 7)  // 6 graphemes, 7 scalars
        let edit = EditPlanner.correction(
            word: "ghbdtn", separator: " ", corrected: decomposed
        )
        XCTAssertEqual(edit.insert, "привёт ")      // precomposed ё (U+0451)
        XCTAssertEqual(edit.insert.unicodeScalars.count, 7)  // ё now 1 scalar + space
        XCTAssertEqual(edit.deleteCount, 7)         // 6-letter wrong word + space
    }

    func test_undoOfNormalizedCorrectionRoundTrips() {
        let edit = EditPlanner.correction(
            word: "ghbdtn", separator: " ", corrected: "приве\u{0308}т"
        )
        // deleteCount is in grapheme units (synth types 1 event per Character,
        // field deletes 1 grapheme per backspace): "привёт " == 7 graphemes.
        let undo = EditPlanner.undo(of: edit, originalWord: "ghbdtn", separator: " ")
        XCTAssertEqual(undo.deleteCount, 7)            // delete normalized "привёт "
        XCTAssertEqual(undo.deleteCount, edit.insert.count)
        XCTAssertEqual(undo.insert, "ghbdtn ")
    }
}
