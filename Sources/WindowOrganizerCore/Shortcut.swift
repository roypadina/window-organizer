import Foundation

public enum ShortcutModifier: String, CaseIterable, Codable, Sendable, Comparable {
    case command
    case option
    case control
    case shift

    public static func < (lhs: ShortcutModifier, rhs: ShortcutModifier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public var symbol: String {
        switch self {
        case .command: "⌘"
        case .option: "⌥"
        case .control: "⌃"
        case .shift: "⇧"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .control: 0
        case .option: 1
        case .shift: 2
        case .command: 3
        }
    }
}

public struct KeyboardShortcut: Codable, Equatable, Hashable, Sendable {
    public var key: String
    public var modifiers: Set<ShortcutModifier>

    public init(key: String, modifiers: Set<ShortcutModifier>) {
        self.key = key
        self.modifiers = modifiers
    }

    public var normalizedKey: String {
        key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    public var isValid: Bool {
        !normalizedKey.isEmpty && !modifiers.isEmpty
    }

    public var displayString: String {
        let modifierText = modifiers.sorted().map(\.symbol).joined()
        return modifierText + normalizedKey
    }
}
