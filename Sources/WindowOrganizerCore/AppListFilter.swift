import Foundation

/// Which running apps the Settings → Apps list shows. Filters combine (AND).
public struct AppListFilter: Equatable, Sendable {
    public enum Status: String, CaseIterable, Identifiable, Sendable {
        case all, targeted, skipped, hasRule

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .all: "Any status"
            case .targeted: "Targeted"
            case .skipped: "Skipped"
            case .hasRule: "Has a rule"
            }
        }
    }

    public enum Source: String, CaseIterable, Identifiable, Sendable {
        case all, apple, thirdParty

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .all: "Any developer"
            case .apple: "Apple"
            case .thirdParty: "Third-party"
            }
        }
    }

    public enum Kind: String, CaseIterable, Identifiable, Sendable {
        case dockAndMenuBar, dock, menuBar, background, all

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .dockAndMenuBar: "Dock & menu bar apps"
            case .dock: "Dock apps"
            case .menuBar: "Menu bar apps"
            case .background: "Background processes"
            case .all: "All processes"
            }
        }

        func matches(_ policy: AppActivationPolicy) -> Bool {
            switch self {
            case .dockAndMenuBar: policy != .prohibited
            case .dock: policy == .regular
            case .menuBar: policy == .accessory
            case .background: policy == .prohibited
            case .all: true
            }
        }
    }

    public var query = ""
    public var status = Status.all
    public var source = Source.all
    public var kind = Kind.dockAndMenuBar

    public init() {}

    public static func isApple(_ bundleIdentifier: String) -> Bool {
        bundleIdentifier.hasPrefix("com.apple.")
    }

    public func apply(to apps: [RunningAppDescriptor], resolver: TargetResolver) -> [RunningAppDescriptor] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        let rules = resolver.preferences.includedBundleIdentifiers.union(resolver.preferences.excludedBundleIdentifiers)

        return apps.filter { app in
            guard kind.matches(app.activationPolicy) else { return false }

            switch source {
            case .all: break
            case .apple: guard Self.isApple(app.bundleIdentifier) else { return false }
            case .thirdParty: guard !Self.isApple(app.bundleIdentifier) else { return false }
            }

            switch status {
            case .all: break
            case .targeted: guard resolver.isEligible(app) else { return false }
            case .skipped: guard !resolver.isEligible(app) else { return false }
            case .hasRule: guard rules.contains(app.bundleIdentifier) else { return false }
            }

            return needle.isEmpty
                || app.localizedName.localizedCaseInsensitiveContains(needle)
                || app.bundleIdentifier.localizedCaseInsensitiveContains(needle)
        }
    }
}
