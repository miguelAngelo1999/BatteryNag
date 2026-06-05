#!/bin/bash
# Build BatteryNag.app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$SCRIPT_DIR/BatteryNag.app"
SRC="$SCRIPT_DIR/BatteryNag"

echo "Building BatteryNag..."

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

swiftc -o "$APP/Contents/MacOS/BatteryNag" \
  -framework AppKit \
  -framework IOKit \
  -framework UserNotifications \
  -framework ServiceManagement \
  -target arm64-apple-macos13.0 \
  "$SRC/BatteryNagApp.swift" \
  "$SRC/BatteryMonitor.swift" \
  "$SRC/ContentView.swift"

echo "Done! App at: $APP"
echo ""
echo "To install to Applications: cp -r \"$APP\" /Applications/"
echo "To run: open \"$APP\""
