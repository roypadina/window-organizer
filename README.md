<div align="center">

<img src="docs/AppIcon-1024.png" alt="Window Organizer app icon" width="160">

# Window Organizer

### Clear the desk in one keystroke.

A small native **macOS** menu bar app that minimizes, closes, quits or force quits
all your open apps and windows at once, from global shortcuts. It is not an app switcher.

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Universal](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-555555?logo=apple&logoColor=white)](#requirements)
[![Release](https://img.shields.io/github/v/release/roypadina/window-organizer?logo=github&label=release)](https://github.com/roypadina/window-organizer/releases/latest)
[![Homebrew](https://img.shields.io/badge/brew-roypadina%2Ftap-FBB040?logo=homebrew&logoColor=white)](https://github.com/roypadina/homebrew-tap)
[![CI](https://github.com/roypadina/window-organizer/actions/workflows/ci.yml/badge.svg)](https://github.com/roypadina/window-organizer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?logo=opensourceinitiative&logoColor=white)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-support-F16061?logo=ko-fi&logoColor=white)](https://ko-fi.com/roypadina)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Stars](https://img.shields.io/github/stars/roypadina/window-organizer?style=social)](https://github.com/roypadina/window-organizer/stargazers)

<br>

```bash
brew install --cask roypadina/tap/window-organizer
```

<img src="docs/screenshots/settings-shortcuts.png" alt="Window Organizer Settings, Shortcuts tab: global shortcuts for Minimize All Windows, Close All Windows, Quit Apps and Force Quit Apps" width="560">

</div>

---

## Features

- **Minimize all windows** — every window of every targeted app goes to the Dock.
- **Close all windows** — presses each window's close button; apps keep running.
- **Quit apps** — asks every targeted app to quit normally (save dialogs still appear).
- **Force quit apps** — terminates targeted apps immediately, after a confirmation.
- **Global shortcuts** for all four actions: record any key combination in Settings, with live
  preview, conflict checks and a warning when another app already owns a shortcut.
- **App rules** — include or exclude any running app by bundle identifier. Finder, the Dock,
  System Settings, menu bar apps and Window Organizer itself are skipped by default.
  Search the running apps and filter by kind (Dock, menu bar, background), developer (Apple or
  third-party) and status (targeted, skipped, has a rule).
- **Action scope** — the windows on the current Space and displays (default), or all Spaces and displays.
- **Launch at Login**, and no Dock icon: it lives in the menu bar only.

## Requirements

macOS 14 Sonoma or later · Apple Silicon and Intel (universal binary)

## Install

```bash
brew install --cask roypadina/tap/window-organizer
```

**Not notarized.** Window Organizer is self-signed (no paid Apple Developer ID), so macOS may block the first launch. Open
**System Settings → Privacy & Security**, scroll down and click **Open Anyway** (right-click → Open no longer works on macOS 15+),
or clear quarantine once:

```bash
xattr -dr com.apple.quarantine "/Applications/Window Organizer.app"
```

Or download `Window-Organizer.zip` from the [latest release](https://github.com/roypadina/window-organizer/releases/latest),
unzip it and move `Window Organizer.app` to `/Applications`.

## Accessibility permission

Minimize and close use the macOS Accessibility API, so they need permission (quit and force quit do not):

1. Click the Window Organizer menu bar icon → **Settings…** → **General**.
2. Click **Grant Access…** next to Accessibility.
3. Turn on **Window Organizer** in System Settings → Privacy & Security → Accessibility.

Since 0.2.0 releases are signed with the same certificate, so the grant survives updates.
Upgrading from 0.1.0, or still asked for access although it's on? Reset it once and grant again:

```bash
tccutil reset Accessibility com.padina.window-organizer
```

## Default shortcuts

| Shortcut | Action |
|---|---|
| `⌃⌥⌘M` | Minimize all windows |
| `⌃⌥⌘W` | Close all windows |
| `⌃⌥⌘Q` | Quit apps |
| `⌃⌥⌘⇧Q` | Force quit apps (asks first) |

Change them in **Settings… → Shortcuts**: click a shortcut and press the new keys (any key with ⌘, ⌃ or ⌥; F-keys work alone). Esc cancels, Delete removes it.
The same actions are in the menu bar menu.

## Limitations

- **Current visible context is best effort.** macOS has no public API for full Space-level window control.
- Minimize and close only reach windows that apps expose through Accessibility.
- Quit can be interrupted by save dialogs and app confirmations; Window Organizer does not bypass them.
- **Force quit discards unsaved work.** It always asks for confirmation first.
- Some system and protected processes can't be quit.
- Not notarized (see [Install](#install)).

## Privacy

No network access, no analytics. Preferences are stored in the defaults domain `com.padina.window-organizer`.

## Build from source

Requires Xcode or the Xcode command line tools (Swift 6).

```bash
git clone https://github.com/roypadina/window-organizer.git
cd window-organizer
swift test
Scripts/package_app.sh            # writes dist/Window Organizer.app
open "dist/Window Organizer.app"
```

`RELEASE=1 Scripts/package_app.sh` also writes `dist/Window-Organizer.zip`.
`swift run WindowOrganizerApp` works for quick checks, but use the packaged app for real menu bar,
Accessibility and Launch at Login behavior. See [CONTRIBUTING.md](CONTRIBUTING.md) and the
[wiki](https://github.com/roypadina/window-organizer/wiki).

## Uninstall

```bash
brew uninstall --zap --cask window-organizer
```

Or quit it, drag `/Applications/Window Organizer.app` to the Trash, and remove it from Login Items.

## Support

If Window Organizer clears your desktop in one keystroke, you can support its development — it's optional and always appreciated.

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/roypadina)

A ⭐ on the repo helps just as much.

## License

[MIT](LICENSE) © Roy Padina
