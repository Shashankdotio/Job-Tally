#!/bin/sh
set -eu
cd "$(dirname "$0")"
APP="Job Tally.app"
DMG="dist/Job-Tally.dmg"

if [ ! -d "$APP" ]; then
  ./build.sh
fi

mkdir -p dist
hdiutil create -volname "Job Tally" -srcfolder "$APP" -ov -format UDZO "$DMG"
printf 'Created %s/%s\n' "$PWD" "$DMG"
