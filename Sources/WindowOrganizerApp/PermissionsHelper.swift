import AppKit
import ApplicationServices
import Foundation
import os

protocol PermissionsHelping {
    var isAccessibilityTrusted: Bool { get }
    func openAccessibilitySettings()
    func requestAccessibilityPermissionPrompt()
}

struct PermissionsHelper: PermissionsHelping {
    var isAccessibilityTrusted: Bool {
        let trusted = AXIsProcessTrusted()
        Logger(subsystem: "com.padina.window-organizer", category: "permissions")
            .info("Accessibility trusted: \(trusted, privacy: .public), path: \(Bundle.main.bundlePath, privacy: .public)")
        return trusted
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
