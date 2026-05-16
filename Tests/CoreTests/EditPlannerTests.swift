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
}
