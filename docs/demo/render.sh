#!/bin/bash
# Regenerates the Window Organizer demo from scratch: compile the real Core files (action titles, default shortcuts) + kit + scene,
# render frames offscreen (no window is ever shown, nothing is clicked or captured), encode. One command: ./render.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
KIT="${KIT:-$HERE}"; [ -f "$KIT/DemoKit.swift" ] || KIT="$HERE/../kit"          # repo: kit is vendored next to this file
APP="${APP_SRC:-$HERE/../../Sources/WindowOrganizerCore}"                       # repo: docs/demo -> Sources/WindowOrganizerCore
ICONS="${APP_ICONS:-$HERE/../../Assets/icons}"                                  # the app's real menu bar glyph (menubar@2x.png)
GIF="${GIF:-$HERE/../demo.gif}"                                                 # repo: docs/demo.gif
BUILD="${BUILD:-${TMPDIR:-/tmp}/window-organizer-demo}"                         # never inside the repo (hundreds of MB of frames)
mkdir -p "$BUILD"
swiftc -swift-version 5 -parse-as-library -O -o "$BUILD/demo" \
  "$KIT/DemoKit.swift" "$HERE/scene.swift" "$APP/Models.swift" "$APP/Shortcut.swift" "$APP/Preferences.swift"
rm -rf "$BUILD/frames"
WO_ICONS="$ICONS" "$BUILD/demo" "$BUILD/frames" 30 -AppleLocale en_US -AppleLanguages "(en)"
POSTER=${POSTER:-118}  # Minimize All Windows hovered in the open menu (t = 3.93 s, reviewer asked for the menu in the poster)
"$KIT/encode.sh" "$BUILD/frames" "$GIF" "${MP4:-}" "${WEBP:-}" "${POSTER:-}"                  # empty slots keep encode.sh positional args aligned
[ -n "${KEEP_FRAMES:-}" ] || rm -rf "$BUILD/frames"                              # ~400 MB of PNGs; only after a successful encode (set -e)
