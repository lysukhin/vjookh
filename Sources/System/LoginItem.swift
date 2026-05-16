import ServiceManagement

/// Launch-at-login via `SMAppService` (macOS 13+). Thin adapter.
public enum LoginItem {
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static func setEnabled(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("[vjookh] login item toggle failed: \(error)")
        }
    }
}
