#!/bin/sh
# Bundles openGym's training engine for JavaScriptCore.
#   apple/core/build.sh   → apple/OpenGymCore/Sources/OpenGymCore/Resources/engine.js
set -e
cd "$(dirname "$0")"
OUT=../OpenGymCore/Sources/OpenGymCore/Resources
mkdir -p "$OUT"
node gen-defaults.mjs
node gen-body.mjs
../../frontend/node_modules/.bin/vitest run --root . --silent
../../frontend/node_modules/.bin/rolldown -c rolldown.config.mjs
ls -la "$OUT/engine.js" | awk '{print "engine.js", $5, "bytes"}'
