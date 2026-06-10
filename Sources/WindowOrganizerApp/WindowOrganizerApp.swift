import SwiftUI
import WindowOrganizerCore

@main
struct WindowOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = AppController()

    var body: some Scene {
        MenuBarExtra("Window Organizer", systemImage: "rectangle.3.group") {
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

            Button("Quit Window Organizer") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView(controller: controller)
                .frame(
                    minWidth: SettingsLayoutMetrics.windowMinimumWidth,
                    minHeight: SettingsLayoutMetrics.windowMinimumHeight,
                    alignment: .top
                )
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
