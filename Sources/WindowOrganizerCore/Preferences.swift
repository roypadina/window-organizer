import Foundation

public struct OrganizerPreferences: Codable, Equatable, Sendable {
    public var shortcuts: [OrganizerAction: KeyboardShortcut]
    public var scope: ActionScope
    public var launchAtLoginEnabled: Bool
    public var forceQuitRequiresConfirmation: Bool
    public var includedBundleIdentifiers: Set<String>
    public var excludedBundleIdentifiers: Set<String>

    public init(
        shortcuts: [OrganizerAction: KeyboardShortcut],
        scope: ActionScope,
        launchAtLoginEnabled: Bool,
        forceQuitRequiresConfirmation: Bool,
        includedBundleIdentifiers: Set<String>,
        excludedBundleIdentifiers: Set<String>
    ) {
        self.shortcuts = shortcuts
        self.scope = scope
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.forceQuitRequiresConfirmation = forceQuitRequiresConfirmation
        self.includedBundleIdentifiers = includedBundleIdentifiers
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
    }

    public static let defaults = OrganizerPreferences(
        shortcuts: [
            .minimizeAllWindows: KeyboardShortcut(key: "M", modifiers: [.command, .option, .control]),
            .closeAllWindows: KeyboardShortcut(key: "W", modifiers: [.command, .option, .control]),
            .quitApps: KeyboardShortcut(key: "Q", modifiers: [.command, .option, .control]),
            .forceQuitApps: KeyboardShortcut(key: "Q", modifiers: [.command, .option, .control, .shift])
        ],
        scope: .currentVisibleContext,
        launchAtLoginEnabled: false,
        forceQuitRequiresConfirmation: true,
        includedBundleIdentifiers: [],
        excludedBundleIdentifiers: []
    )
}

public protocol PreferencesPersisting {
    func load() -> OrganizerPreferences
    func save(_ preferences: OrganizerPreferences)
}

public final class UserDefaultsPreferencesStore: PreferencesPersisting {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "OrganizerPreferences") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> OrganizerPreferences {
        guard let data = defaults.data(forKey: key),
              let preferences = try? JSONDecoder().decode(OrganizerPreferences.self, from: data) else {
            return .defaults
        }
        return preferences
    }

    public func save(_ preferences: OrganizerPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}
