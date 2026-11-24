#!/bin/sh
set -eu
cd "$(dirname "$0")"
APP="Job Tally.app"
ICONSET="build/JobTally.iconset"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ICONSET"
cp Info.plist "$APP/Contents/Info.plist"
sips -z 16 16 assets/JobTally_logo.png --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 assets/JobTally_logo.png --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 assets/JobTally_logo.png --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 assets/JobTally_logo.png --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 assets/JobTally_logo.png --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 assets/JobTally_logo.png --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 assets/JobTally_logo.png --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 assets/JobTally_logo.png --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 assets/JobTally_logo.png --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 assets/JobTally_logo.png --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns -o "$APP/Contents/Resources/JobTally.icns" "$ICONSET"
swiftc -parse-as-library -framework AppKit -framework SwiftUI JobTally.swift -o "$APP/Contents/MacOS/JobTally"
printf 'Built %s/%s\n' "$PWD" "$APP"
