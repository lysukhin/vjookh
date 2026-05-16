import XCTest
@testable import Core

final class PlausibilityTests: XCTestCase {
    // Latin tokens that are clearly NOT plausible English (used when the word
    // is in neither dictionary, e.g. an inflected RU word typed in EN layout).
    func test_latinGibberishIsImplausibleEnglish() {
        XCTAssertFalse(Plausibility.looksLikeLatin("ghbdtnjv"))  // приветом
        XCTAssertFalse(Plausibility.looksLikeLatin("ghjdthrf"))  // проверка
        XCTAssertFalse(Plausibility.looksLikeLatin(" djpdhfn"))  // возврат
    }

    func test_realEnglishLooksLikeLatin() {
        for w in ["computer", "keyboard", "the", "switching", "rhythm", "strength"] {
            XCTAssertTrue(Plausibility.looksLikeLatin(w), "\(w) should look English")
        }
    }

    func test_realCyrillicLooksLikeCyrillic() {
        for w in ["приветом", "проверка", "возврата", "компьютера"] {
            XCTAssertTrue(Plausibility.looksLikeCyrillic(w), "\(w) should look Russian")
        }
    }

    // No vowels at all → not a plausible word in either script. This is the
    // only reliably-separable structural signal (see Plausibility doc comment:
    // Russian-in-EN-layout strips Latin vowels; the reverse is not reliable,
    // so that direction stays dictionary-only).
    func test_noVowelsIsImplausible() {
        XCTAssertFalse(Plausibility.looksLikeLatin("bcdfg"))
        XCTAssertFalse(Plausibility.looksLikeCyrillic("бвгджз"))
    }
}
