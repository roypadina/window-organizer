import AppKit
import ApplicationServices
import Foundation
import WindowOrganizerCore

@MainActor
final class WindowActionEngine {
    private let currentBundleIdentifier: String

    init(currentBundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.padina.window-organizer") {
        self.currentBundleIdentifier = currentBundleIdentifier
    }

    func perform(_ action: OrganizerAction, preferences: OrganizerPreferences) -> ActionResult {
        let apps = targetApplications(preferences: preferences)

        switch action {
        case .minimizeAllWindows:
            let count = apps.reduce(0) { partial, app in
                partial + setWindowsMinimized(true, for: app, scope: preferences.scope)
            }
            return ActionResult(action: action, affectedCount: count)

        case .closeAllWindows:
            let count = apps.reduce(0) { partial, app in
                partial + closeWindows(for: app, scope: preferences.scope)
            }
            return ActionResult(action: action, affectedCount: count)

        case .quitApps:
            var count = 0
            for app in apps where app.terminate() {
                count += 1
            }
            return ActionResult(action: action, affectedCount: count)

        case .forceQuitApps:
            var count = 0
            for app in apps where app.forceTerminate() {
                count += 1
            }
            return ActionResult(action: action, affectedCount: count)
        }
    }

    private func targetApplications(preferences: OrganizerPreferences) -> [NSRunningApplication] {
        let applications = NSWorkspace.shared.runningApplications
        let descriptors = applications.compactMap(RunningAppDescriptor.init(application:))
        let resolver = TargetResolver(preferences: preferences, currentBundleIdentifier: currentBundleIdentifier)
        let targetPIDs = Set(resolver.targets(from: descriptors).map(\.processIdentifier))
        return applications.filter { targetPIDs.contains($0.processIdentifier) }
    }

    private func setWindowsMinimized(_ minimized: Bool, for app: NSRunningApplication, scope: ActionScope) -> Int {
        windows(for: app, scope: scope).reduce(0) { count, window in
            let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, minimized as CFBoolean)
            return result == .success ? count + 1 : count
        }
    }

    private func closeWindows(for app: NSRunningApplication, scope: ActionScope) -> Int {
        windows(for: app, scope: scope).reduce(0) { count, window in
            var closeButtonValue: CFTypeRef?
            let copyResult = AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &closeButtonValue)
            guard copyResult == .success, let closeButtonValue else {
                return count
            }

            let closeButton = closeButtonValue as! AXUIElement
            let pressResult = AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
            return pressResult == .success ? count + 1 : count
        }
    }

    private func windows(for app: NSRunningApplication, scope: ActionScope) -> [AXUIElement] {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windowsValue)
        guard result == .success, let windows = windowsValue as? [AXUIElement] else {
            return []
        }

        switch scope {
        case .currentVisibleContext:
            return windows.filter(isWindowVisible)
        case .allSpacesAndDisplays:
            return windows
        }
    }

    private func isWindowVisible(_ window: AXUIElement) -> Bool {
        var minimizedValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue) == .success,
           let minimized = minimizedValue as? Bool,
           minimized {
            return false
        }

        guard let frame = frame(for: window) else {
            return true
        }

        return NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
    }

    private func frame(for window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue,
              let sizeValue else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: point, size: size)
    }
}

struct ActionResult {
    var action: OrganizerAction
    var affectedCount: Int

    var statusMessage: String {
        "\(action.title): \(affectedCount) target\(affectedCount == 1 ? "" : "s") affected"
    }
}
