import XCTest
@testable import Core

final class LexiconTests: XCTestCase {
    func test_bundledDictionariesLoadAndContainCommonWords() throws {
        let en = try Lexicon.load(name: "en")
        let ru = try Lexicon.load(name: "ru")
        XCTAssertGreaterThan(en.count, 20_000)
        XCTAssertGreaterThan(ru.count, 50_000)
        XCTAssertTrue(en.contains("hello"))
        XCTAssertTrue(en.contains("computer"))
        XCTAssertTrue(ru.contains("привет"))
        XCTAssertTrue(ru.contains("компьютер"))
        // Cross-check that drives the detector: gibberish maps to a real word.
        XCTAssertFalse(en.contains("ghbdtn"))
        XCTAssertTrue(ru.contains("привет"))
    }

    func test_contains_isCaseInsensitive() {
        let lex = Lexicon(words: ["hello", "Москва"])
        XCTAssertTrue(lex.contains("hello"))
        XCTAssertTrue(lex.contains("HELLO"))
        XCTAssertTrue(lex.contains("москва"))
        XCTAssertFalse(lex.contains("zzzznope"))
    }

    // hunspell .dic format: a leading entry-count line, then `stem/AFFIXFLAGS`.
    func test_initFromText_parsesHunspellDicFormat() {
        let dic = "3\nдом/SG\nкот\nlinux/MS\n"
        let lex = Lexicon(text: dic)
        XCTAssertTrue(lex.contains("дом"))      // affix flags stripped
        XCTAssertTrue(lex.contains("кот"))
        XCTAssertTrue(lex.contains("linux"))
        XCTAssertFalse(lex.contains("3"))       // count line is not a word
        XCTAssertFalse(lex.contains("дом/SG"))
    }

    func test_initFromText_parsesNewlineSeparatedTrimmedWords() {
        let text = "hello\n  world  \n\nМир\n"
        let lex = Lexicon(text: text)
        XCTAssertTrue(lex.contains("world"))
        XCTAssertTrue(lex.contains("мир"))
        XCTAssertFalse(lex.contains(""))  // blank lines are not members
    }
}
