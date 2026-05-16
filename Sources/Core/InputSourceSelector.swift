/// A keyboard input source as seen from the pure layer (the TIS adapter
/// converts real `TISInputSource`s into these).
public struct InputSourceInfo: Equatable {
    public let id: String
    public let languages: [String]
    public let isSelectable: Bool

    public init(id: String, languages: [String], isSelectable: Bool) {
        self.id = id
        self.languages = languages
        self.isSelectable = isSelectable
    }
}

/// Picks which input source to activate for a given layout. Pure: the only
/// testable logic extracted from the TIS adapter.
public enum InputSourceSelector {
    private static func languageCode(for layout: Detector.Layout) -> String {
        switch layout {
        case .latin: return "en"
        case .cyrillic: return "ru"
        }
    }

    public static func pick(
        for layout: Detector.Layout,
        from sources: [InputSourceInfo],
        override: [Detector.Layout: String] = [:]
    ) -> InputSourceInfo? {
        if let wantedID = override[layout],
           let match = sources.first(where: { $0.id == wantedID && $0.isSelectable }) {
            return match
        }
        let code = languageCode(for: layout)
        return sources.first { $0.isSelectable && $0.languages.contains(code) }
    }
}
