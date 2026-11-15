#!/usr/bin/env bash
# Builds the iPad app, opens every room by deep link on an iPad simulator and saves one PNG per room.
# Usage: scripts/screens.sh <out-dir> [simulator-udid]
#   KYM_APPEARANCE=light|dark   sets the simulator's appearance first (default light)
#   KYM_ONLY="today gallery"    shoots only the named links (first word of each shot line)
#   Extra shots for sheets and sub-pages live in scripts/screens.d/<room>.sh, one `shot` per line.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?out dir}"; UDID="${2:-${KYM_SIM:-50DD38E8-51D3-4868-8E38-90BA7C5D3FF9}}"
DD=build/screens
mkdir -p "$OUT"
xcodebuild build -project KymMaths.xcodeproj -scheme KymMaths-iPad \
  -destination "id=$UDID" -configuration Debug CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$DD" -quiet
APP=$(find "$DD/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name '*.app' | head -1)
BID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 || true
xcrun simctl ui "$UDID" appearance "${KYM_APPEARANCE:-light}"
xcrun simctl install "$UDID" "$APP"
# Each shot relaunches with -KymDeepLink; `simctl openurl` stops on an "Open in KymMaths?" prompt.
# shot <link> <seconds> <name> [extra launch args, e.g. -EuclidProgress head]
shot() {
  if [[ -n "${KYM_ONLY:-}" && " $KYM_ONLY " != *" ${1%%/*} "* ]]; then return; fi
  local link="$1" wait="$2" name="$3"; shift 3
  xcrun simctl launch --terminate-running-process "$UDID" "$BID" -KymDeepLink "$link" "$@" >/dev/null
  sleep "$wait"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null
  echo "$OUT/$name.png"
}
shot today 4 01-today
shot school 2.5 03-school
shot chapter 3 06-patterned
shot chapter/0/read 4 07-chapter-0
shot chapter/1 4 07-chapter-1
shot widget 2.5 09-atlas
shot polya 2.5 11-polya
shot journal 2.5 12-journal
shot coach 2.5 15-coach
shot euclid 2.5 16-euclid
shot deadlines 2.5 14-deadlines
shot settings 2.5 20-settings
shot gallery 3 00-gallery
shot today/flow 3 02-daily-flow
shot proof/1 3 04-proof-studio
shot euclid/I.1 3 17-euclid-board
shot euclid/motif:M1 3 19-euclid-motif -EuclidProgress head
for extra in scripts/screens.d/*.sh; do [[ -e "$extra" ]] && source "$extra"; done
