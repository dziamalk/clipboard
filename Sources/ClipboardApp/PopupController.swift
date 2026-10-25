import AppKit
import SwiftUI

private final class PopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class PopupController: NSObject, NSWindowDelegate {
    private let monitor: ClipboardMonitor
    private var panel: PopupPanel?
    private var keyMonitor: Any?
    private var model: PopupViewModel?

    init(monitor: ClipboardMonitor) { self.monitor = monitor }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() { isVisible ? hide() : show() }

    func show() {
        hide()
        let model = PopupViewModel()
        self.model = model
        let view = PopupView(model: model) { [weak self] item, plain in self?.pick(item, plain: plain) }
        let host = NSHostingView(rootView: view)
        let size = NSSize(width: 440, height: 380)
        host.frame = NSRect(origin: .zero, size: size)

        let panel = PopupPanel(contentRect: NSRect(origin: .zero, size: size),
                               styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        panel.setFrameOrigin(origin(for: size))
        self.panel = panel

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event) ?? event
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panel?.delegate = nil
        panel?.orderOut(nil)
        panel = nil
        model = nil
    }

    func windowDidResignKey(_ notification: Notification) { hide() }

    private func pick(_ item: ClipItem, plain: Bool) {
        hide()
        Paster.paste(item, plainOnly: plain, monitor: monitor)
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let model else { return event }
        let cmd = event.modifierFlags.contains(.command)
        switch event.keyCode {
        case 53: hide()
        case 125: model.move(1)
        case 126: model.move(-1)
        case 36, 76:
            if let item = model.current { pick(item, plain: event.modifierFlags.contains(.shift)) }
        case 51 where cmd: model.deleteCurrent()
        default: return event
        }
        return nil
    }

    /// Near the mouse cursor, kept fully on the screen the cursor is on.
    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let area = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var x = mouse.x
        var y = mouse.y - size.height
        x = min(max(x, area.minX + 8), area.maxX - size.width - 8)
        y = min(max(y, area.minY + 8), area.maxY - size.height - 8)
        return NSPoint(x: x, y: y)
    }
}
