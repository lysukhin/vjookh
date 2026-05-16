import XCTest
@testable import Core

final class KeystrokeBufferTests: XCTestCase {
    func test_charactersAccumulateIntoCurrentWord() {
        var buf = KeystrokeBuffer()
        buf.handle(.character("h"))
        buf.handle(.character("i"))
        XCTAssertEqual(buf.currentWord, "hi")
    }

    func test_boundaryReturnsCompletedWordAndResets() {
        var buf = KeystrokeBuffer()
        for c in "ghbdtn" { buf.handle(.character(c)) }
        let completed = buf.handle(.boundary)
        XCTAssertEqual(completed, "ghbdtn")
        XCTAssertEqual(buf.currentWord, "")
    }

    func test_boundaryWithNoWordReturnsNil() {
        var buf = KeystrokeBuffer()
        XCTAssertNil(buf.handle(.boundary))
    }

    func test_backspaceRemovesLastCharacter() {
        var buf = KeystrokeBuffer()
        for c in "hel" { buf.handle(.character(c)) }
        buf.handle(.backspace)
        XCTAssertEqual(buf.currentWord, "he")
    }

    func test_backspaceOnEmptyWordIsNoOp() {
        var buf = KeystrokeBuffer()
        buf.handle(.backspace)
        XCTAssertEqual(buf.currentWord, "")
    }

    // Focus change / caret move invalidates the in-progress word: we can no
    // longer trust that backspaces would land on the same text.
    func test_resetClearsCurrentWord() {
        var buf = KeystrokeBuffer()
        for c in "abc" { buf.handle(.character(c)) }
        buf.handle(.reset)
        XCTAssertEqual(buf.currentWord, "")
    }
}
