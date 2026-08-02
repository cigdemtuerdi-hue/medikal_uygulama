#!/usr/bin/env bash
# Build a release IPA for App Store Connect.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d /Applications/Xcode.app ]]; then
  echo "ERROR: Full Xcode is required. Install from the Mac App Store, then:"
  echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

API_BASE_URL="${API_BASE_URL:-https://medgift-us-api.onrender.com}"

flutter pub get
flutter build ipa \
  --release \
  --dart-define="API_BASE_URL=${API_BASE_URL}" \
  --export-options-plist=ios/ExportOptions.plist

echo
echo "IPA / archive under build/ios/"
echo "Next: open Xcode Organizer or Transporter to upload to App Store Connect."
