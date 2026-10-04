#!/bin/bash
# Generate the project, build for the booted simulator and install: apple/App/dev.sh
set -eo pipefail
cd "$(dirname "$0")"
xcodegen generate -q
xcodebuild -project GymFree.xcodeproj -scheme GymFree -destination "platform=iOS Simulator,name=${SIM:-iPhone 17 Pro}" \
  -derivedDataPath ../build/dd build 2>&1 | { grep -E "^/.*(error|warning):|BUILD (SUCC|FAIL)" | sort -u || true; }
test -d ../build/dd/Build/Products/Debug-iphonesimulator/GymFree.app
xcrun simctl install booted ../build/dd/Build/Products/Debug-iphonesimulator/GymFree.app
