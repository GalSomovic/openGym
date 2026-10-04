#!/bin/sh
# Debug screenshot of one screen: apple/App/shot.sh <name> [launch args…]
set -e
OUT=${SHOTS:-/tmp/gymfree-shots}; mkdir -p "$OUT"
name=$1; shift
xcrun simctl terminate booted com.gsomovic.gymfree 2>/dev/null || true
xcrun simctl launch booted com.gsomovic.gymfree "$@" >/dev/null
sleep ${WAIT:-2.5}
xcrun simctl io booted screenshot "$OUT/$name.png" >/dev/null 2>&1
echo "$OUT/$name.png"
