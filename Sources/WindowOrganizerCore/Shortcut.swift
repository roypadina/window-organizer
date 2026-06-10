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

public struct OrganizerShortcut: Codable, Equatable, Hashable, Sendable {
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

public extension OrganizerShortcut {
    static let letterKeyCodes: [String: UInt32] = [
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04, "G": 0x05, "Z": 0x06,
        "X": 0x07, "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E,
        "R": 0x0F, "Y": 0x10, "T": 0x11, "O": 0x1F, "U": 0x20, "I": 0x22, "P": 0x23,
        "L": 0x25, "J": 0x26, "K": 0x28, "N": 0x2D, "M": 0x2E
    ]

    var carbonKeyCode: UInt32? {
        Self.letterKeyCodes[normalizedKey]
    }
}
