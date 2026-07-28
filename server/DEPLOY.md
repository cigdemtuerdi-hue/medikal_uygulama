# Deploy MedGift API (fixes “Sunucuya bağlanılamadı”)

The Flutter site on https://medgift.us needs a public HTTPS API.
Default production URL: `https://medgift-us-api.onrender.com`

## Option A — Render (recommended, free)

1. Open [Render Dashboard](https://dashboard.render.com/) and sign in with GitHub.
2. **New → Blueprint** → select `cigdemtuerdi-hue/medikal_uygulama` (uses root `render.yaml`).
3. Apply. Service name: `medgift-us-api`.
4. In the service → **Environment**, set (from your local `server/.env`):

   | Key | Example |
   |-----|---------|
   | `EMAIL_PASS` | mailbox password |
   | `TWILIO_ACCOUNT_SID` | `AC…` |
   | `TWILIO_AUTH_TOKEN` | auth token |
   | `TWILIO_FROM_NUMBER` | `+17372583478` |
   | `TWILIO_API_KEY` | optional |
   | `TWILIO_API_SECRET` | optional |

5. Wait until **Live**. Open `https://medgift-us-api.onrender.com/api/health`.
6. GitHub → repo **Settings → Secrets → Actions**:
   - `API_BASE_URL` = `https://medgift-us-api.onrender.com`
   - (optional) `RENDER_DEPLOY_HOOK` = Deploy Hook URL from Render
7. **Actions → Deploy Web → Run workflow**.

## Option B — Temporary tunnel (Mac stays awake)

```bash
cd server
./scripts/go-live.sh
```

Copy the printed `https://….trycloudflare.com` URL into GitHub secret `API_BASE_URL`, then re-run **Deploy Web**.

## Local SMS test (no deploy)

```bash
cd server && npm run dev
curl -X POST http://127.0.0.1:3001/api/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"donor@medgift.us","phone":"+19492794630","method":"sms"}'
```
