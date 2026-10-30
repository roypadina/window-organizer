// Window Organizer demo: five fake app windows are cleared with the app's menu and its shortcut. Action titles and the default
// shortcut come from the real Core files (Models.swift, Shortcut.swift, Preferences.swift, compiled unchanged); the remaining menu rows
// are copied verbatim from MenuContent in WindowOrganizerApp.swift. The window contents are made-up generic apps (no brands).
import AppKit
import ImageIO
import SwiftUI

private let W = Demo.size.width, H = Demo.size.height
private let prefs = OrganizerPreferences.defaults
private let shortcut = prefs.shortcuts[.minimizeAllWindows]!.displayString  // "⌃⌥⌘M": what the menu shows (WindowOrganizerApp.swift:78)

// MARK: - the app's menu (WindowOrganizerApp.swift MenuContent), Accessibility already granted so no "Grant Accessibility Access…" row (:36)

private func actionRow(_ a: OrganizerAction) -> MenuMock.Row { .item(a.title, key: prefs.shortcuts[a]?.displayString) }
private let menuRows: [MenuMock.Row] = [
    actionRow(.minimizeAllWindows),                   // :44 title = OrganizerAction.title, key = the recorded shortcut (:78)
    actionRow(.closeAllWindows),                      // :45
    actionRow(.quitApps),                             // :46
    .separator,                                       // :48
    .item("Force Quit Apps…"),                        // :50 no shortcut
    .separator,                                       // :54
    .item("Settings…", key: "⌘,"),                    // :56
    .separator,                                       // :58
    .item("About Window Organizer"),                  // :60
    .item("Support on Ko-fi ☕"),                     // :64
    .item("Quit Window Organizer", key: "⌘Q"),       // :68, :71
]

// MARK: - status item: the app's real template glyph (Assets/icons/menubar@2x.png), tinted like a menu bar template image

private let statusSpacer: String = {  // reserves the glyph's width in the kit's status item; the glyph is drawn over it
    var s = ""
    while (s as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 13)]).width < 18 { s += " " }
    return s
}()
private let statusItem = StatusItem(text: statusSpacer)

private let glyph: CGImage = {
    let url = URL(fileURLWithPath: ProcessInfo.processInfo.environment["WO_ICONS"]! + "/menubar@2x.png")
    let img = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
    let ctx = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let r = CGRect(x: 0, y: 0, width: img.width, height: img.height)
    ctx.draw(img, in: r); ctx.setBlendMode(.sourceIn); ctx.setFillColor(CGColor(gray: 1, alpha: 0.95)); ctx.fill(r)
    return ctx.makeImage()!
}()

// MARK: - fake app windows (generic made-up content)

private let paper = Color(white: 0.17)

private struct NotesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Launch checklist").font(.system(size: 18, weight: .bold))
            ForEach(Array(["Review the final copy", "Send the draft to the team", "Book the room for Friday", "Update the release notes", "Pack the demo laptop"].enumerated()), id: \.offset) { i, t in
                HStack(spacing: 8) {
                    Image(systemName: i < 2 ? "checkmark.circle.fill" : "circle").foregroundStyle(i < 2 ? Color.green : .secondary)
                    Text(t)
                }.font(.system(size: 13))
            }
        }.padding(18).frame(width: 330, height: 200, alignment: .topLeading).background(paper)
    }
}

private struct BudgetView: View {
    private let rows = [("Design", "12.4k", "13.1k", "14.8k"), ("Travel", "6.2k", "4.9k", "7.5k"), ("Tools", "3.8k", "3.8k", "4.1k"),
                        ("Events", "9.0k", "11.2k", "8.4k"), ("Total", "31.4k", "33.0k", "34.8k")]
    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: 20, verticalSpacing: 8) {
            GridRow { Text("Item").gridColumnAlignment(.leading); Text("Q1"); Text("Q2"); Text("Q3") }.foregroundStyle(.secondary)
            Divider().gridCellUnsizedAxes(.horizontal)
            ForEach(rows, id: \.0) { r in GridRow { Text(r.0).gridColumnAlignment(.leading); Text(r.1); Text(r.2); Text(r.3) } }
        }.font(.system(size: 13).monospacedDigit()).padding(18).frame(width: 340, height: 190, alignment: .topLeading).background(paper)
    }
}

