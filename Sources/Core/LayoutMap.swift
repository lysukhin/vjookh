import Foundation

/// Bidirectional positional keyboard-layout transliterator.
///
/// Given the set of (latin, cyrillic) character pairs that occupy the same
/// physical keys, converts a token as if it had been typed in the other
/// layout. Pure: no system APIs, no I/O.
public struct LayoutMap {
    private let latinToCyrillic: [Character: Character]
    private let cyrillicToLatin: [Character: Character]

    public enum LoadError: Error { case lengthMismatch, malformed, resourceNotFound }

    /// Load a layout pair, e.g. `"en-ru"` → `Resources/Layouts/en-ru.json`.
    /// Falls back to an embedded copy so the canonical `en-ru` pair always
    /// loads even if resource bundling is misconfigured.
    public static func load(pair name: String) throws -> LayoutMap {
        if let url = ResourceBundle.url(
            forResource: name, withExtension: "json", subdirectory: "Resources/Layouts"
        ) {
            return try LayoutMap(jsonData: Data(contentsOf: url))
        }
        if name == "en-ru" {
            return try LayoutMap(jsonData: Data(Self.embeddedEnRuJSON.utf8))
        }
        throw LoadError.resourceNotFound
    }

    /// Embedded copy of `Resources/Layouts/en-ru.json` — the canonical pair
    /// must load even if resource bundling is misconfigured.
    private static let embeddedEnRuJSON = """
    {"latin":"qwertyuiop[]asdfghjkl;'zxcvbnm,./`QWERTYUIOP{}ASDFGHJKL:\\"ZXCVBNM<>?~",\
    "cyrillic":"йцукенгшщзхъфывапролджэячсмитьбю.ёЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"}
    """

    /// JSON shape: `{ "latin": "...", "cyrillic": "..." }` — two equal-length
    /// strings whose characters are positionally paired.
    public init(jsonData: Data) throws {
        struct Spec: Decodable { let latin: String; let cyrillic: String }
        let spec: Spec
        do {
            spec = try JSONDecoder().decode(Spec.self, from: jsonData)
        } catch {
            throw LoadError.malformed
        }
        guard spec.latin.count == spec.cyrillic.count else {
            throw LoadError.lengthMismatch
        }
        self.init(pairs: Array(zip(spec.latin, spec.cyrillic)))
    }

    public init(pairs: [(Character, Character)]) {
        var l2c: [Character: Character] = [:]
        var c2l: [Character: Character] = [:]
        for (latin, cyrillic) in pairs {
            l2c[latin] = cyrillic
            c2l[cyrillic] = latin
        }
        self.latinToCyrillic = l2c
        self.cyrillicToLatin = c2l
    }

    /// Re-interpret a Latin-typed token as if typed in the Cyrillic layout.
    public func toCyrillic(_ token: String) -> String {
        String(token.map { latinToCyrillic[$0] ?? $0 })
    }

    /// Re-interpret a Cyrillic-typed token as if typed in the Latin layout.
    public func toLatin(_ token: String) -> String {
        String(token.map { cyrillicToLatin[$0] ?? $0 })
    }
}
