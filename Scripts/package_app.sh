#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Window Organizer"
BUNDLE_ID="com.padina.window-organizer"
BUILD_CONFIG="release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:-}"
# RELEASE=1: ad-hoc signed app + dist/Window-Organizer.zip for GitHub Releases and the Homebrew cask.
RELEASE="${RELEASE:-}"

cd "$ROOT_DIR"

swift build -c "$BUILD_CONFIG"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp ".build/$BUILD_CONFIG/WindowOrganizerApp" "$MACOS_DIR/$APP_NAME"
cp Assets/icons/AppIcon.icns Assets/icons/menubar.png Assets/icons/menubar@2x.png "$RESOURCES_DIR/"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Padina</string>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$APP_NAME"

if [[ -z "$SIGNING_IDENTITY" && -z "$RELEASE" ]]; then
    SIGNING_IDENTITY="$(
        security find-identity -v -p codesigning 2>/dev/null \
            | awk -F '"' '/valid identities found/ { next } /".+"/ { print $2; exit }'
    )"
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" --identifier "$BUNDLE_ID" "$APP_DIR"
else
    [[ -n "$RELEASE" ]] || {
        echo "warning: no code-signing identity found; falling back to ad hoc signing" >&2
        echo "warning: macOS Accessibility permission may reset after rebuilds" >&2
    }
    codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_DIR"
fi

if [[ -n "$RELEASE" ]]; then
    ZIP="$DIST_DIR/Window-Organizer.zip"
    rm -f "$ZIP"
    ditto -c -k --norsrc --noextattr --keepParent "$APP_DIR" "$ZIP"
    shasum -a 256 "$ZIP"
fi

echo "$APP_DIR"
