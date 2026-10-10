#!/bin/sh
# Archive → export → upload GymFree to App Store Connect (TestFlight / App Review).
#   apple/release/upload.sh <build-number>
# Uses the App Store Connect API key in ~/private_keys (same team as Plume).
# AGPL: tag the exact commit of every uploaded build and push the tag, so its source stays public.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/../App"
KEY=X4DTBHP75S; ISSUER=645c9907-115f-4148-aeba-5f5dd2da9e5b
BUILD=${1:?build number}
OUT=/tmp/gymfree-release
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$APP" && xcodegen generate -q
xcodebuild -project GymFree.xcodeproj -scheme GymFree -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' -archivePath "$OUT/GymFree.xcarchive" \
  CURRENT_PROJECT_VERSION="$BUILD" -allowProvisioningUpdates \
  -authenticationKeyPath ~/private_keys/AuthKey_$KEY.p8 -authenticationKeyID $KEY -authenticationKeyIssuerID $ISSUER \
  archive 2>&1 | grep -E "error:|ARCHIVE (SUCCEEDED|FAILED)"
xcodebuild -exportArchive -archivePath "$OUT/GymFree.xcarchive" -exportOptionsPlist "$HERE/ExportOptions.plist" \
  -exportPath "$OUT/export" -allowProvisioningUpdates \
  -authenticationKeyPath ~/private_keys/AuthKey_$KEY.p8 -authenticationKeyID $KEY -authenticationKeyIssuerID $ISSUER \
  2>&1 | grep -E "error|EXPORT (SUCCEEDED|FAILED)"
ls -la "$OUT/export"/*.ipa
if [ "$2" = "--upload" ]; then
  xcrun altool --upload-app --type ios --file "$OUT/export/GymFree.ipa" --apiKey $KEY --apiIssuer $ISSUER 2>&1 | grep -E "UPLOAD|rror"
  git -C "$HERE" tag -f "gymfree-1.0-build$BUILD" && git -C "$HERE" push -f origin "gymfree-1.0-build$BUILD"
fi
