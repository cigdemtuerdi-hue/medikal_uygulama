# Deploy MedGift API (fixes “Sunucuya bağlanılamadı”)

The Flutter site on https://medgift.us needs a public HTTPS API.
Default production URL: `https://medgift-us-api.onrender.com`

Password reset is **email link only** (SMS was removed).

## Admin CMS (site content control)

Owner console: `https://medgift.us/admin`

- Edit landing/home copy, emergency banner, partnership footer, feature flags
- Save writes to `PUT /api/settings/admin` (requires admin login)
- Public site reads `GET /api/settings/public`

**Persistence:** On Render free tier with `MONGODB_URI=memory`, CMS saves are lost on restart.
For permanent control:

1. Create a free [MongoDB Atlas](https://www.mongodb.com/atlas) cluster
2. Copy the connection string into Render → `medgift-us-api` → Environment:
   - `MONGODB_URI=mongodb+srv://...`
   - `USE_MEMORY_DB=false`
3. Redeploy the API

Also set `ADMIN_PASSWORD` on Render (and keep GitHub secret in sync).


Diagnose locally (never prints secrets):

```bash
cd server
npm run check:messaging
```

Common failure:

1. **Email (GoDaddy SMTP 535)** — `EMAIL_PASS` wrong, or truncated because it contained `#` without quotes.
   - Fix: GoDaddy → reset password for `info@medgift.us`
   - Put full password in `.env` as `EMAIL_PASS="…"` (quotes required if password has `#`)
   - Copy the **same** value into Render → `medgift-us-api` → Environment → `EMAIL_PASS`

Health check: `https://medgift-us-api.onrender.com/api/health`  
Look at `messaging.emailConfigured`.

## Option A — Render (recommended, free)

1. Open [Render Dashboard](https://dashboard.render.com/) and sign in with GitHub.
2. **New → Blueprint** → select `cigdemtuerdi-hue/medikal_uygulama` (uses root `render.yaml`).
3. Apply. Service name: `medgift-us-api`.
4. In the service → **Environment**, set:

   | Key | Example |
   |-----|---------|
   | `EMAIL_PASS` | mailbox password (**quote if it contains `#`**) |

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

## Local email test

```bash
cd server && npm run dev
npm run check:messaging

curl -X POST http://127.0.0.1:3001/api/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"donor@medgift.us"}'
```
