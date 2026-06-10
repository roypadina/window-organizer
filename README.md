# Window Organizer

Window Organizer is a small native macOS menu bar app for managing open windows and apps. It is not an app switcher.

Bundle identifier: `com.padina.window-organizer`

## Phase 1 Features

- Menu bar app with no Dock icon when packaged
- Configurable global shortcuts
- Minimize all windows
- Close all windows
- Quit targeted apps
- Force quit targeted apps with confirmation
- Launch at Login setting
- Accessibility permission status and shortcut to System Settings
- App include/exclude rules by bundle identifier
- Current visible context vs broader all Spaces/displays action scope

## Requirements

- macOS 14 Sonoma or newer
- Xcode command line tools or Xcode
- Accessibility permission for minimize and close window actions

## Build And Test

```bash
swift test
swift build
```

## Run During Development

```bash
swift run WindowOrganizerApp
```

When run directly through SwiftPM, macOS treats the executable differently from a packaged app. For realistic menu bar and Launch at Login behavior, use the packaged app.

## Package

```bash
Scripts/package_app.sh
```

The packaged app is written to:

```text
dist/Window Organizer.app
```

Open it with:

```bash
open "dist/Window Organizer.app"
```

## Permissions

Minimize and close actions require Accessibility permission:

1. Open Window Organizer settings.
2. Go to General.
3. Click Request or Open Settings next to Accessibility.
4. Enable Window Organizer in Privacy & Security > Accessibility.

Normal quit and force quit use `NSRunningApplication`. Some apps may still show save dialogs, block termination, or be protected by macOS.

## Current Limitations

- Current visible context is best effort because macOS does not expose perfect Space-level window control.
- Close/minimize only affects windows exposed through Accessibility.
- Force quit can discard unsaved work and always requires confirmation.
- Automatic app rules, schedules, profiles, idle timers, and app switching are out of scope for phase 1.

