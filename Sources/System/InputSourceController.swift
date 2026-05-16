import Carbon
import Core
import Foundation

/// Thin Carbon Text Input Source adapter. NOT unit-tested (mutates the live
/// system input source) — the selection logic is the pure, TDD'd
/// `InputSourceSelector`. This shim only enumerates real sources and calls TIS.
public final class InputSourceController {
    public init() {}

    private func string(_ src: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(src, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private func languages(_ src: TISInputSource) -> [String] {
        guard let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages)
        else { return [] }
        return (Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as? [String]) ?? []
    }

    private func isSelectable(_ src: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceIsSelectCapable)
        else { return false }
        return Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue() == kCFBooleanTrue
    }

    /// All keyboard input sources, paired with the live TIS handle.
    private func enumerate() -> [(info: InputSourceInfo, src: TISInputSource)] {
        guard let cf = TISCreateInputSourceList(nil, false)?.takeRetainedValue(),
              let list = cf as? [TISInputSource] else { return [] }
        return list.compactMap { src in
            guard let id = string(src, kTISPropertyInputSourceID) else { return nil }
            // Keyboard layouts / input modes only.
            let info = InputSourceInfo(
                id: id, languages: languages(src), isSelectable: isSelectable(src)
            )
            return (info, src)
        }
    }

    /// The layout class of the currently-active input source.
    public func currentLayout() -> Detector.Layout? {
        guard let cur = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        let langs = languages(cur)
        if langs.contains("ru") { return .cyrillic }
        if langs.contains("en") { return .latin }
        return nil
    }

    /// Activate the input source matching `layout` (honoring a user override).
    @discardableResult
    public func switchTo(
        _ layout: Detector.Layout, override: [Detector.Layout: String] = [:]
    ) -> Bool {
        let sources = enumerate()
        guard let chosen = InputSourceSelector.pick(
            for: layout, from: sources.map(\.info), override: override
        ), let handle = sources.first(where: { $0.info.id == chosen.id })?.src else {
            return false
        }
        return TISSelectInputSource(handle) == noErr
    }
}
