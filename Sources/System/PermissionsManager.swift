import AppKit
import ApplicationServices

/// Checks/guides the Accessibility permission required for the event tap.
/// Thin shim — verified manually.
public enum PermissionsManager {
    /// Whether this process is trusted for Accessibility (required to create a
    /// keystroke-modifying event tap).
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the system Accessibility dialog if not yet trusted.
    @discardableResult
    public static func requestIfNeeded() -> Bool {
        let opt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([opt: true] as CFDictionary)
    }

    /// Open System Settings → Privacy & Security → Accessibility.
    public static func openAccessibilitySettings() {
        let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
