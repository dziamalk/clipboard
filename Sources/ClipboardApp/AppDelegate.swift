import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = ClipboardMonitor()
    private lazy var popup = PopupController(monitor: monitor)
    private let hotKey = HotKey()
    private var statusItem: NSStatusItem!
    private var pauseItem: NSMenuItem!
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var pruneTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.shared
        monitor.start()
        HistoryStore.shared.prune()
        pruneTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in HistoryStore.shared.prune() }

        HotKey.action = { [weak self] in self?.popup.toggle() }
        registerHotKey()
        Publishers.CombineLatest(settings.$hotKeyCode, settings.$hotKeyMods)
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.registerHotKey() }
            .store(in: &cancellables)

        setUpStatusItem()
        _ = Paster.hasAccessibility(prompt: true)
    }

    private func registerHotKey() {
        let s = Settings.shared
        hotKey.register(keyCode: s.hotKeyCode, modifiers: NSEvent.ModifierFlags(rawValue: s.hotKeyMods))
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "Show History", action: #selector(showHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        pauseItem = menu.addItem(withTitle: "Pause Recording", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(withTitle: "Clear History…", action: #selector(clearHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Quit Clipboard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        pauseItem.state = Settings.shared.paused ? .on : .off
        menu.items.first?.title = "Show History (\(Settings.shared.hotKeyDescription))"
    }

    @objc private func showHistory() {
        // Let the status menu finish dismissing before the popup takes key.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.popup.show() }
    }

    @objc private func togglePause() { Settings.shared.paused.toggle() }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear all clipboard history?"
        alert.informativeText = "This cannot be undone."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { HistoryStore.shared.clear() }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = "Clipboard Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
