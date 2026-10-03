# Contributing to Window Organizer

Thanks for your interest! Bug reports, feature ideas, docs and code are all welcome.

## Ground rules

- **`main` is protected.** No direct pushes; changes land via Pull Request and are
  reviewed/merged by the maintainer ([@roypadina](https://github.com/roypadina)).
- Be respectful — see the [Code of Conduct](CODE_OF_CONDUCT.md).
- Keep changes focused. One logical change per PR, smallest diff that solves it.

## Getting started

```bash
git clone https://github.com/roypadina/window-organizer.git
cd window-organizer
swift test                 # core logic tests
Scripts/package_app.sh     # builds dist/Window Organizer.app
open "dist/Window Organizer.app"
```

Requirements: **macOS 14+**, Xcode or the Xcode command line tools (Swift 6).

`Scripts/package_app.sh` signs with the first code-signing identity in your keychain (or
`CODE_SIGN_IDENTITY` if set) and falls back to ad-hoc. Ad-hoc changes the code hash every
build, so macOS forgets the Accessibility grant after each rebuild. A self-signed
code-signing certificate avoids that.

## Layout

- `Sources/WindowOrganizerCore` — pure, tested logic: preferences, shortcuts, target rules.
- `Sources/WindowOrganizerApp` — the SwiftUI/AppKit menu bar app: global shortcuts
  (Carbon hot keys), Accessibility window actions, settings UI.
- `Tests/WindowOrganizerCoreTests` — Swift Testing suite for the core.
- `Assets/icons` — SVG sources for the app and menu bar icons; regenerate the PNG/icns
  with `Scripts/make_icons.sh` (needs `brew install librsvg`).

## Workflow

1. **Fork** and branch: `git checkout -b feat/my-thing`.
2. Make your change; run `swift test` and try it in the packaged app.
3. Match the surrounding style; no drive-by refactors.
4. Open a **Pull Request** against `main`. CI must be green and the maintainer must approve.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org): `feat: ...`, `fix: ...`, `docs: ...`.

## Reporting bugs / requesting features

Use the [issue templates](https://github.com/roypadina/window-organizer/issues/new/choose).
