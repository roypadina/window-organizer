import Foundation

public struct TargetResolver: Sendable {
    public var preferences: OrganizerPreferences
    public var currentBundleIdentifier: String

    public init(preferences: OrganizerPreferences, currentBundleIdentifier: String) {
        self.preferences = preferences
        self.currentBundleIdentifier = currentBundleIdentifier
    }

    public func targets(from apps: [RunningAppDescriptor]) -> [RunningAppDescriptor] {
        apps
            .filter { isEligible($0) }
            .sorted { lhs, rhs in
                lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
            }
    }

    public func isEligible(_ app: RunningAppDescriptor) -> Bool {
        let bundleIdentifier = app.bundleIdentifier

        if preferences.excludedBundleIdentifiers.contains(bundleIdentifier) {
            return false
        }

        if preferences.includedBundleIdentifiers.contains(bundleIdentifier) {
            return true
        }

        if bundleIdentifier == currentBundleIdentifier {
            return false
        }

        guard app.activationPolicy == .regular else {
            return false
        }

        return !DefaultExclusions.bundleIdentifiers.contains(bundleIdentifier)
    }
}
