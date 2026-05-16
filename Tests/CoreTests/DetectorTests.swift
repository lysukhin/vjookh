import XCTest
@testable import Core

final class DetectorTests: XCTestCase {
    private func makeDetector() throws -> Detector {
        let map = try LayoutMap.load(pair: "en-ru")
        let en = Lexicon(words: ["hello", "world", "the", "fox", "test"])
        let ru = Lexicon(words: ["привет", "мир", "слово", "тест"])
        return Detector(latin: en, cyrillic: ru, map: map)
    }

    // High-confidence: gibberish in active layout that becomes a real word
    // in the other layout MUST be flagged for conversion.
    func test_latinGibberish_thatIsRealRussian_isHighConfidenceConvert() throws {
        let d = try makeDetector()
        let decision = d.evaluate(token: "ghbdtn", activeLayout: .latin)
        XCTAssertTrue(decision.shouldConvert)
        XCTAssertEqual(decision.confidence, .high)
    }

    // A valid word in the currently-active layout MUST NEVER be converted.
    func test_validActiveLayoutWord_isNotConverted() throws {
        let d = try makeDetector()
        XCTAssertFalse(d.evaluate(token: "hello", activeLayout: .latin).shouldConvert)
        XCTAssertFalse(d.evaluate(token: "привет", activeLayout: .cyrillic).shouldConvert)
    }

    // Gibberish that is not a word in EITHER layout (typical code identifiers /
    // random typing) must NOT be converted — the #1 false-positive complaint.
    func test_gibberishInBothLayouts_isNotConverted() throws {
        let d = try makeDetector()
        // "asdf" → cyrillic "фыва": neither is in its lexicon.
        XCTAssertFalse(d.evaluate(token: "asdf", activeLayout: .latin).shouldConvert)
        XCTAssertFalse(d.evaluate(token: "xyzzy", activeLayout: .latin).shouldConvert)
    }

    // Tokens with digits, or too short, are never auto-converted (high false-positive risk).
    func test_digitsAndVeryShortTokens_areNotConverted() throws {
        let d = try makeDetector()
        XCTAssertFalse(d.evaluate(token: "ab12", activeLayout: .latin).shouldConvert)
        XCTAssertFalse(d.evaluate(token: "a", activeLayout: .latin).shouldConvert)
    }
}
