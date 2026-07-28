# Deploy MedGift API (fixes “Sunucuya bağlanılamadı”)

The Flutter site on https://medgift.us needs a public HTTPS API.
Default production URL: `https://medgift-us-api.onrender.com`

## Why email / SMS may not arrive

Diagnose locally (never prints secrets):

```bash
cd server
node scripts/check-messaging.js
```

Current failure modes we have seen:

1. **Email (GoDaddy SMTP 535)** — `EMAIL_PASS` wrong, or truncated because it contained `#` without quotes.
   - Fix: GoDaddy → reset password for `info@medgift.us`
   - Put full password in `.env` as `EMAIL_PASS="…"` (quotes required if password has `#`)
   - Copy the **same** value into Render → `medgift-us-api` → Environment → `EMAIL_PASS`
2. **SMS (Twilio)** — account authenticates but `TWILIO_FROM_NUMBER` is **not owned** by the account (no Incoming Numbers).
   - Fix: Twilio Console → Buy a US number → set `TWILIO_FROM_NUMBER` to that E.164 value
   - Also set `TWILIO_ACCOUNT_SID` + `TWILIO_AUTH_TOKEN` on Render
3. **Fake success** — if the user email/phone is not in the API DB (memory DB resets on Render free sleep), forgot-password returns success without sending. Sign up again (or keep API warm) so the account exists, then retry.

Health check (no secrets): `https://medgift-us-api.onrender.com/api/health`  
Look at `messaging.emailConfigured` and `messaging.twilioConfigured`.

## Option A — Render (recommended, free)

1. Open [Render Dashboard](https://dashboard.render.com/) and sign in with GitHub.
2. **New → Blueprint** → select `cigdemtuerdi-hue/medikal_uygulama` (uses root `render.yaml`).
3. Apply. Service name: `medgift-us-api`.
4. In the service → **Environment**, set (from your local `server/.env`):

   | Key | Example |
   |-----|---------|
   | `EMAIL_PASS` | mailbox password (**quote if it contains `#`**) |
   | `TWILIO_ACCOUNT_SID` | `AC…` |
   | `TWILIO_AUTH_TOKEN` | auth token |
   | `TWILIO_FROM_NUMBER` | Twilio **owned** number e.g. `+1737…` |
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

## Local SMS / email test

```bash
cd server && npm run dev
node scripts/check-messaging.js

curl -X POST http://127.0.0.1:3001/api/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"donor@medgift.us","method":"email"}'

curl -X POST http://127.0.0.1:3001/api/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"donor@medgift.us","phone":"+1YOUR_NUMBER","method":"sms"}'
```