private struct InboxView: View {
    private let rows: [(Color, String, String)] = [(.orange, "Design team", "Updated mockups are ready"), (.blue, "Billing", "Your receipt for October"),
                                                   (.pink, "Travel desk", "Itinerary for the offsite"), (.teal, "Weekly digest", "Five things that changed")]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(rows, id: \.1) { r in
                HStack(spacing: 10) {
                    Circle().fill(r.0.gradient).frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(r.1).font(.system(size: 13, weight: .semibold))
                        Text(r.2).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
        }.padding(18).frame(width: 300, height: 210, alignment: .topLeading).background(paper)
    }
}

private struct MockupsView: View {
    private let tiles: [[Color]] = [[.purple, .pink], [.blue, .teal], [.orange, .yellow], [.green, .mint], [.indigo, .blue], [.red, .orange]]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(0..<tiles.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: tiles[i], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 76)
            }
        }.padding(14).frame(width: 330, height: 200, alignment: .topLeading).background(paper)
    }
}

private struct ConsoleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("$ build --release").foregroundStyle(.green)
            Text("Compiling 42 files…")
            Text("Linking…")
            Text("Done in 3.2 s").foregroundStyle(.secondary)
            Text("$ ").foregroundStyle(.green)
        }.font(.system(size: 12, design: .monospaced)).padding(14).frame(width: 340, height: 190, alignment: .topLeading).background(Color(white: 0.07))
    }
}

private struct Win { let layer: CGImage }

/// A window drawn alone (real title bar, kit shadow) on a transparent full-canvas layer, so it can be scaled toward the Dock as one piece.
@MainActor private func win<V: View>(_ v: V, _ size: CGSize, _ title: String, at o: CGPoint, active: Bool) -> Win {
    let c = Canvas(background: nil)
    c.window(captureWindow(v, size: size, title: title, active: active)!, at: o, radius: 16)
    return Win(layer: c.image)
}

// MARK: - timeline (seconds from the start; every scene draws from this one clock, so scene crossfades blend identical frames)

private let tOpen = 3.0, tClick = 5.95   // menu opens / Minimize All clicked (scenes 1-3); scene 4 has its own clock below
private let tKey = 1.3                    // scene 4, seconds into the scene: the shortcut is pressed
private let nWin = 5

/// 0 = full size on the desk, 1 = minimized away, `t0` = when the minimize starts. Front window goes first.
private func away(_ i: Int, _ t: Double, since t0: Double) -> Double {
    let s = t0 + Double(nWin - 1 - i) * 0.07
    return ease(ramp(t, s, s + 0.5))
}

/// The shortcut as the user sees it: one keycap per glyph of the real display string (⌃ ⌥ ⌘ M), up or pressed.
private struct KeysView: View {
    let down: Bool
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(shortcut.enumerated()), id: \.offset) { _, k in
                Text(String(k)).font(.system(size: 26, weight: .medium, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(down ? 0.40 : 0.14)))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(down ? 0.55 : 0.28), lineWidth: 1))
                    .scaleEffect(down ? 0.94 : 1)
            }
        }.padding(14)
    }
}

