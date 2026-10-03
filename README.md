<div align="center">

<img src="docs/AppIcon-1024.png" alt="Window Organizer app icon" width="160">

# Window Organizer

### Clear the desk in one keystroke.

A small native **macOS** menu bar app that minimizes, closes, quits or force quits
all your open apps and windows at once, from global shortcuts. It is not an app switcher.

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
[![CI](https://github.com/roypadina/window-organizer/actions/workflows/ci.yml/badge.svg)](https://github.com/roypadina/window-organizer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?logo=opensourceinitiative&logoColor=white)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Stars](https://img.shields.io/github/stars/roypadina/window-organizer?style=social)](https://github.com/roypadina/window-organizer/stargazers)

<br>

<!-- Screenshot placeholder: add docs/screenshots/menu.png (the menu bar menu) and replace this comment with
<img src="docs/screenshots/menu.png" alt="The Window Organizer menu bar menu" width="420"> -->

</div>

---

## Features

- **Minimize all windows** — every window of every targeted app goes to the Dock.
- **Close all windows** — presses each window's close button; apps keep running.
- **Quit apps** — asks every targeted app to quit normally (save dialogs still appear).
- **Force quit apps** — terminates targeted apps immediately, after a confirmation.
- **Global shortcuts** for all four actions, configurable in Settings.
- **App rules** — include or exclude any running app by bundle identifier. Finder, the Dock,
  System Settings, menu bar apps and Window Organizer itself are skipped by default.
- **Action scope** — the windows on the current Space and displays (default), or all Spaces and displays.
- **Launch at Login**, and no Dock icon: it lives in the menu bar only.

## Install

> **Requires macOS 14 Sonoma or newer.**

```bash
brew install --cask roypadina/tap/window-organizer
```

**Not notarized.** Window Organizer is ad-hoc signed, so macOS may block the first launch. Either
right-click it in `/Applications` → **Open** (then **Open Anyway** in System Settings → Privacy & Security),
or clear quarantine once:

```bash
xattr -dr com.apple.quarantine "/Applications/Window Organizer.app"
```

Or download `Window-Organizer.zip` from the [latest release](https://github.com/roypadina/window-organizer/releases/latest),
unzip it and move `Window Organizer.app` to `/Applications`.

## Accessibility permission

Minimize and close use the macOS Accessibility API, so they need permission (quit and force quit do not):

1. Click the Window Organizer menu bar icon → **Settings…** → **General**.
2. Click **Request** (or **Open Settings**) next to Accessibility.
3. Turn on **Window Organizer** in System Settings → Privacy & Security → Accessibility.

The ad-hoc signature changes with every update, so after an update you may need to turn the
switch off and on again, or reset it and grant again:

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

Change them in **Settings… → Shortcuts**: pick a key and the modifiers for each action.
The same actions are in the menu bar menu.

## Limitations

- **Current visible context is best effort.** macOS has no public API for full Space-level window control.
- Minimize and close only reach windows that apps expose through Accessibility.
- Quit can be interrupted by save dialogs and app confirmations; Window Organizer does not bypass them.
- **Force quit discards unsaved work.** Confirmation is on by default (Settings → Behavior).
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

`RELEASE=1 Scripts/package_app.sh` also writes an ad-hoc signed `dist/Window-Organizer.zip`.
`swift run WindowOrganizerApp` works for quick checks, but use the packaged app for real menu bar,
Accessibility and Launch at Login behavior. See [CONTRIBUTING.md](CONTRIBUTING.md) and the
[wiki](https://github.com/roypadina/window-organizer/wiki).

## Uninstall

```bash
brew uninstall --zap --cask window-organizer
```

Or quit it, drag `/Applications/Window Organizer.app` to the Trash, and remove it from Login Items.

## Support

If Window Organizer saves you some clicks, you can [**buy me a coffee on Ko-fi ☕**](https://ko-fi.com/roypadina) — optional, always appreciated. A **⭐ star** helps just as much.

## License

[MIT](LICENSE) © Roy Padina
