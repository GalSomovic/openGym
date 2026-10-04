#!/bin/sh
# Downloads the exercise animations bundled into the native app.
#   apple/core/fetch-media.sh   → apple/Media/ExerciseGIFs/<openGym id>.gif
#
# Source: the free ExerciseDB V1 dataset by AscendAPI (oss.exercisedb.dev),
# licensed for non-commercial apps with credit to AscendAPI. The app is free,
# with no ads and no in-app purchases, and credits AscendAPI on every demo.
#
# The GIFs are NOT committed (apple/Media is gitignored): publishing the raw
# files would be redistribution. This script fetches them once, politely
# (sequential, throttled, resumable), and Xcode bundles them into the app, so
# the app makes no network calls for media at runtime.
set -e
cd "$(dirname "$0")/.."
OUT=Media/ExerciseGIFs
mkdir -p "$OUT"
node -e "
const s=require('fs').readFileSync('../frontend/src/lib/exercises-data.js','utf8');
for (const m of s.matchAll(/\"id\":\"(\d+)\"[^}]*?\"img\":\"\d+-([A-Za-z0-9]+)\.jpg\"/g)) console.log(m[1]+' '+m[2]);
" | while read OGID EXID; do
  [ -s "$OUT/$OGID.gif" ] && continue
  curl -sf --retry 3 --retry-delay 5 -o "$OUT/$OGID.gif.part" "https://static.exercisedb.dev/media/$EXID.gif" \
    && mv "$OUT/$OGID.gif.part" "$OUT/$OGID.gif" || echo "missing $OGID ($EXID)"
  sleep 0.5
done
echo "$(ls "$OUT" | grep -c '\.gif$') GIFs, $(du -sh "$OUT" | cut -f1)"
