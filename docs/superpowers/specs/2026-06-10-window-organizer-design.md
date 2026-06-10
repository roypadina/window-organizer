# Window Organizer Phase 1 Design

Date: 2026-06-10

## Summary

Window Organizer is a small native macOS menu bar app for organizing and managing open windows and apps. It is not a window switcher and will not include an Alt-Tab style interface, window thumbnails, search palette, or focus switching in phase 1.

The app targets macOS 14 Sonoma and newer. It is designed for local use first, then open source GitHub distribution and installation through a personal Homebrew tap. It is not designed for Mac App Store constraints.

Bundle identifier: `com.padina.window-organizer`

Display name: `Window Organizer`

## Phase 1 Features

Phase 1 includes four global shortcut actions:

- Minimize all windows
- Close all windows
- Quit apps
- Force quit apps, with confirmation

Global shortcuts must work while Window Organizer is running in the menu bar, even when another app is focused. Shortcuts are configurable from day one.

The app also includes:

- Menu bar icon and menu
- Settings window
- Launch at Login setting
- Accessibility permission detection and guidance
- App include/exclude rules
- Action scope setting for current visible context vs broader all Spaces/displays behavior

Automatic minimize or close rules are reserved for a later phase.

## Behavior And Safety

By default, actions target user-facing apps and windows. Default exclusions include:

- Window Organizer itself
- Finder
- Dock, menu bar, and system UI processes
- System Settings
- Protected, background, and system processes

Settings include an app rules list that can override defaults. The user can explicitly include normally skipped apps, such as Finder or System Settings, where macOS permits control.

Normal close and quit actions run immediately. These actions may be interrupted by save dialogs, unsaved document prompts, app-specific confirmations, or macOS protections. Phase 1 does not attempt to bypass those prompts.

Force quit always requires confirmation before execution.

## Window Scope

The default action scope is the current visible context: windows visible on the current Space and displays. A setting allows broader behavior across all Spaces and displays where macOS permits it.

macOS does not expose complete, reliable control over every Space and every app window. The implementation should treat broader scope as best effort and avoid claiming perfect Space-level control.

## App Structure

The app is a native Swift and SwiftUI project, using AppKit where needed.

Core components:

- `MenuBarController`: owns the menu bar extra, quick actions, Settings command, and Quit command.
- `SettingsWindow`: native settings UI for shortcuts, behavior, app rules, Launch at Login, permissions, and version information.
- `GlobalShortcutManager`: registers, updates, and unregisters configurable global keyboard shortcuts.
- `WindowActionEngine`: performs minimize, close, quit, and force quit operations.
- `TargetResolver`: enumerates running applications and windows, then filters targets using scope and app rules.
- `PermissionsHelper`: checks Accessibility permission state and opens the relevant System Settings pane.
- `PreferencesStore`: persists shortcuts, Launch at Login, scope, and app rules.

Implementation should prefer native APIs:

- `NSRunningApplication` for app enumeration, normal quit, and force quit.
- Accessibility APIs for window discovery, minimize, and close.
- AppleScript or System Events only as a targeted fallback if native APIs are not reliable enough for a specific phase 1 behavior.

## Menu Bar UX

The menu bar menu contains:

- Minimize All Windows
- Close All Windows
- Quit Apps
- Force Quit Apps...
- Settings...
- Quit Window Organizer

The menu should stay compact and operational. It should not become a dashboard or app switcher.

## Settings UX

The settings window uses a compact native layout. Tabs or simple grouped sections are acceptable.

Settings areas:

- Shortcuts: configurable global shortcuts for each action.
- Behavior: current visible context vs broader all Spaces/displays behavior.
- Apps: default exclusions and user overrides to include or exclude apps by bundle identifier.
- General: Launch at Login, Accessibility permission status, app name, and version.

The phase 1 app rules UI should stay basic. The user can pick from currently running apps and store bundle identifiers. Advanced rule types such as schedules, idle timers, profiles, auto minimize, and auto close are out of scope.

## Persistence

Preferences are stored locally using app preferences. Stored values include:

- Shortcut definitions
- Launch at Login enabled state
- Action scope
- App include rules
- App exclude rules

App rules should store bundle identifiers, not display names, because display names can change and are not unique.

## Permissions

The app requires Accessibility permission for reliable window discovery and window-level actions. The app should:

- Detect whether Accessibility permission is granted.
- Show permission status in Settings.
- Provide a direct action to open the relevant System Settings area.
- Fail gracefully when permission is missing.

Automation permissions may appear if AppleScript or System Events fallback behavior is later used. Native APIs should be preferred to reduce extra permission prompts.

## Testing And Verification

Automated tests should cover logic that can be tested without controlling real app windows:

- Shortcut configuration validation and persistence
- Default app exclusions
- Explicit app include rules
- Explicit app exclude rules
- Target selection based on scope and app rules
- Force quit confirmation requirement

Manual verification on macOS should cover:

- Accessibility permission request and recovery flow
- Global shortcuts while another app is focused
- Minimize, close, and quit behavior across common apps
- Force quit confirmation and execution
- Launch at Login persistence
- Menu bar operation without unnecessary Dock UI
- Best-effort behavior for current visible context and broader all Spaces/displays mode

## Non-Goals For Phase 1

Phase 1 does not include:

- App or window switching
- Alt-Tab style UI
- Window thumbnails
- Search palette
- Window focus controls
- Automatic minimize or close rules
- Schedules, profiles, timers, or idle detection
- Mac App Store packaging
- Perfect control of all Spaces and all app windows

