# Window Organizer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build phase 1 of Window Organizer as a native macOS menu bar app with configurable global shortcuts for minimize, close, quit, and confirmed force quit.

**Architecture:** Use a Swift package with a testable `WindowOrganizerCore` library and a `WindowOrganizerApp` executable target. Core owns preferences models, shortcut validation, app filtering, and action policy; the app target owns SwiftUI/AppKit UI, global shortcut registration, Accessibility window operations, app lifecycle operations, and packaging support.

**Tech Stack:** Swift 6.3, Swift Package Manager, SwiftUI, AppKit, Accessibility APIs, Carbon global hotkeys, ServiceManagement, XCTest.

---

## File Structure

- Create `Package.swift`: defines a macOS 14 Swift package with library, executable, and tests.
- Create `Sources/WindowOrganizerCore/Models.swift`: app actions, scope, app descriptors, rules, and default exclusions.
- Create `Sources/WindowOrganizerCore/Shortcut.swift`: shortcut model, validation, display text, and Carbon conversion helpers.
- Create `Sources/WindowOrganizerCore/Preferences.swift`: default preferences and JSON/UserDefaults encoding surface.
- Create `Sources/WindowOrganizerCore/TargetResolver.swift`: pure filtering rules for app descriptors.
- Create `Sources/WindowOrganizerCore/ActionPolicy.swift`: determines confirmation and permission requirements per action.
- Create `Sources/WindowOrganizerApp/WindowOrganizerApp.swift`: SwiftUI app entry, menu bar menu, settings scene.
- Create `Sources/WindowOrganizerApp/AppController.swift`: coordinates actions, preferences, shortcuts, permissions, and app engine.
- Create `Sources/WindowOrganizerApp/GlobalShortcutManager.swift`: registers configurable global shortcuts with Carbon.
- Create `Sources/WindowOrganizerApp/WindowActionEngine.swift`: performs Accessibility minimize/close and app quit/force quit.
- Create `Sources/WindowOrganizerApp/PermissionsHelper.swift`: checks and opens Accessibility permissions.
- Create `Sources/WindowOrganizerApp/LoginItemManager.swift`: controls Launch at Login.
- Create `Sources/WindowOrganizerApp/SettingsView.swift`: native settings UI.
- Create `Scripts/package_app.sh`: builds an `.app` bundle with `LSUIElement` and bundle identifier `com.padina.window-organizer`.
- Create `Tests/WindowOrganizerCoreTests/WindowOrganizerCoreTests.swift`: tests for shortcut validation, rules, target selection, defaults, and force quit confirmation.
- Create `README.md`: build, run, package, and permission instructions.

## Task 1: Test Core Behavior First

**Files:**
- Create: `Package.swift`
- Create: `Tests/WindowOrganizerCoreTests/WindowOrganizerCoreTests.swift`

- [ ] **Step 1: Write package and failing core tests**

Create the Swift package manifest and tests that import `WindowOrganizerCore`. The tests should cover default exclusions, explicit include overrides, explicit excludes, shortcut validation, default preferences, and force quit confirmation.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test`

Expected: failure because `WindowOrganizerCore` types do not exist yet.

## Task 2: Implement Core Library

**Files:**
- Create: `Sources/WindowOrganizerCore/Models.swift`
- Create: `Sources/WindowOrganizerCore/Shortcut.swift`
- Create: `Sources/WindowOrganizerCore/Preferences.swift`
- Create: `Sources/WindowOrganizerCore/TargetResolver.swift`
- Create: `Sources/WindowOrganizerCore/ActionPolicy.swift`

- [ ] **Step 1: Implement minimal core models and logic**

Add the models and pure logic required by the tests: app descriptors, preferences, shortcut validation, app filtering, and action policy.

- [ ] **Step 2: Run tests and verify GREEN**

Run: `swift test`

Expected: all core tests pass.

- [ ] **Step 3: Commit core logic**

Run: `git add Package.swift Sources/WindowOrganizerCore Tests/WindowOrganizerCoreTests docs/superpowers/plans/2026-06-10-window-organizer-implementation.md && git commit -m "Add Window Organizer core model"`

## Task 3: Build Native App Shell

**Files:**
- Create: `Sources/WindowOrganizerApp/WindowOrganizerApp.swift`
- Create: `Sources/WindowOrganizerApp/AppController.swift`
- Create: `Sources/WindowOrganizerApp/SettingsView.swift`
- Create: `Sources/WindowOrganizerApp/PermissionsHelper.swift`
- Create: `Sources/WindowOrganizerApp/LoginItemManager.swift`

- [ ] **Step 1: Implement SwiftUI menu bar app and settings**

Add a `MenuBarExtra` app with menu actions, a settings window, permission status, Launch at Login toggle, scope picker, shortcut fields, and basic app rules list.

- [ ] **Step 2: Build app shell**

Run: `swift build`

Expected: build succeeds.

## Task 4: Add Shortcut Registration And Actions

**Files:**
- Create: `Sources/WindowOrganizerApp/GlobalShortcutManager.swift`
- Create: `Sources/WindowOrganizerApp/WindowActionEngine.swift`
- Modify: `Sources/WindowOrganizerApp/AppController.swift`

- [ ] **Step 1: Implement global shortcuts and action engine**

Register Carbon global hotkeys from saved shortcut preferences. Implement minimize and close using Accessibility windows where permission is granted. Implement quit and force quit using `NSRunningApplication`, with force quit routed through confirmation.

- [ ] **Step 2: Build and test**

Run: `swift test && swift build`

Expected: tests pass and app builds.

- [ ] **Step 3: Commit app implementation**

Run: `git add Sources README.md Scripts Package.swift && git commit -m "Implement menu bar window organizer app"`

## Task 5: Package And Verify

**Files:**
- Create: `Scripts/package_app.sh`
- Create: `README.md`

- [ ] **Step 1: Add packaging script and README**

Add a script that builds release binary output into `dist/Window Organizer.app` with bundle identifier `com.padina.window-organizer`, `LSUIElement=true`, and usage descriptions. Document build, test, run, package, permissions, and current limitations.

- [ ] **Step 2: Run final verification**

Run: `swift test && swift build && Scripts/package_app.sh`

Expected: tests pass, build succeeds, and `dist/Window Organizer.app` exists.

- [ ] **Step 3: Commit packaging docs**

Run: `git add Scripts README.md && git commit -m "Add packaging and usage docs"`

