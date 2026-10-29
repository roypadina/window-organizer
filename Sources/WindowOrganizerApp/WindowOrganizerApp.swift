import SwiftUI
import WindowOrganizerCore

@main
struct WindowOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Plain let, not @StateObject: the Settings window needs the same controller, and it is built once here.
    private let controller: AppController

    init() {
        let controller = AppController()
        self.controller = controller
        SettingsWindow.shared.controller = controller
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(nsImage: Self.menuBarIcon)
                .accessibilityLabel("Window Organizer")
        }
        .commands {  // App menu while a window is open (policy .regular)
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { SettingsWindow.shared.show() }.keyboardShortcut(",")
            }
        }
    }
}

private struct MenuContent: View {
    @ObservedObject var controller: AppController

    var body: some View {
        actionButton(.minimizeAllWindows)
        actionButton(.closeAllWindows)
        actionButton(.quitApps)

        Divider()

        Button("Force Quit Apps…") {
            controller.perform(.forceQuitApps)
        }

        Divider()

        Button("Settings…") { SettingsWindow.shared.show() }.keyboardShortcut(",")

        Divider()

        Button("About Window Organizer") {
            AboutWindow.show()
        }

        Button("Support on Ko-fi ☕") {
            NSWorkspace.shared.open(WindowOrganizerApp.koFiURL)
        }

        Button("Quit Window Organizer") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func actionButton(_ action: OrganizerAction) -> some View {
        Button(action.title) {
            controller.perform(action)
        }
        .keyboardShortcut(controller.preferences.shortcuts[action]?.menuShortcut)
    }
}

private extension OrganizerShortcut {
    /// Shows the recorded global shortcut in the menu (KBD-1). Display only: the Carbon hot key consumes the
    /// keystroke first, so the item can't double-fire. Letters and digits only; other keys have no safe key equivalent.
    var menuShortcut: KeyboardShortcut? {
        guard let keyCode, Self.specialKeyLabels[keyCode] == nil, key.count == 1,
              let character = key.lowercased().first, character.isLetter || character.isNumber else { return nil }
        var modifiers: EventModifiers = []
        if self.modifiers.contains(.command) { modifiers.insert(.command) }
        if self.modifiers.contains(.option) { modifiers.insert(.option) }
        if self.modifiers.contains(.control) { modifiers.insert(.control) }
        if self.modifiers.contains(.shift) { modifiers.insert(.shift) }
        return KeyboardShortcut(KeyEquivalent(character), modifiers: modifiers)
    }
}

extension WindowOrganizerApp {
    static let koFiURL = URL(string: "https://ko-fi.com/roypadina")!

    /// Template image bundled by Scripts/package_app.sh; `swift run` has no bundle resources, so it falls back to an SF Symbol.
    static let menuBarIcon: NSImage = {
        let image = NSImage(named: "menubar")
            ?? NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: nil)
            ?? NSImage()
        image.isTemplate = true
        image.accessibilityDescription = "Window Organizer"
        return image
    }()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    /// Opening Window Organizer again (Finder, Raycast) shows Settings: the way in when the icon is hidden (MBX-8).
    @MainActor func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { SettingsWindow.shared.show() }
        return true
    }
}
