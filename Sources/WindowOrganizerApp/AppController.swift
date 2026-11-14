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
    @Published private(set) var supportPromptShowing = false  // mirrored in the menu: the card never takes keyboard focus

    private let preferencesStore: PreferencesPersisting
    private let permissionsHelper: PermissionsHelping
    private let actionEngine: WindowActionEngine
    private var shortcutManager: GlobalShortcutManager?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var supportPromptTask: Task<Void, Never>?  // the pending ~3 s try after the last clean-up

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
        // A support card still unanswered when the next bulk action starts counts as "Ask me in 2 weeks".
        if supportPromptShowing { SupportPanel.respond(.snooze); SupportPanel.close() }
        supportPromptTask?.cancel()  // mid-action again: the wait restarts after this one
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
        countCleanUp(result)
    }

    // MARK: Ko-fi support card (UserDefaults; counting starts with the version that ships the card)

    static let supportInstallDateKey = "supportInstallDate"
    private static let bulkActionsKey = "supportBulkActions"
    private static let windowsTidiedKey = "supportWindowsTidied"
    private static let supportPromptKey = "supportPrompt"
    static var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    private var supportPrompt: SupportPromptState {
        get {
            UserDefaults.standard.data(forKey: Self.supportPromptKey)
                .flatMap { try? JSONDecoder().decode(SupportPromptState.self, from: $0) } ?? SupportPromptState()
        }
        set { UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: Self.supportPromptKey) }
    }

    /// The success moment: a bulk action that changed something. Counted, then (not after force quit) the card gets one try ~3 s later.
    private func countCleanUp(_ result: ActionResult) {
        guard result.affectedCount > 0 else { return }
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: Self.bulkActionsKey) + 1, forKey: Self.bulkActionsKey)
        if result.action == .minimizeAllWindows || result.action == .closeAllWindows {  // counts windows; quit counts apps
            defaults.set(defaults.integer(forKey: Self.windowsTidiedKey) + result.affectedCount, forKey: Self.windowsTidiedKey)
        }
        guard result.action != .forceQuitApps else { return }  // counted, but never ask right after a force quit
        supportPromptTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.maybeShowSupportPrompt()
        }
    }

    /// One try per clean-up; a guard that fails drops this chance, the next clean-up tries again.
    private func maybeShowSupportPrompt(now: Date = Date()) {
        // Not now: Welcome on screen, a dialog or shortcut recording in progress, nobody at the desk, or a call.
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
        guard !supportPromptShowing, !WelcomeWindow.isShowing, NSApp.modalWindow == nil, recordingAction == nil,
              idleSeconds <= 120, !SupportPanel.micInUse(),
              let installDate = UserDefaults.standard.object(forKey: Self.supportInstallDateKey) as? Date,
              supportPrompt.mayAsk(now: now, installDate: installDate,
                                   bulkActions: UserDefaults.standard.integer(forKey: Self.bulkActionsKey),
                                   appVersion: Self.appVersion)
        else { return }
        supportPrompt.recordShown(now)
        presentSupportPrompt()
    }

    /// `record: false` = the ⌥ menu preview: shows the real card but never touches the ask bookkeeping.
    func presentSupportPrompt(record: Bool = true) {
        guard !supportPromptShowing else { return }
        supportPromptShowing = true
        SupportPanel.show(bulkActions: UserDefaults.standard.integer(forKey: Self.bulkActionsKey),
                          windowsTidied: UserDefaults.standard.integer(forKey: Self.windowsTidiedKey),
                          onAnswer: { [weak self] answer in self?.answerSupportPrompt(answer, record: record) },
                          onClosed: { [weak self] in self?.supportPromptShowing = false })
    }

    private func answerSupportPrompt(_ answer: SupportPromptState.Answer, record: Bool) {
        if answer == .support { NSWorkspace.shared.open(WindowOrganizerApp.koFiURL) }
        guard record else { return }
        supportPrompt.record(answer, now: Date(), appVersion: Self.appVersion)
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
        // Forceful: hotkey or menu (user action); on macOS 14+ the front app can refuse activate() (alert behind).
        NSApp.activate(ignoringOtherApps: true)  // inactive .accessory app, usually right after a global hotkey: show the alert in front
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
