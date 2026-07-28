#!/usr/bin/env bash
# Start MedGift API locally and expose it via Cloudflare quick tunnel.
# Prints the public HTTPS URL — set that as GitHub secret API_BASE_URL
# (or paste into .env) and redeploy the web app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
CF="${REPO}/.tools/cloudflared"
PORT="${PORT:-3005}"
URL_FILE="${ROOT}/.tunnel-url"

cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing server/.env — copy from .env.example and fill credentials."
  exit 1
fi

if [[ ! -x "$CF" ]]; then
  echo "Downloading cloudflared..."
  mkdir -p "${REPO}/.tools"
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "arm64" ]]; then
    CF_TGZ="cloudflared-darwin-arm64.tgz"
  else
    CF_TGZ="cloudflared-darwin-amd64.tgz"
  fi
  curl -fsSL -o /tmp/cf.tgz \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/${CF_TGZ}"
  tar -xzf /tmp/cf.tgz -C "${REPO}/.tools"
  chmod +x "$CF"
fi

# Free port if needed
if lsof -tiTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $PORT in use — stopping old listener..."
  lsof -tiTCP:"$PORT" -sTCP:LISTEN | xargs kill -9 2>/dev/null || true
  sleep 1
fi

echo "Starting API on :$PORT ..."
PORT="$PORT" node src/index.js >"${ROOT}/.api.log" 2>&1 &
API_PID=$!
echo "$API_PID" >"${ROOT}/.api.pid"

for i in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.3
done

if ! curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null 2>&1; then
  echo "API failed to start. See ${ROOT}/.api.log"
  exit 1
fi
echo "API healthy."

echo "Opening Cloudflare tunnel..."
rm -f "$URL_FILE"
"$CF" tunnel --url "http://127.0.0.1:${PORT}" --no-autoupdate 2>&1 | tee "${ROOT}/.tunnel.log" &
TUN_PID=$!
echo "$TUN_PID" >"${ROOT}/.tunnel.pid"

PUBLIC_URL=""
for i in $(seq 1 60); do
  PUBLIC_URL="$(grep -Eo 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "${ROOT}/.tunnel.log" 2>/dev/null | head -1 || true)"
  if [[ -n "$PUBLIC_URL" ]]; then
    break
  fi
  sleep 0.5
done

if [[ -z "$PUBLIC_URL" ]]; then
  echo "Could not get tunnel URL. See ${ROOT}/.tunnel.log"
  exit 1
fi

echo "$PUBLIC_URL" >"$URL_FILE"
echo ""
echo "============================================"
echo " Public API: $PUBLIC_URL"
echo " Health:     $PUBLIC_URL/api/health"
echo "============================================"
echo ""
echo "Keep this Terminal window open."
echo "Then set GitHub secret API_BASE_URL=$PUBLIC_URL"
echo "and re-run the Deploy Web workflow."
echo ""

# Keep foreground attached to tunnel
wait "$TUN_PID"
