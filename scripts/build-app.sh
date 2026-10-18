#!/bin/zsh
# Created: 2026-10-18 14:29 -05:00 · Edited: 2026-10-18 14:29 -05:00
# F5-T1 — build a release binary and wrap it as a sandboxed, hardened, ad-hoc signed .app.
#   scripts/build-app.sh            -> build/DockWatch.app
#   scripts/build-app.sh --install  -> also copies to ~/Applications/DockWatch.app
# Ad-hoc identity ("-"): replace with a Developer ID to notarize (D15, v1.5).
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
APP=build/DockWatch.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/DockWatch "$APP/Contents/MacOS/DockWatch"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --options runtime --entitlements Resources/DockWatch.entitlements --sign - "$APP"
codesign --verify --strict "$APP"
echo "Built $APP"
if [[ "${1:-}" == "--install" ]]; then
  mkdir -p ~/Applications
  # A running copy must quit before it is replaced; ditto over a live bundle breaks code signing.
  osascript -e 'tell application id "com.martingleason.dockwatch" to quit' >/dev/null 2>&1 || true
  sleep 1
  rm -rf ~/Applications/DockWatch.app
  ditto "$APP" ~/Applications/DockWatch.app
  echo "Installed ~/Applications/DockWatch.app"
fi
