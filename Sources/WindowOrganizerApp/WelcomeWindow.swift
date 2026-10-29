import ServiceManagement
import SwiftUI
import WindowOrganizerCore

/// First-launch welcome (MBX-18): why the app exists, how to use it, how to get back in without the icon (MBX-8),
/// the login item (MBX-17) and the Accessibility grant. Shown once from AppDelegate, again from Settings > General.
@MainActor
enum WelcomeWindow {
    private static var window: NSWindow?

    static func show() {
        guard let controller = SettingsWindow.shared.controller else { return }
        if window?.isVisible != true {  // rebuilt each time so the shortcut text is current
            let w = NSWindow(contentViewController: NSHostingController(rootView: WelcomeView(
                controller: controller,
                onDone: { window?.close() })))
            w.title = "Welcome"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        if let window { AccessoryWindows.shared.show(window) }
    }
}

struct WelcomeView: View {
    @ObservedObject var controller: AppController
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 56, height: 56).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Window Organizer").font(.title2.bold())
                    Text("Too many apps and windows open? Window Organizer clears them all at once: minimize, close, quit or force quit, from the menu bar or a keyboard shortcut.")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            row("menubar.rectangle", "Window Organizer lives in the menu bar.",
                "Click its icon to minimize all windows, close all windows, quit apps or force quit apps. Force Quit always asks first.")
            row("keyboard", "Or press a shortcut from any app.", shortcutsDetail)
            row("hand.raised", "Minimize and Close need Accessibility access.",
                "Quit and Force Quit work without it. Finder, menu bar apps and background processes are skipped by default; change that per app in Settings > Apps.")
            row("questionmark.circle", "Icon missing?",
                "The shortcuts still work. Open Window Organizer again from Applications to get Settings, or check System Settings > Menu Bar.")
            LaunchAtLoginToggle()
            SupportBox()
            HStack {
                if !controller.isAccessibilityGranted {
                    // Prompt + System Settings > Privacy & Security > Accessibility.
                    Button("Allow Accessibility…") { controller.grantAccessibility() }
                }
                Spacer()
                Button("Done", action: onDone).keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear { controller.refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refreshPermissions()  // the user may have granted it in System Settings
        }
    }

    /// The live shortcuts, so a rebound key is never described wrong.
    private var shortcutsDetail: String {
        let keys = OrganizerAction.allCases.compactMap { action in
            controller.preferences.shortcuts[action].map { "\(shortName(action)) \($0.displayString)" }
        }
        return (keys.isEmpty ? "No shortcuts are set." : keys.joined(separator: ", ") + ".") + " Change them in Settings > Shortcuts."
    }

    private func shortName(_ action: OrganizerAction) -> String {
        switch action {
        case .minimizeAllWindows: "Minimize"
        case .closeAllWindows: "Close"
        case .quitApps: "Quit"
        case .forceQuitApps: "Force Quit"
        }
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.tint).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Settings > General and the welcome window (MBX-17): user action only, status re-read on activation.
struct LaunchAtLoginToggle: View {
    @State private var status = SMAppService.mainApp.status

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Open at Login", isOn: Binding(
                get: { status == .enabled },
                set: { on in
                    try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    status = SMAppService.mainApp.status
                }))
            if status == .requiresApproval {
                Button("Allow in Login Items…") { SMAppService.openSystemSettingsLoginItems() }
            } else if status == .notFound {
                Text("Move Window Organizer to Applications to open it at login.").font(.callout).foregroundStyle(.secondary)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            status = SMAppService.mainApp.status  // the user may change it in System Settings
        }
    }
}

/// Quiet Ko-fi box (house style H1): the app's own next step stays the primary button, so this one is `.bordered`.
struct SupportBox: View {
    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free and open source").font(.headline)
                    Text("If Window Organizer saves you time, a coffee on Ko-fi keeps the next one coming.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Link("Support on Ko-fi ☕", destination: WindowOrganizerApp.koFiURL).buttonStyle(.bordered)
            }
            .padding(4)
        }
    }
}
