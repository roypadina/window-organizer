import Foundation

public enum OrganizerAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case minimizeAllWindows
    case closeAllWindows
    case quitApps
    case forceQuitApps

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .minimizeAllWindows: "Minimize All Windows"
        case .closeAllWindows: "Close All Windows"
        case .quitApps: "Quit Apps"
        case .forceQuitApps: "Force Quit Apps"
        }
    }
}

public enum ActionScope: String, CaseIterable, Codable, Sendable, Identifiable {
    case currentVisibleContext
    case allSpacesAndDisplays

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .currentVisibleContext: "Current visible context"
        case .allSpacesAndDisplays: "All Spaces and displays"
        }
    }
}

public enum AppActivationPolicy: String, Codable, Sendable {
    case regular
    case accessory
    case prohibited
}

public struct RunningAppDescriptor: Codable, Equatable, Hashable, Sendable, Identifiable {
    public var id: Int32 { processIdentifier }
    public var bundleIdentifier: String
    public var localizedName: String
    public var processIdentifier: Int32
    public var activationPolicy: AppActivationPolicy

    public init(
        bundleIdentifier: String,
        localizedName: String,
        processIdentifier: Int32,
        activationPolicy: AppActivationPolicy
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.processIdentifier = processIdentifier
        self.activationPolicy = activationPolicy
    }
}

public enum DefaultExclusions {
    public static let bundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systempreferences",
        "com.apple.systemsettings",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.WindowManager",
        "com.apple.loginwindow",
        "com.apple.SystemUIServer"
    ]
}
