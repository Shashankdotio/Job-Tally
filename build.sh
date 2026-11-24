#!/bin/sh
set -eu
cd "$(dirname "$0")"
APP="Job Tally.app"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
swiftc -parse-as-library -framework AppKit -framework SwiftUI JobTally.swift -o "$APP/Contents/MacOS/JobTally"
printf 'Built %s/%s\n' "$PWD" "$APP"