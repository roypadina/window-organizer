import Foundation
import Testing
@testable import WindowOrganizerCore

@Suite("Window Organizer core behavior")
struct WindowOrganizerCoreTests {
    @Test("default preferences include all phase 1 actions")
    func defaultPreferencesIncludeActions() {
        let preferences = OrganizerPreferences.defaults

        #expect(Set(preferences.shortcuts.keys) == Set(OrganizerAction.allCases))
        #expect(preferences.scope == .currentVisibleContext)
        #expect(preferences.forceQuitRequiresConfirmation)
        #expect(preferences.launchAtLoginEnabled == false)
    }

    @Test("shortcut validation rejects missing key and modifiers")
    func shortcutValidation() {
        #expect(OrganizerShortcut(key: "", modifiers: [.command]).isValid == false)
        #expect(OrganizerShortcut(key: "M", modifiers: []).isValid == false)
        #expect(OrganizerShortcut(key: "M", modifiers: [.command, .option]).isValid)
        #expect(OrganizerShortcut(key: "m", modifiers: [.command]).displayString == "⌘M")
    }

    @Test("default exclusions skip system and protected apps")
    func defaultExclusionsSkipSystemApps() {
        let resolver = TargetResolver(
            preferences: .defaults,
            currentBundleIdentifier: "com.padina.window-organizer"
        )

        let apps = [
            RunningAppDescriptor(bundleIdentifier: "com.apple.finder", localizedName: "Finder", processIdentifier: 100, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.apple.systempreferences", localizedName: "System Settings", processIdentifier: 101, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.apple.dock", localizedName: "Dock", processIdentifier: 102, activationPolicy: .accessory),
            RunningAppDescriptor(bundleIdentifier: "com.apple.TextEdit", localizedName: "TextEdit", processIdentifier: 103, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.padina.window-organizer", localizedName: "Window Organizer", processIdentifier: 104, activationPolicy: .accessory)
        ]

        let targets = resolver.targets(from: apps).map(\.bundleIdentifier)

        #expect(targets == ["com.apple.TextEdit"])
    }

    @Test("explicit include can override a default exclusion")
    func explicitIncludeOverridesDefaultExclusion() {
        var preferences = OrganizerPreferences.defaults
        preferences.includedBundleIdentifiers = ["com.apple.finder"]
        let resolver = TargetResolver(
            preferences: preferences,
            currentBundleIdentifier: "com.padina.window-organizer"
        )

        let targets = resolver.targets(from: [
            RunningAppDescriptor(bundleIdentifier: "com.apple.finder", localizedName: "Finder", processIdentifier: 200, activationPolicy: .regular)
        ])

        #expect(targets.map(\.bundleIdentifier) == ["com.apple.finder"])
    }

    @Test("explicit exclude removes otherwise eligible apps")
    func explicitExcludeWinsForEligibleApps() {
        var preferences = OrganizerPreferences.defaults
        preferences.excludedBundleIdentifiers = ["com.apple.TextEdit"]
        let resolver = TargetResolver(
            preferences: preferences,
            currentBundleIdentifier: "com.padina.window-organizer"
        )

        let targets = resolver.targets(from: [
            RunningAppDescriptor(bundleIdentifier: "com.apple.TextEdit", localizedName: "TextEdit", processIdentifier: 300, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.apple.Safari", localizedName: "Safari", processIdentifier: 301, activationPolicy: .regular)
        ])

        #expect(targets.map(\.bundleIdentifier) == ["com.apple.Safari"])
    }

    @Test("force quit requires confirmation but normal actions do not")
    func actionPolicyConfirmation() {
        let policy = ActionPolicy(preferences: .defaults)

        #expect(policy.requiresConfirmation(for: .forceQuitApps))
        #expect(policy.requiresConfirmation(for: .quitApps) == false)
        #expect(policy.requiresConfirmation(for: .closeAllWindows) == false)
        #expect(policy.requiresConfirmation(for: .minimizeAllWindows) == false)
    }

    @Test("shortcuts saved before key codes still decode")
    func legacyShortcutJSONDecodes() throws {
        let json = #"{"key":"M","modifiers":["command","option","control"]}"#
        let shortcut = try JSONDecoder().decode(OrganizerShortcut.self, from: Data(json.utf8))
        #expect(shortcut.keyCode == 0x2E)
        #expect(shortcut.isValid)

        let digit = try JSONDecoder().decode(OrganizerShortcut.self, from: Data(#"{"key":"1","modifiers":["command"]}"#.utf8))
        #expect(digit.keyCode == nil)
        #expect(digit.isValid == false)
    }

    @Test("saved preferences round-trip and keep key codes")
    func preferencesRoundTrip() throws {
        var preferences = OrganizerPreferences.defaults
        preferences.shortcuts[.minimizeAllWindows] = OrganizerShortcut(key: "F5", modifiers: [], keyCode: 0x60)
        preferences.includedBundleIdentifiers = ["com.apple.finder"]
        let decoded = try JSONDecoder().decode(OrganizerPreferences.self, from: JSONEncoder().encode(preferences))
        #expect(decoded == preferences)
        #expect(decoded.shortcuts[.minimizeAllWindows]?.keyCode == 0x60)
    }

    @Test("shortcut validation allows lone function keys only")
    func shortcutValidationRules() {
        #expect(OrganizerShortcut(key: "F5", modifiers: [], keyCode: 0x60).isValid)
        #expect(OrganizerShortcut(key: "M", modifiers: [.shift]).isValid == false)
        #expect(OrganizerShortcut(key: "M", modifiers: [.command]).isValid)
        #expect(OrganizerShortcut(key: "←", modifiers: [.option], keyCode: 0x7B).isValid)
        #expect(OrganizerShortcut(key: "←", modifiers: [.option, .command], keyCode: 0x7B).displayString == "⌥⌘←")
        #expect(OrganizerShortcut.specialKeyLabels[0x31] == "Space")
        #expect(OrganizerShortcut.functionKeyLabels.count == 20)
        #expect(OrganizerPreferences.defaults.shortcuts.values.allSatisfy { $0.keyCode != nil })
    }

    @Test("conflicting shortcuts are detected between actions")
    func shortcutConflicts() {
        let preferences = OrganizerPreferences.defaults
        let quit = OrganizerShortcut(key: "Q", modifiers: [.command, .option, .control])
        #expect(preferences.conflictingAction(for: quit, excluding: .forceQuitApps) == .quitApps)
        #expect(preferences.conflictingAction(for: quit, excluding: .quitApps) == nil)
        #expect(preferences.conflictingAction(for: OrganizerShortcut(key: "Q", modifiers: [.command]), excluding: .forceQuitApps) == nil)
    }

    @Test("app list filter combines search, status, developer and kind")
    func appListFilter() {
        var preferences = OrganizerPreferences.defaults
        preferences.excludedBundleIdentifiers = ["com.tinyspeck.slackmacgap"]
        let resolver = TargetResolver(preferences: preferences, currentBundleIdentifier: "com.padina.window-organizer")
        let apps = [
            RunningAppDescriptor(bundleIdentifier: "com.apple.Safari", localizedName: "Safari", processIdentifier: 1, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.apple.finder", localizedName: "Finder", processIdentifier: 2, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.tinyspeck.slackmacgap", localizedName: "Slack", processIdentifier: 3, activationPolicy: .regular),
            RunningAppDescriptor(bundleIdentifier: "com.example.menu", localizedName: "Menu Thing", processIdentifier: 4, activationPolicy: .accessory),
            RunningAppDescriptor(bundleIdentifier: "com.apple.agent", localizedName: "Agent", processIdentifier: 5, activationPolicy: .prohibited)
        ]
        func names(_ configure: (inout AppListFilter) -> Void) -> [String] {
            var filter = AppListFilter()
            configure(&filter)
            return filter.apply(to: apps, resolver: resolver).map(\.localizedName)
        }

        #expect(names { _ in } == ["Safari", "Finder", "Slack", "Menu Thing"])
        #expect(names { $0.kind = .all }.count == 5)
        #expect(names { $0.kind = .background } == ["Agent"])
        #expect(names { $0.kind = .menuBar } == ["Menu Thing"])
        #expect(names { $0.status = .targeted } == ["Safari"])
        #expect(names { $0.status = .skipped } == ["Finder", "Slack", "Menu Thing"])
        #expect(names { $0.status = .hasRule } == ["Slack"])
        #expect(names { $0.source = .apple } == ["Safari", "Finder"])
        #expect(names { $0.source = .thirdParty } == ["Slack", "Menu Thing"])
        #expect(names { $0.query = "SLACK" } == ["Slack"])
        #expect(names { $0.query = "tinyspeck" } == ["Slack"])
        #expect(names { $0.query = "  " }.count == 4)
    }
}
