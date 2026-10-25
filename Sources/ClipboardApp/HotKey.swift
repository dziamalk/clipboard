import AppKit
import Carbon.HIToolbox

final class HotKey {
    static var action: (() -> Void)?
    private static var handlerInstalled = false
    private var ref: EventHotKeyRef?

    func register(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
        unregister()
        if !Self.handlerInstalled {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                HotKey.action?()
                return noErr
            }, 1, &spec, nil, nil)
            Self.handlerInstalled = true
        }
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        let id = EventHotKeyID(signature: OSType(0x434C4950), id: 1) // 'CLIP'
        RegisterEventHotKey(UInt32(keyCode), carbon, id, GetApplicationEventTarget(), 0, &ref)
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
    }
}
