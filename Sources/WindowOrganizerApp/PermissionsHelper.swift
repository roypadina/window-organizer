import AppKit
import ApplicationServices
import Foundation

protocol PermissionsHelping {
    var isAccessibilityTrusted: Bool { get }
    func openAccessibilitySettings()
    func requestAccessibilityPermissionPrompt()
}

struct PermissionsHelper: PermissionsHelping {
    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func requestAccessibilityPermissionPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
