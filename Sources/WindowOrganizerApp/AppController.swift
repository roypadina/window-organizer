import AppKit
import Combine
import Foundation
import WindowOrganizerCore

@MainActor
final class AppController: ObservableObject {
    @Published var preferences: OrganizerPreferences {
        didSet {
            preferencesStore.save(preferences)
            applyShortcuts()
        }
    }

    @Published private(set) var isAccessibilityGranted: Bool
    /// The action whose shortcut is being recorded. Global hot keys are paused meanwhile,
    /// so pressing the current combo is captured instead of firing the action.
    @Published var recordingAction: OrganizerAction? {
        didSet {
            applyShortcuts()
        }
    }
    /// Actions whose shortcut macOS refused, usually because another app already owns it.
    @Published private(set) var unavailableShortcuts: Set<OrganizerAction> = []
    @Published var statusMessage: String = "Ready"

    private let preferencesStore: PreferencesPersisting
    private let permissionsHelper: PermissionsHelping
    private let actionEngine: WindowActionEngine
    private var shortcutManager: GlobalShortcutManager?
    private var workspaceObservers: [NSObjectProtocol] = []

    init(
        preferencesStore: PreferencesPersisting = UserDefaultsPreferencesStore(),
        permissionsHelper: PermissionsHelping = PermissionsHelper(),
        actionEngine: WindowActionEngine = WindowActionEngine(),
        registersShortcuts: Bool = true // false only for offscreen screenshot rendering
    ) {
        self.preferencesStore = preferencesStore
        self.permissionsHelper = permissionsHelper
        self.actionEngine = actionEngine

        let loadedPreferences = preferencesStore.load()
        preferences = loadedPreferences
        isAccessibilityGranted = permissionsHelper.isAccessibilityTrusted
        shortcutManager = registersShortcuts ? GlobalShortcutManager { [weak self] action in
            self?.perform(action)
        } : nil
        applyShortcuts()

        // Keep the Settings → Apps list current as apps launch and quit.
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.objectWillChange.send() }
            })
        }
    }

    private func applyShortcuts() {
        guard let shortcutManager else { return }
        if recordingAction == nil {
            unavailableShortcuts = shortcutManager.updateShortcuts(preferences.shortcuts)
        } else {
            shortcutManager.updateShortcuts([:])
        }
    }

    func perform(_ action: OrganizerAction) {
        refreshPermissions()

        let policy = ActionPolicy(preferences: preferences)
        if policy.requiresAccessibilityPermission(for: action),
           !permissionsHelper.isAccessibilityTrusted {
            grantAccessibility()
            statusMessage = "Accessibility permission is required for \(action.title)"
            return
        }

        if policy.requiresConfirmation(for: action),
           !confirmForceQuit() {
            statusMessage = "Force quit cancelled"
            return
        }

        let result = actionEngine.perform(action, preferences: preferences)
        statusMessage = result.statusMessage
    }

    func refreshPermissions() {
        isAccessibilityGranted = permissionsHelper.isAccessibilityTrusted
    }

    /// macOS shows its prompt only once per signature, so also open the pane for repeat clicks.
    func grantAccessibility() {
        permissionsHelper.requestAccessibilityPermissionPrompt()
        permissionsHelper.openAccessibilitySettings()
        refreshPermissions()
    }

    func openAccessibilitySettings() {
        permissionsHelper.openAccessibilitySettings()
        refreshPermissions()
    }

    func requestAccessibilityPermissionPrompt() {
        permissionsHelper.requestAccessibilityPermissionPrompt()
        refreshPermissions()
    }

    func runningApps() -> [RunningAppDescriptor] {
        NSWorkspace.shared.runningApplications.compactMap(RunningAppDescriptor.init(application:))
            .sorted { lhs, rhs in
                lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
            }
    }

    func targetResolver() -> TargetResolver {
        TargetResolver(
            preferences: preferences,
            currentBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.padina.window-organizer"
        )
    }

    func inclusionState(for bundleIdentifier: String) -> AppRuleState {
        if preferences.includedBundleIdentifiers.contains(bundleIdentifier) {
            return .included
        }
        if preferences.excludedBundleIdentifiers.contains(bundleIdentifier) {
            return .excluded
        }
        return .default
    }

    func setInclusionState(_ state: AppRuleState, for bundleIdentifier: String) {
        preferences.includedBundleIdentifiers.remove(bundleIdentifier)
        preferences.excludedBundleIdentifiers.remove(bundleIdentifier)

        switch state {
        case .default:
            break
        case .included:
            preferences.includedBundleIdentifiers.insert(bundleIdentifier)
        case .excluded:
            preferences.excludedBundleIdentifiers.insert(bundleIdentifier)
        }
    }

    private func confirmForceQuit() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Force quit apps?"
        alert.informativeText = "This immediately terminates targeted apps and can discard unsaved work."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Force Quit")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()  // inactive .accessory app, usually right after a global hotkey: show the alert in front
        return alert.runModal() == .alertFirstButtonReturn
    }
}

enum AppRuleState: String, CaseIterable, Identifiable {
    case `default`
    case included
    case excluded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "Default"
        case .included: "Include"
        case .excluded: "Exclude"
        }
    }
}

extension RunningAppDescriptor {
    init?(application: NSRunningApplication) {
        guard let bundleIdentifier = application.bundleIdentifier else {
            return nil
        }

        self.init(
            bundleIdentifier: bundleIdentifier,
            localizedName: application.localizedName ?? bundleIdentifier,
            processIdentifier: application.processIdentifier,
            activationPolicy: AppActivationPolicy(application.activationPolicy)
        )
    }
}

extension AppActivationPolicy {
    init(_ policy: NSApplication.ActivationPolicy) {
        switch policy {
        case .regular:
            self = .regular
        case .accessory:
            self = .accessory
        case .prohibited:
            self = .prohibited
        @unknown default:
            self = .prohibited
        }
    }
}
