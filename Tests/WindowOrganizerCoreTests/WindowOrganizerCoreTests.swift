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

    @Test("settings window uses compact top aligned layout")
    func settingsWindowLayoutIsCompact() {
        #expect(SettingsLayoutMetrics.windowMinimumHeight <= 340)
        #expect(SettingsLayoutMetrics.headerPadding == 12)
        #expect(SettingsLayoutMetrics.contentPadding == 16)
    }
}
