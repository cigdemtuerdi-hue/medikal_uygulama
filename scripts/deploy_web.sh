#!/usr/bin/env bash
# Local web build + deploy helpers for MedGift US.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-build}"

echo "==> Flutter web release build"
flutter pub get
flutter build web --release --base-href /

case "$TARGET" in
  build)
    echo "✓ Built: $ROOT/build/web"
    echo "Preview locally:"
    echo "  cd build/web && python3 -m http.server 8080"
    ;;
  firebase)
    command -v firebase >/dev/null || {
      echo "Install Firebase CLI: npm i -g firebase-tools"
      exit 1
    }
    firebase deploy --only hosting
    ;;
  vercel)
    command -v vercel >/dev/null || {
      echo "Install Vercel CLI: npm i -g vercel"
      exit 1
    }
    vercel deploy --prebuilt --prod --yes || vercel ./build/web --prod --yes
    ;;
  *)
    echo "Usage: $0 [build|firebase|vercel]"
    exit 1
    ;;
esac
