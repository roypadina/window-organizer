# Changelog

All notable changes to Window Organizer are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
