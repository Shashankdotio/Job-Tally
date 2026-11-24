#!/bin/sh
set -eu
cd "$(dirname "$0")"
APP="Job Tally.app"
DMG="dist/Job-Tally.dmg"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/job-tally-dmg.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

if [ ! -d "$APP" ]; then
  ./build.sh
fi

mkdir -p dist
ditto "$APP" "$STAGE/Job Tally.app"
ln -s /Applications "$STAGE/Applications"
cp "$APP/Contents/Resources/JobTally.icns" "$STAGE/.VolumeIcon.icns"
SetFile -a C "$STAGE"
hdiutil create -volname "Job Tally" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
printf 'Created %s/%s\n' "$PWD" "$DMG"
