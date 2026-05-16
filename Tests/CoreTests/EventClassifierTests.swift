import XCTest
@testable import Core

final class EventClassifierTests: XCTestCase {
    // macOS virtual key codes
    private let kTab = 48, kReturn = 36, kKeypadEnter = 76, kLeftArrow = 123, kA = 0

    func test_letterIsCharacter() {
        XCTAssertEqual(EventClassifier.classify(typed: "g", isDelete: false, keyCode: kA), .character("g"))
        XCTAssertEqual(EventClassifier.classify(typed: "Я", isDelete: false, keyCode: kA), .character("Я"))
    }

    func test_deleteIsBackspace() {
        XCTAssertEqual(EventClassifier.classify(typed: "", isDelete: true, keyCode: 51), .backspace)
    }

    func test_spacePunctuationAndNewlineAreBoundaries() {
        XCTAssertEqual(EventClassifier.classify(typed: " ", isDelete: false, keyCode: 49), .boundary)
        XCTAssertEqual(EventClassifier.classify(typed: ".", isDelete: false, keyCode: 47), .boundary)
        XCTAssertEqual(EventClassifier.classify(typed: "\n", isDelete: false, keyCode: kReturn), .boundary)
    }

    func test_digitIsBoundary() {
        XCTAssertEqual(EventClassifier.classify(typed: "7", isDelete: false, keyCode: 26), .boundary)
    }

    // Tab / Return / keypad-Enter must trigger a word boundary even when the
    // event delivers no Unicode string (a common case for these keys).
    func test_tabAndReturnAreBoundariesEvenWithEmptyTyped() {
        XCTAssertEqual(EventClassifier.classify(typed: "", isDelete: false, keyCode: kTab), .boundary)
        XCTAssertEqual(EventClassifier.classify(typed: "", isDelete: false, keyCode: kReturn), .boundary)
        XCTAssertEqual(EventClassifier.classify(typed: "", isDelete: false, keyCode: kKeypadEnter), .boundary)
    }

    // Genuine non-printing keys (arrows, modifiers, F-keys) still abandon the word.
    func test_nonPrintingKeyIsReset() {
        XCTAssertEqual(EventClassifier.classify(typed: "", isDelete: false, keyCode: kLeftArrow), .reset)
    }
}
