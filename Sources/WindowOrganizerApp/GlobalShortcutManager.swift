@preconcurrency import Carbon
import Foundation
import WindowOrganizerCore

final class GlobalShortcutManager: @unchecked Sendable {
    nonisolated(unsafe) static weak var activeManager: GlobalShortcutManager?

    private var hotKeyRefs: [OrganizerAction: EventHotKeyRef] = [:]
    private var actionByID: [UInt32: OrganizerAction] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?
    private let handler: (OrganizerAction) -> Void

    init(handler: @escaping (OrganizerAction) -> Void) {
        self.handler = handler
        Self.activeManager = self
        installHandlerIfNeeded()
    }

    deinit {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    /// Returns the actions whose shortcut macOS refused (usually: another app already owns it).
    @discardableResult
    func updateShortcuts(_ shortcuts: [OrganizerAction: OrganizerShortcut]) -> Set<OrganizerAction> {
        unregisterAll()

        var failed = Set<OrganizerAction>()
        for action in OrganizerAction.allCases {
            guard let shortcut = shortcuts[action], shortcut.isValid else {
                continue
            }
            if !register(shortcut, for: action) {
                failed.insert(action)
            }
        }
        return failed
    }

    private func register(_ shortcut: OrganizerShortcut, for action: OrganizerAction) -> Bool {
        guard let keyCode = shortcut.carbonKeyCode else {
            return false
        }

        let id = nextID
        nextID += 1
        let hotKeyID = EventHotKeyID(signature: 0x574F5247, id: id)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers(for: shortcut.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            return false
        }

        hotKeyRefs[action] = hotKeyRef
        actionByID[id] = action
        return true
    }

    private func unregisterAll() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actionByID.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { _, event, _ in
            guard let event else { return noErr }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else {
                return status
            }

            Task { @MainActor in
                GlobalShortcutManager.activeManager?.handleHotKey(id: hotKeyID.id)
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    private func handleHotKey(id: UInt32) {
        guard let action = actionByID[id] else {
            return
        }
        handler(action)
    }

    private func carbonModifiers(for modifiers: Set<ShortcutModifier>) -> UInt32 {
        var value: UInt32 = 0
        if modifiers.contains(.command) {
            value |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            value |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            value |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            value |= UInt32(shiftKey)
        }
        return value
    }
}
