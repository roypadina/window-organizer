import AppKit
import SwiftUI
import WindowOrganizerCore

/// Click, then press a key combination. Esc cancels, Delete removes the shortcut.
/// A local key monitor swallows the keys, so ⌘Q / ⌘W can't trigger menu items while recording.
struct ShortcutRecorder: View {
    let action: OrganizerAction
    @ObservedObject var controller: AppController
    @Binding var hint: String?
    @State private var monitor: Any?
    @State private var heldModifiers = Set<ShortcutModifier>()

    private var isRecording: Bool { controller.recordingAction == action }
    private var shortcut: OrganizerShortcut? { controller.preferences.shortcuts[action] }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isRecording ? stop() : start()
            } label: {
                Text(label)
                    .foregroundStyle(isRecording || shortcut == nil ? .secondary : .primary)
                    .frame(minWidth: 120)
            }
            .buttonStyle(.bordered)
            .overlay {
                if isRecording {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }

            Button {
                stop()
                controller.preferences.shortcuts[action] = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove shortcut")
            .opacity(shortcut == nil || isRecording ? 0 : 1)
            .disabled(shortcut == nil || isRecording)
        }
        .onChange(of: isRecording) { _, recording in
            // Another recorder took over: drop this one's monitor.
            if !recording { removeMonitor() }
        }
        .onDisappear(perform: stop)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            if isRecording { stop() }
        }
    }

    private var label: String {
        guard isRecording else { return shortcut?.displayString ?? "Record Shortcut" }
        let held = heldModifiers.sorted().map(\.symbol).joined()
        return held.isEmpty ? "Type shortcut…" : held + "…"
    }

    private func start() {
        controller.recordingAction = action
        hint = nil
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            MainActor.assumeIsolated {
                if event.type == .flagsChanged {
                    heldModifiers = ShortcutModifier.set(from: event.modifierFlags)
                } else {
                    handle(event)
                }
            }
            return nil
        }
    }

    private func stop() {
        removeMonitor()
        if isRecording { controller.recordingAction = nil }
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        heldModifiers = []
    }

    private func handle(_ event: NSEvent) {
        let modifiers = ShortcutModifier.set(from: event.modifierFlags)

        if event.keyCode == 0x35 {  // Esc
            stop()
            return
        }
        if modifiers.isEmpty, [0x33, 0x75].contains(event.keyCode) {  // Delete / Forward Delete
            stop()
            controller.preferences.shortcuts[action] = nil
            return
        }

        // Unshifted character, so ⇧⌘2 reads "⇧⌘2", not "⇧⌘@".
        let label = OrganizerShortcut.specialKeyLabels[event.keyCode]
            ?? event.characters(byApplyingModifiers: [])?.uppercased() ?? ""
        let candidate = OrganizerShortcut(key: label, modifiers: modifiers, keyCode: event.keyCode)

        guard candidate.isValid, !label.isEmpty else {
            NSSound.beep()
            hint = "Use ⌘, ⌃ or ⌥ with the key. Function keys work alone."
            return
        }
        if let other = controller.preferences.conflictingAction(for: candidate, excluding: action) {
            NSSound.beep()
            hint = "\(candidate.displayString) is already used by \(other.title)."
            return
        }

        // Stop first (re-registers the old set), then save (didSet registers the new one).
        stop()
        controller.preferences.shortcuts[action] = candidate
    }
}

extension ShortcutModifier {
    static func set(from flags: NSEvent.ModifierFlags) -> Set<ShortcutModifier> {
        var modifiers = Set<ShortcutModifier>()
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        return modifiers
    }
}
