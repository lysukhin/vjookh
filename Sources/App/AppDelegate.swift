import AppKit
import Core

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var tap: EventTapController?
    private var pipeline: CorrectionPipeline?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpMenuBar()

        if PermissionsManager.requestIfNeeded() {
            startEngine()
        } else {
            notifyPermissionNeeded()
            // Onboarding without relaunch: poll until the grant lands, then
            // start the engine automatically.
            permissionTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0, repeats: true
            ) { [weak self] _ in
                guard PermissionsManager.isTrusted else { return }
                self?.permissionTimer?.invalidate()
                self?.permissionTimer = nil
                self?.startEngine()
            }
        }
    }

    private func startEngine() {
        guard tap == nil else { return }  // idempotent (timer + relaunch safety)
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

    // MARK: Menu

    private func setUpMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let icon = NSImage(named: "StatusIcon") {
            icon.isTemplate = true  // let macOS tint for light/dark menu bars
            icon.size = NSSize(width: 18, height: 18)
            item.button?.image = icon
        } else {
            item.button?.title = "⌨︎"  // fallback if the asset is missing
        }
        let menu = NSMenu()
        menu.delegate = self  // rebuilt on open so dynamic items stay current
        item.menu = menu
        statusItem = item
    }

    /// Rebuilt every time the menu opens so the per-app exclusion and
    /// launch-at-login states reflect reality.
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let enabled = menuItem("Enabled", #selector(toggleEnabled),
                               on: Settings.shared.isEnabled)
        menu.addItem(enabled)

        if let app = NSWorkspace.shared.frontmostApplication,
           let bid = app.bundleIdentifier {
            let name = app.localizedName ?? bid
            let excluded = Settings.shared.isExcluded(bid)
            let mi = menuItem(
                "Ignore “\(name)”", #selector(toggleExcludeFrontmost), on: excluded
            )
            mi.representedObject = bid
            menu.addItem(mi)
        }

        menu.addItem(menuItem("Launch at Login", #selector(toggleLogin),
                              on: LoginItem.isEnabled))

        menu.addItem(.separator())
        let hint = NSMenuItem(
            title: "Double-tap ⇧ Shift — fix last word", action: nil, keyEquivalent: ""
        )
        hint.isEnabled = false
        menu.addItem(hint)

        if !PermissionsManager.isTrusted {
            let warn = NSMenuItem(
                title: "⚠︎ Grant Accessibility…",
                action: #selector(openAccessibility), keyEquivalent: ""
            )
            warn.target = self
            menu.addItem(warn)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit vjookh", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func menuItem(_ title: String, _ sel: Selector, on: Bool) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        mi.target = self
        mi.state = on ? .on : .off
        return mi
    }

    @objc private func toggleEnabled() { Settings.shared.isEnabled.toggle() }

    @objc private func toggleExcludeFrontmost(_ sender: NSMenuItem) {
        guard let bid = sender.representedObject as? String else { return }
        var set = Settings.shared.excludedBundleIDs
        if set.contains(bid) { set.remove(bid) } else { set.insert(bid) }
        Settings.shared.excludedBundleIDs = set
    }

    @objc private func toggleLogin() { LoginItem.setEnabled(!LoginItem.isEnabled) }

    @objc private func openAccessibility() {
        PermissionsManager.openAccessibilitySettings()
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func notifyPermissionNeeded() {
        let alert = NSAlert()
        alert.messageText = "Accessibility permission required"
        alert.informativeText =
            "Grant vjookh access in System Settings → Privacy & Security → "
            + "Accessibility. vjookh starts automatically once granted — no "
            + "relaunch needed."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            PermissionsManager.openAccessibilitySettings()
        }
    }
}
