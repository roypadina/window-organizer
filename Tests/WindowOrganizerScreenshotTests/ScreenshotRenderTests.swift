import AppKit
import SwiftUI
import WindowOrganizerCore
import XCTest
@testable import WindowOrganizerApp

private final class MemoryStore: PreferencesPersisting {
    var value = OrganizerPreferences.defaults
    func load() -> OrganizerPreferences { value }
    func save(_ preferences: OrganizerPreferences) { value = preferences }
}

private struct FakePermissions: PermissionsHelping {
    var isAccessibilityTrusted: Bool { true }
    func openAccessibilitySettings() {}
    func requestAccessibilityPermissionPrompt() {}
}

private struct FakeLoginItem: LoginItemManaging {
    func setEnabled(_ enabled: Bool) throws {}
}

/// Dev-only: renders README screenshots offscreen. Skipped unless RENDER_SCREENSHOTS=<output dir>.
/// Usage: RENDER_SCREENSHOTS=$PWD/docs/screenshots swift test --filter ScreenshotRenderTests
@MainActor
final class ScreenshotRenderTests: XCTestCase {
    private func render<V: View>(_ view: V, name: String, dir: String) throws {
        let host = NSHostingView(rootView: view.environment(\.controlActiveState, .key))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        let win = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        win.appearance = NSAppearance(named: .aqua)
        win.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        // 2x, with the tab strip cropped off (its selected label does not render offscreen).
        let scale = 2
        let rep = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale, pixelsHigh: Int(size.height) * scale,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        let strip = 46 * scale
        let cg = try XCTUnwrap(rep.cgImage)
        let crop = try XCTUnwrap(cg.cropping(to: CGRect(x: 0, y: strip, width: cg.width, height: cg.height - strip)))
        let png = try XCTUnwrap(NSBitmapImageRep(cgImage: crop).representation(using: .png, properties: [:]))
        try png.write(to: URL(fileURLWithPath: dir).appendingPathComponent(name))
    }

    func test_renderScreenshots() throws {
        guard let dir = ProcessInfo.processInfo.environment["RENDER_SCREENSHOTS"] else {
            throw XCTSkip("set RENDER_SCREENSHOTS=<dir> to render")
        }
        let controller = AppController(
            preferencesStore: MemoryStore(),
            permissionsHelper: FakePermissions(),
            loginItemManager: FakeLoginItem(),
            registersShortcuts: false
        )
        for (tab, name) in [(SettingsView.Tab.shortcuts, "settings-shortcuts.png")] {
            try render(SettingsView(controller: controller, tab: tab), name: name, dir: dir)
        }
    }
}
