import Foundation

public struct ActionPolicy: Sendable {
    public var preferences: OrganizerPreferences

    public init(preferences: OrganizerPreferences) {
        self.preferences = preferences
    }

    public func requiresConfirmation(for action: OrganizerAction) -> Bool {
        action == .forceQuitApps && preferences.forceQuitRequiresConfirmation
    }

    public func requiresAccessibilityPermission(for action: OrganizerAction) -> Bool {
        switch action {
        case .minimizeAllWindows, .closeAllWindows:
            true
        case .quitApps, .forceQuitApps:
            false
        }
    }
}
