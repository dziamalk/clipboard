import AppKit
import ServiceManagement

final class Settings: ObservableObject {
    static let shared = Settings()
    private let defaults = UserDefaults.standard

    @Published var maxItems: Int { didSet { defaults.set(maxItems, forKey: "maxItems") } }
    /// 0 means never expire.
    @Published var maxAgeDays: Int { didSet { defaults.set(maxAgeDays, forKey: "maxAgeDays") } }
    @Published var maxTextMB: Double { didSet { defaults.set(maxTextMB, forKey: "maxTextMB") } }
    @Published var maxImageMB: Double { didSet { defaults.set(maxImageMB, forKey: "maxImageMB") } }
    @Published var paused: Bool { didSet { defaults.set(paused, forKey: "paused") } }
    @Published var hotKeyCode: Int { didSet { defaults.set(hotKeyCode, forKey: "hotKeyCode") } }
    @Published var hotKeyMods: UInt { didSet { defaults.set(hotKeyMods, forKey: "hotKeyMods") } }
    @Published var hotKeyLabel: String { didSet { defaults.set(hotKeyLabel, forKey: "hotKeyLabel") } }
    @Published var launchAtLogin: Bool

    var maxTextBytes: Int { Int(maxTextMB * 1_048_576) }
    var maxImageBytes: Int { Int(maxImageMB * 1_048_576) }

    private init() {
        func int(_ key: String, _ fallback: Int) -> Int {
            UserDefaults.standard.object(forKey: key) == nil ? fallback : UserDefaults.standard.integer(forKey: key)
        }
        func dbl(_ key: String, _ fallback: Double) -> Double {
            UserDefaults.standard.object(forKey: key) == nil ? fallback : UserDefaults.standard.double(forKey: key)
        }
        maxItems = int("maxItems", 1000)
        maxAgeDays = int("maxAgeDays", 7)
        maxTextMB = dbl("maxTextMB", 1)
        maxImageMB = dbl("maxImageMB", 10)
        paused = UserDefaults.standard.bool(forKey: "paused")
        hotKeyCode = int("hotKeyCode", 9) // V
        hotKeyMods = UInt(int("hotKeyMods", Int(NSEvent.ModifierFlags([.command, .shift]).rawValue)))
        hotKeyLabel = UserDefaults.standard.string(forKey: "hotKeyLabel") ?? "V"
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Launch at login failed: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var hotKeyDescription: String {
        let flags = NSEvent.ModifierFlags(rawValue: hotKeyMods)
        var s = ""
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option) { s += "⌥" }
        if flags.contains(.shift) { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        return s + hotKeyLabel
    }
}
