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
    /// Display label: "M", "5", "F5", "←", "Space".
    public var key: String
    /// Virtual key code (Carbon / NSEvent). Nil only for legacy values that can't be resolved.
    public var keyCode: UInt16?
    public var modifiers: Set<ShortcutModifier>

    public init(key: String, modifiers: Set<ShortcutModifier>, keyCode: UInt16? = nil) {
        self.key = key
        self.modifiers = modifiers
        let letter = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.keyCode = keyCode ?? Self.letterKeyCodes[letter].map { UInt16($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case key, keyCode, modifiers
    }

    /// Preferences saved before key codes existed have no `keyCode`; the init derives it for letters.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            key: try container.decode(String.self, forKey: .key),
            modifiers: try container.decode(Set<ShortcutModifier>.self, forKey: .modifiers),
            keyCode: try container.decodeIfPresent(UInt16.self, forKey: .keyCode)
        )
    }

    public var normalizedKey: String {
        key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    public var isFunctionKey: Bool {
        keyCode.map { Self.functionKeyLabels[$0] != nil } ?? false
    }

    /// Function keys may stand alone; anything else needs ⌘, ⌃ or ⌥ (⇧ alone would hijack typing).
    public var isValid: Bool {
        keyCode != nil && (isFunctionKey || !modifiers.isDisjoint(with: [.command, .control, .option]))
    }

    public var displayString: String {
        let modifierText = modifiers.sorted().map(\.symbol).joined()
        return modifierText + normalizedKey
    }
}

public extension OrganizerShortcut {
    /// Letter key codes, used to migrate shortcuts saved before `keyCode` existed.
    static let letterKeyCodes: [String: UInt32] = [
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04, "G": 0x05, "Z": 0x06,
        "X": 0x07, "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E,
        "R": 0x0F, "Y": 0x10, "T": 0x11, "O": 0x1F, "U": 0x20, "I": 0x22, "P": 0x23,
        "L": 0x25, "J": 0x26, "K": 0x28, "N": 0x2D, "M": 0x2E
    ]

    static let functionKeyLabels: [UInt16: String] = [
        0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5", 0x61: "F6", 0x62: "F7",
        0x64: "F8", 0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12", 0x69: "F13", 0x6B: "F14",
        0x71: "F15", 0x6A: "F16", 0x40: "F17", 0x4F: "F18", 0x50: "F19", 0x5A: "F20"
    ]

    /// Labels for keys whose character is invisible or ambiguous.
    static let specialKeyLabels: [UInt16: String] = functionKeyLabels.merging([
        0x24: "↩", 0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x75: "⌦", 0x35: "⎋",
        0x73: "↖", 0x77: "↘", 0x74: "⇞", 0x79: "⇟", 0x72: "Help",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
        0x4C: "⌤", 0x47: "⌧", 0x41: "Num .", 0x43: "Num *", 0x45: "Num +", 0x4B: "Num /",
        0x4E: "Num -", 0x51: "Num =", 0x52: "Num 0", 0x53: "Num 1", 0x54: "Num 2", 0x55: "Num 3",
        0x56: "Num 4", 0x57: "Num 5", 0x58: "Num 6", 0x59: "Num 7", 0x5B: "Num 8", 0x5C: "Num 9"
    ]) { existing, _ in existing }

    var carbonKeyCode: UInt32? {
        keyCode.map(UInt32.init)
    }
}

public extension OrganizerPreferences {
    /// The other action already using this exact key + modifiers, if any.
    func conflictingAction(for shortcut: OrganizerShortcut, excluding action: OrganizerAction) -> OrganizerAction? {
        shortcuts.first { other, existing in
            other != action && existing.keyCode == shortcut.keyCode && existing.modifiers == shortcut.modifiers
        }?.key
    }
}
