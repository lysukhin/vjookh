import AppKit
import Core

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var tap: EventTapController?
    private var pipeline: CorrectionPipeline?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpMenuBar()

        guard PermissionsManager.requestIfNeeded() else {
            // Not trusted yet — user must grant, then relaunch.
            notifyPermissionNeeded()
            return
        }
        startEngine()
    }

    private func startEngine() {
        guard let map = try? LayoutMap.load(pair: "en-ru"),
              let en = try? Lexicon.load(name: "en"),
              let ru = try? Lexicon.load(name: "ru") else {
            NSLog("[vjookh] failed to load layout/dictionaries"); return
        }
        let detector = Detector(latin: en, cyrillic: ru, map: map)
        let pipeline = CorrectionPipeline(
            map: map, detector: detector,
            synth: InputSynthesizer(), inputSource: InputSourceController(),
            frontmostBundleID: { NSWorkspace.shared.frontmostApplication?.bundleIdentifier }
        )
        let tap = EventTapController(
            onKeystroke: { [weak pipeline] k in pipeline?.ingest(k) },
            onShift: { [weak pipeline] isDown in pipeline?.handleShift(isDown) }
        )
        tap.start()

        self.pipeline = pipeline
        self.tap = tap
    }

    private func setUpMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "⌨︎"
        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: ""
        )
        toggle.target = self
        toggle.state = Settings.shared.isEnabled ? .on : .off
        menu.addItem(toggle)
        menu.addItem(.separator())
        let hint = NSMenuItem(
            title: "Double-tap ⇧ Shift — fix last word", action: nil, keyEquivalent: ""
        )
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit vjookh", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        Settings.shared.isEnabled.toggle()
        sender.state = Settings.shared.isEnabled ? .on : .off
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func notifyPermissionNeeded() {
        let alert = NSAlert()
        alert.messageText = "Accessibility permission required"
        alert.informativeText =
            "Grant vjookh access in System Settings → Privacy & Security → "
            + "Accessibility, then relaunch."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            PermissionsManager.openAccessibilitySettings()
        }
    }
}
