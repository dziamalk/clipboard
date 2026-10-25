import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var trusted = Paster.hasAccessibility(prompt: false)

    var body: some View {
        Form {
            HotKeyRecorder(settings: settings)
            Toggle("Pause recording", isOn: $settings.paused)
            Toggle("Launch at login", isOn: Binding(
                get: { settings.launchAtLogin }, set: { settings.setLaunchAtLogin($0) }))
            Section("History") {
                Stepper("Max items: \(settings.maxItems)", value: $settings.maxItems, in: 50...20000, step: 50)
                Stepper(settings.maxAgeDays == 0 ? "Delete after: never" : "Delete after: \(settings.maxAgeDays) days",
                        value: $settings.maxAgeDays, in: 0...365)
                Stepper("Skip text over: \(settings.maxTextMB, specifier: "%.1f") MB",
                        value: $settings.maxTextMB, in: 0.1...20, step: 0.5)
                Stepper("Skip images over: \(settings.maxImageMB, specifier: "%.0f") MB",
                        value: $settings.maxImageMB, in: 1...100)
            }
            Section("Permissions") {
                HStack {
                    Text(trusted ? "Accessibility: granted (auto-paste works)" : "Accessibility: not granted (needed to auto-paste)")
                    if !trusted {
                        Button("Grant…") { _ = Paster.hasAccessibility(prompt: true) }
                    }
                    Button("Refresh") { trusted = Paster.hasAccessibility(prompt: false) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HotKeyRecorder: View {
    @ObservedObject var settings: Settings
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        LabeledContent("Hotkey") {
            Button(recording ? "Press shortcut… (esc to cancel)" : settings.hotKeyDescription) {
                recording ? stop() : start()
            }
        }
        .onDisappear { stop() }
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { stop(); return nil }
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else { return nil }
            settings.hotKeyCode = Int(event.keyCode)
            settings.hotKeyMods = mods.rawValue
            settings.hotKeyLabel = event.keyCode == 49 ? "Space"
                : (event.charactersIgnoringModifiers ?? "?").uppercased()
            stop()
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
