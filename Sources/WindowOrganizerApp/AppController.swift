import AppKit
import Combine
import Foundation
import WindowOrganizerCore

@MainActor
final class AppController: ObservableObject {
    @Published var preferences: OrganizerPreferences {
        didSet {
            preferencesStore.save(preferences)
            shortcutManager?.updateShortcuts(preferences.shortcuts)
            setLaunchAtLogin(preferences.launchAtLoginEnabled)
        }
    }

    @Published private(set) var permissionStatus: String
    @Published var statusMessage: String = "Ready"

    private let preferencesStore: PreferencesPersisting
    private let permissionsHelper: PermissionsHelping
    private let loginItemManager: LoginItemManaging
    private let actionEngine: WindowActionEngine
    private var shortcutManager: GlobalShortcutManager?

    init(
        preferencesStore: PreferencesPersisting = UserDefaultsPreferencesStore(),
        permissionsHelper: PermissionsHelping = PermissionsHelper(),
        loginItemManager: LoginItemManaging = LoginItemManager(),
        actionEngine: WindowActionEngine = WindowActionEngine()
    ) {
        self.preferencesStore = preferencesStore
        self.permissionsHelper = permissionsHelper
        self.loginItemManager = loginItemManager
        self.actionEngine = actionEngine

        let loadedPreferences = preferencesStore.load()
        preferences = loadedPreferences
        permissionStatus = permissionsHelper.isAccessibilityTrusted ? "Granted" : "Missing"
        shortcutManager = GlobalShortcutManager { [weak self] action in
            self?.perform(action)
        }
        shortcutManager?.updateShortcuts(loadedPreferences.shortcuts)
    }

    func perform(_ action: OrganizerAction) {
        refreshPermissions()

        let policy = ActionPolicy(preferences: preferences)
        if policy.requiresAccessibilityPermission(for: action),
           !permissionsHelper.isAccessibilityTrusted {
            permissionsHelper.requestAccessibilityPermissionPrompt()
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
        permissionStatus = permissionsHelper.isAccessibilityTrusted ? "Granted" : "Missing"
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

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
        } catch {
            statusMessage = "Launch at Login could not be updated: \(error.localizedDescription)"
        }
    }

    private func confirmForceQuit() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Force quit apps?"
        alert.informativeText = "This immediately terminates targeted apps and can discard unsaved work."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Force Quit")
        alert.addButton(withTitle: "Cancel")
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
