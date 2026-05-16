import XCTest
@testable import Core

final class LayoutMapTests: XCTestCase {
    /// The six keys spelling "ghbdtn" / "привет" on the standard ЙЦУКЕН ↔ QWERTY layout.
    private let privetPairs: [(Character, Character)] = [
        ("g", "п"), ("h", "р"), ("b", "и"), ("d", "в"), ("t", "е"), ("n", "т"),
    ]

    func test_toCyrillic_transliteratesLatinTypedToCyrillic() {
        let map = LayoutMap(pairs: privetPairs)
        XCTAssertEqual(map.toCyrillic("ghbdtn"), "привет")
    }

    func test_toLatin_isInverseOfToCyrillic() {
        let map = LayoutMap(pairs: privetPairs)
        XCTAssertEqual(map.toLatin("привет"), "ghbdtn")
    }

    func test_initFromJSON_rejectsLengthMismatch() {
        let json = #"{ "latin": "ab", "cyrillic": "я" }"#
        XCTAssertThrowsError(try LayoutMap(jsonData: Data(json.utf8)))
    }

    func test_initFromJSON_convertsUsingLoadedPairs() throws {
        let json = #"{ "latin": "ghbdtn", "cyrillic": "привет" }"#
        let map = try LayoutMap(jsonData: Data(json.utf8))
        XCTAssertEqual(map.toCyrillic("ghbdtn"), "привет")
        XCTAssertEqual(map.toLatin("привет"), "ghbdtn")
    }

    func test_bundledEnRu_convertsRealisticText() throws {
        let map = try LayoutMap.load(pair: "en-ru")
        XCTAssertEqual(map.toCyrillic("ghbdtn vbh"), "привет мир")
        XCTAssertEqual(map.toCyrillic("Ghbdtn"), "Привет")
        // Unmapped characters (digits, space) pass through unchanged.
        XCTAssertEqual(map.toCyrillic("test123 "), "еуые123 ")
    }

    func test_bundledEnRu_isBijectiveOverLatinAlphabet() throws {
        let map = try LayoutMap.load(pair: "en-ru")
        let sample = "the quick brown fox jumps over THE LAZY DOG"
        XCTAssertEqual(map.toLatin(map.toCyrillic(sample)), sample)
    }
}