@MainActor func windowOrganizerScenes() -> [Scene] {
    let wins = [
        win(NotesView(), CGSize(width: 330, height: 200), "Meeting notes", at: CGPoint(x: 26, y: 50), active: false),
        win(BudgetView(), CGSize(width: 340, height: 190), "Budget", at: CGPoint(x: 290, y: 66), active: false),
        win(InboxView(), CGSize(width: 300, height: 210), "Inbox", at: CGPoint(x: 78, y: 236), active: false),
        win(MockupsView(), CGSize(width: 330, height: 200), "Mockups", at: CGPoint(x: 326, y: 196), active: false),
        win(ConsoleView(), CGSize(width: 340, height: 190), "Console", at: CGPoint(x: 566, y: 292), active: true),
    ]
    let item = Canvas(background: nil).menuBar(app: statusItem)
    let menu = Canvas.menuFrame(menuRows, under: item)
    let rowFrames = MenuMock.frames(menuRows).map { $0.offsetBy(dx: menu.minX, dy: menu.minY) }
    func rowCenter(_ i: Int) -> CGPoint { CGPoint(x: menu.minX + 160, y: rowFrames[i].midY) }
    let bar = CGPoint(x: item.midX, y: Demo.barHeight / 2)

    // hover tour of the four actions, then back to Minimize All Windows and click it
    let path = CursorPath(start: CGPoint(x: W * 0.62, y: H * 0.60),
                          moves: [.init(t0: 2.30, t1: 2.90, to: bar),
                                  .init(t0: 3.45, t1: 3.80, to: rowCenter(0)),
                                  .init(t0: 4.10, t1: 4.35, to: rowCenter(1)),
                                  .init(t0: 4.55, t1: 4.80, to: rowCenter(2)),
                                  .init(t0: 5.00, t1: 5.30, to: rowCenter(4)),
                                  .init(t0: 5.50, t1: 5.85, to: rowCenter(0))],
                          clicks: [tOpen, tClick])

    /// Wallpaper, the windows (minimizing from `t0` on) and the menu bar with the app's glyph.
    func base(_ t: Double, since t0: Double, open: Bool) -> Canvas {
        let c = Canvas()
        for (i, w) in wins.enumerated() {
            let p = away(i, t, since: t0), s = CGFloat(1 - 0.93 * p), alpha = CGFloat(1 - ramp(p, 0.55, 1))
            guard alpha > 0 else { continue }
            let anchor = CGPoint(x: W / 2 + CGFloat(i - 2) * 30, y: H + 10)   // toward the bottom, where the Dock is
            c.draw(w.layer, in: CGRect(x: anchor.x * (1 - s), y: anchor.y * (1 - s), width: W * s, height: H * s), alpha: alpha)
        }
        c.menuBar(app: statusItem, appActive: open)
        c.draw(glyph, in: CGRect(x: item.midX - 9, y: (Demo.barHeight - 18) / 2, width: 18, height: 18))
        return c
    }

    func desk(_ g: Double) -> CGImage {
        let open = g >= tOpen && g < tClick + 0.12
        let c = base(g, since: tClick, open: open)
        if open { c.menu(menuRows, under: item, hover: path.position(g), alpha: CGFloat(min(ramp(g, tOpen, tOpen + 0.12), 1 - ramp(g, tClick, tClick + 0.12)))) }
        let click = path.click(g)
        c.cursor(at: path.position(g), alpha: CGFloat(ramp(g, 2.2, 2.4) * (1 - ramp(g, tClick + 0.1, tClick + 0.25))), press: click.press, pulse: click.pulse)
        return c.image
    }

    // scene 4: a fresh cluttered desk, no cursor, no menu. The keycaps appear, are pressed at tKey, and the windows minimize like in scene 3.
    let keysUp = renderView(KeysView(down: false))!, keysDown = renderView(KeysView(down: true))!
    let keysSize = CGSize(width: CGFloat(keysUp.width) / Demo.scale, height: CGFloat(keysUp.height) / Demo.scale)
    func shortcutDesk(_ l: Double) -> CGImage {
        let c = base(l, since: tKey + 0.08, open: false)
        let alpha = CGFloat(ramp(l, 0.3, 0.5) * (1 - ramp(l, tKey + 0.7, tKey + 0.95)))
        let down = l >= tKey && l < tKey + 0.5
        c.panel(down ? keysDown : keysUp, at: CGPoint(x: (W - keysSize.width) / 2, y: 250), radius: 26, alpha: alpha)
        return c.image
    }

    return [
        Scene(name: "clutter", duration: 2.2, caption: "Cluttered desktop? Clear it in one click") { desk(0.0 + $0) },
        Scene(name: "menu", duration: 3.65, caption: "Minimize, close, quit or force quit at once") { desk(2.2 + $0) },
        Scene(name: "minimize", duration: 2.15, caption: "Every window minimizes in one go") { desk(5.85 + $0) },
        Scene(name: "shortcut", duration: 3.4, caption: "Or press \(shortcut) from any app", render: shortcutDesk),
    ]
}

@main struct WindowOrganizerDemo {
    @MainActor static func main() { Demo.run(scenes: windowOrganizerScenes()) }
}
