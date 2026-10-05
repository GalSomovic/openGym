#!/bin/bash
# Generate the project, build for the simulator and install: apple/App/dev.sh
# SIM names the simulator (default iPhone 17 Pro); it is booted if it is not running.
set -eo pipefail
cd "$(dirname "$0")"
SIM=${SIM:-iPhone 17 Pro}
xcodegen generate -q
xcodebuild -project GymFree.xcodeproj -scheme GymFree -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath ../build/dd build 2>&1 | { grep -E "^/.*(error|warning):|BUILD (SUCC|FAIL)" | sort -u || true; }
test -d ../build/dd/Build/Products/Debug-iphonesimulator/GymFree.app
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl install "$SIM" ../build/dd/Build/Products/Debug-iphonesimulator/GymFree.app
