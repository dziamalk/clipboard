import AppKit

enum Paster {
    static func paste(_ item: ClipItem, plainOnly: Bool, monitor: ClipboardMonitor) {
        let store = HistoryStore.shared
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .text:
            if !plainOnly {
                if let rtf = store.rtf(item) { pb.setData(rtf, forType: .rtf) }
                if let html = store.html(item) { pb.setData(html, forType: .html) }
            }
            pb.setString(item.text ?? "", forType: .string)
        case .image:
            if let data = try? Data(contentsOf: store.imageURL(item)) {
                pb.setData(data, forType: .png)
            }
        }
        monitor.ignoreCurrentChange()
        store.bump(item.id)

        guard hasAccessibility(prompt: true) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { sendCommandV() }
    }

    static func hasAccessibility(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    private static func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
