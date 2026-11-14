# Changelog

All notable changes to Window Organizer are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-11-14

### Added
- Ko-fi support card: about 3 seconds after a bulk action (minimize, close or quit, from the menu or a shortcut) that changed something, a small receipt card may ask for a tip. It waits until 7 days after you install or update to this version, and until you have done more than 20 bulk actions that changed something. It asks at most 3 times a year, and never during the Welcome window, a dialog, shortcut recording, while the microphone is in use or while you are away. "Ask me in 2 weeks" snoozes it. "Nope, don't ask again" keeps it quiet until the next major version, and for at least 90 days. A card still open when you start the next bulk action closes and counts as a snooze; one left unanswered fades after 5 minutes and counts as a snooze too. The card never takes keyboard focus, and the same three choices are in the menu for keyboard and VoiceOver users. Hold ⌥ in the menu for "Show Support Prompt Now" to preview it (macOS 15 or later).

### Changed
- Minimize all windows skips windows that are already minimized and no longer counts them.

## [0.4.1] - 2026-11-04

### Added
- **Check for Updates…** (or **Install Update X.Y.Z…** once one is found) in the menu-bar menu.

## [0.4.0] - 2026-11-04

### Added
- Updates from inside the app, with your permission. Window Organizer asks once, on its second launch, whether to check for updates automatically; with your yes it checks once a day (downloading the release feed from GitHub, which sends nothing about you) and asks before installing a new version. Check by hand with **Check for Updates…** in the About window or Settings › About. Updates are signed, keep the Accessibility grant, and need no `xattr` step.

## [0.3.0] - 2026-10-30

### Added
- Welcome window on first launch, and "Welcome Guide…" in Settings > General: what the app does, your current shortcuts, the Accessibility step and how to reach Settings when the menu bar icon is hidden.
- The menu shows "Grant Accessibility Access…" while Minimize and Close cannot work yet; a blocked Minimize or Close opens the Accessibility pane.
- The menu shows your recorded shortcuts next to each action.
- Opening Window Organizer again from Applications or Raycast opens Settings.

### Changed
- Settings and About open in front with the menu bar and Dock icon while they are open, and close with ⌘W.
- Settings has its own window with a toolbar of tabs and remembers the last tab.
- Quit Window Organizer is ⌘Q; the wrong ⌘M, ⌘W and ⌘Q hints on the bulk actions are gone.
- The Force Quit confirmation appears in front of other apps.
- Settings status and hint text is easier to read; colour stays on the icons.

### Fixed
- Open at Login shows the real system state and no longer re-adds a login item you removed in System Settings.
- VoiceOver: the remove-shortcut button, recorders and per-app rule pop-ups have proper labels.

## [0.2.4] - 2026-10-23

### Added
- About: request a feature / contribute. Two buttons open the feature-request form and CONTRIBUTING.md; Ko-fi supporters' requests go to the front of the queue.

## [0.2.3] - 2026-10-23

### Changed
- Universal build: now runs on Intel Macs as well as Apple Silicon.
- README: Requirements block, Open Anyway steps for macOS 15+, Settings screenshot, release and universal badges.

## [0.2.2] - 2026-10-03

### Changed
- Custom About window (no clipped text); compact About in Settings.

## [0.2.1] - 2026-10-03

### Added
- About section and menu items with a Ko-fi support link; README Support section.

## [0.2.0] - 2026-10-03

### Added
- **Record any shortcut**: click a shortcut and press any key with ⌘, ⌃ or ⌥ (F-keys work alone). Live modifier preview, Esc cancels, Delete or ⓧ clears, conflicts between actions are refused, and a ⚠︎ warns when another app already owns a shortcut.
- **Apps tab**: search, filter by kind / developer / status, app icons, Targeted/Skipped per app, an explanation of Default / Include / Exclude; the list updates as apps launch and quit.
- **General tab**: live Accessibility status that flips to Granted by itself, one Grant Access button, About section.

### Changed
- Redesigned Settings: native tabs, grouped forms, Restore Defaults.

### Fixed
- The app kept asking for Accessibility although it was granted. Releases are now signed with a stable certificate, so the grant survives updates.

### Notes
- Upgrading from 0.1.0: run `tccutil reset Accessibility com.padina.window-organizer` once and grant again.

## [0.1.0] - 2026-10-03

First public release.

### Added
- Minimize all windows (⌃⌥⌘M), close all windows (⌃⌥⌘W), quit apps (⌃⌥⌘Q), force quit apps with confirmation (⌃⌥⌘⇧Q), all configurable.
- App include/exclude rules, action scope (current Space or all Spaces), Launch at Login.
- Menu bar only, no Dock icon.

### Notes
- Requires macOS 14+. Ad-hoc signed, not notarized: right-click → Open on first launch. Minimize/close need Accessibility permission.

[Unreleased]: https://github.com/roypadina/window-organizer/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/roypadina/window-organizer/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/roypadina/window-organizer/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/roypadina/window-organizer/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/roypadina/window-organizer/releases/tag/v0.1.0
