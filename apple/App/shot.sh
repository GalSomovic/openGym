#!/bin/sh
# Debug screenshot of one screen: apple/App/shot.sh <name> [launch args…]
# SIM names the simulator (default: the booted one).
set -e
OUT=${SHOTS:-/tmp/gymfree-shots}; mkdir -p "$OUT"
DEV=${SIM:-booted}
name=$1; shift
xcrun simctl terminate "$DEV" com.gsomovic.gymfree 2>/dev/null || true
xcrun simctl launch "$DEV" com.gsomovic.gymfree "$@" >/dev/null
sleep ${WAIT:-2.5}
xcrun simctl io "$DEV" screenshot "$OUT/$name.png" >/dev/null 2>&1
echo "$OUT/$name.png"
