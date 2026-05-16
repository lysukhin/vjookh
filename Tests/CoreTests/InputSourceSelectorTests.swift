import XCTest
@testable import Core

final class InputSourceSelectorTests: XCTestCase {
    private let sources = [
        InputSourceInfo(id: "com.apple.keylayout.ABC", languages: ["en"], isSelectable: true),
        InputSourceInfo(id: "com.apple.keylayout.Russian", languages: ["ru"], isSelectable: true),
        InputSourceInfo(id: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectable: true),
        InputSourceInfo(id: "com.apple.keylayout.NotSelectable", languages: ["ru"], isSelectable: false),
    ]

    func test_picksFirstSelectableSourceForLanguage() {
        XCTAssertEqual(
            InputSourceSelector.pick(for: .latin, from: sources)?.id,
            "com.apple.keylayout.ABC"
        )
        XCTAssertEqual(
            InputSourceSelector.pick(for: .cyrillic, from: sources)?.id,
            "com.apple.keylayout.Russian"
        )
    }

    func test_userOverrideWinsWhenItExistsAmongSources() {
        let override: [Detector.Layout: String] = [.cyrillic: "com.apple.keylayout.RussianWin"]
        XCTAssertEqual(
            InputSourceSelector.pick(for: .cyrillic, from: sources, override: override)?.id,
            "com.apple.keylayout.RussianWin"
        )
    }

    func test_ignoresNonSelectableSources_andReturnsNilWhenNoneMatch() {
        let onlyUnusable = [
            InputSourceInfo(id: "x", languages: ["ru"], isSelectable: false),
        ]
        XCTAssertNil(InputSourceSelector.pick(for: .cyrillic, from: onlyUnusable))
        XCTAssertNil(InputSourceSelector.pick(for: .latin, from: sources.filter { $0.languages == ["ru"] }))
    }
}
