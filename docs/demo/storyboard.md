# Window Organizer demo — storyboard (11.4 s, loops)

Real code: `OrganizerAction.title`, `OrganizerPreferences.defaults` and `OrganizerShortcut.displayString` from `Sources/WindowOrganizerCore`
(`Models.swift`, `Shortcut.swift`, `Preferences.swift`), compiled unchanged: menu titles and the default shortcut ⌃⌥⌘M come from them.
The other menu rows copy `MenuContent` in `WindowOrganizerApp.swift` (Force Quit Apps… :50, Settings… :56, About :60, Support :64, Quit :68;
the "Grant Accessibility Access…" row :36 is left out: access is granted). Status item glyph = the app's real `Assets/icons/menubar@2x.png`.
Fake data: five generic app windows (Meeting notes, Budget, Inbox, Mockups, Console) with made-up content, no brand names.

| # | Scene | Start | Dur | What happens | Caption |
|---|-------|-------|-----|--------------|---------|
| 1 | clutter | 0.0 | 2.2 | Five overlapping app windows, the last one active (others inactive). Menu bar shows the Window Organizer glyph. | Cluttered desktop? Clear it in one click |
| 2 | menu | 2.2 | 3.65 | Cursor glides to the status item, click: item highlights, menu opens at once (Minimize All Windows ⌃⌥⌘M, Close All Windows ⌃⌥⌘W, Quit Apps ⌃⌥⌘Q, Force Quit Apps…, Settings… ⌘,, About, Support on Ko-fi, Quit). Hover tours the four actions, then back to Minimize All Windows. | Minimize, close, quit or force quit at once |
| 3 | minimize | 5.85 | 2.15 | Click on Minimize All Windows: menu closes at once, cursor fades, all five windows shrink toward the bottom (scale + fade, 0.07 s stagger, front first). Clean desktop. | Every window minimizes in one go |
| 4 | shortcut | 8.0 | 3.4 | Crossfade to a fresh cluttered desktop (same five windows, no cursor, no menu). A keycap panel (⌃ ⌥ ⌘ M, one key per glyph of the real `displayString`) fades in, the keys press at 1.3 s, the five windows minimize exactly like scene 3, the keys fade out. Clean desktop at the end. | Or press ⌃⌥⌘M from any app |

Transitions: 0.2 s crossfade between scenes (scenes 1–3 draw from one shared timeline; scene 3 → 4 blends a clean desktop into a fresh cluttered one); captions
fade old 0–0.12 s / new 0.12–0.35 s; the last 0.2 s dissolves into scene 1's first frame (clean loop).
Cursor: system arrow, eased glides on a slight arc, click = dip + ripple; visible only while it points at something.
Poster: frame 118 (t = 3.93 s, Minimize All Windows hovered in the open menu), pinned in `render.sh`.
Render: `./render.sh` (swiftc + 30 fps frames + encode).
