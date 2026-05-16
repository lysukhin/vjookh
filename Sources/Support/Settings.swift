import Foundation

/// The only persisted state (privacy invariant: no keystrokes ever touch disk).
public final class Settings {
    public static let shared = Settings()
    private let defaults = UserDefaults.standard
    private enum Key {
        static let enabled = "enabled"
        static let excluded = "excludedBundleIDs"
    }

    private init() {
        defaults.register(defaults: [Key.enabled: true])
    }

    public var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// Bundle identifiers where auto-correction is suppressed (e.g. IDEs).
    public var excludedBundleIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.excluded) ?? []) }
        set { defaults.set(Array(newValue), forKey: Key.excluded) }
    }

    public func isExcluded(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return excludedBundleIDs.contains(bundleID)
    }
}
