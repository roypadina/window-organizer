import SwiftUI
import WindowOrganizerCore

@main
struct WindowOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            Button(OrganizerAction.minimizeAllWindows.title) {
                controller.perform(.minimizeAllWindows)
            }
            .keyboardShortcut("m")

            Button(OrganizerAction.closeAllWindows.title) {
                controller.perform(.closeAllWindows)
            }
            .keyboardShortcut("w")

            Button(OrganizerAction.quitApps.title) {
                controller.perform(.quitApps)
            }
            .keyboardShortcut("q")

            Divider()

            Button("Force Quit Apps...") {
                controller.perform(.forceQuitApps)
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }

            Divider()

            Button("About Window Organizer") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.orderFrontStandardAboutPanel(options: [.credits: Self.aboutCredits])
            }

            Button("Support on Ko-fi ☕") {
                NSWorkspace.shared.open(Self.koFiURL)
            }

            Divider()

            Button("Quit Window Organizer") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }

        Settings {
            SettingsView(controller: controller)
        }
    }
}

extension WindowOrganizerApp {
    static let koFiURL = URL(string: "https://ko-fi.com/roypadina")!

    static let aboutCredits: NSAttributedString = {
        let text = NSMutableAttributedString(
            string: "Made by Roy Padina\n\nI'm a software engineer from Israel who builds small, focused Mac tools to fix the little annoyances in my own day — then shares them free and open source.\n\nIf this app saves you time, a coffee on Ko-fi keeps the next one coming. ☕\n\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.labelColor])
        text.append(NSAttributedString(string: "Support on Ko-fi ☕", attributes: [.font: NSFont.systemFont(ofSize: 11), .link: koFiURL]))
        return text
    }()

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
}
