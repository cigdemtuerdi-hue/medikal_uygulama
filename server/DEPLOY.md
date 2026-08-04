# Deploy MedGift API (fixes “Sunucuya bağlanılamadı”)

The Flutter site on https://medgift.us needs a public HTTPS API.
Default production URL: `https://medgift-us-api.onrender.com`

Password reset is **email link only** (SMS was removed).

## Admin CMS (site content control)

Owner console: `https://medgift.us/admin`

- Edit landing/home copy, emergency banner, partnership footer, feature flags
- Save writes to `PUT /api/settings/admin` (requires admin login)
  (alias also available: `PUT /api/admin/settings`)
- Public site reads `GET /api/settings/public`

**Persistence:** On Render free tier with `MONGODB_URI=memory`, CMS saves are lost on restart.
For permanent control, set MongoDB Atlas (≈5 minutes):

### MongoDB Atlas + Render (kalıcı CMS)

1. Open https://www.mongodb.com/cloud/atlas → **Sign up / Log in** (Google ile olabilir).
2. **Build a Database** → **M0 Free** → Provider/Region (örn. AWS / closest) → **Create**.
3. **Database Access** → **Add New Database User**
   - Authentication: Password
   - Username: `medgift`
   - Password: güçlü bir şifre oluştur (kaydet)
   - Role: **Atlas admin** veya **Read and write to any database**
4. **Network Access** → **Add IP Address** → **Allow Access from Anywhere** (`0.0.0.0/0`)  
   (Render’ın IP’si değiştiği için gerekli)
5. **Database** → **Connect** → **Drivers** → copy connection string:  
   `mongodb+srv://medgift:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority`  
   - `<password>` yerine gerçek şifreyi yaz  
   - Sonuna DB adı ekle: `...mongodb.net/medgift_us?retryWrites=true&w=majority`
6. Open https://dashboard.render.com → service **medgift-us-api** → **Environment**:

   | Key | Value |
   |-----|--------|
   | `MONGODB_URI` | `mongodb+srv://medgift:SIFRE@cluster.../medgift_us?retryWrites=true&w=majority` |
   | `USE_MEMORY_DB` | `false` |
   | `ADMIN_PASSWORD` | (admin paneli şifren) |

7. **Manual Deploy** → **Deploy latest commit** (veya Save Environment → otomatik restart).
8. Kontrol: https://medgift-us-api.onrender.com/api/health  
   `"db":"mongo"` görünmeli (artık `"memory"` olmamalı).
9. Admin’de bir metin kaydet → Render restart sonrası da durmalı.

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

## Stripe Checkout (sales marketplace)

Buyers pay the full listing price on MedGift’s Stripe account. The API records
`commissionCents` / `sellerNetCents` (17%); Connect payouts can come later.

1. Stripe Dashboard → **Developers → API keys** → copy **Secret key** (`sk_test_…` or `sk_live_…`).
2. **Developers → Webhooks → Add endpoint**
   - URL: `https://medgift-us-api.onrender.com/api/payments/webhook`
   - Events: `checkout.session.completed`, `checkout.session.expired`
   - Copy the **Signing secret** (`whsec_…`).
3. Render → **medgift-us-api** → **Environment**:

   | Key | Value |
   |-----|--------|
   | `STRIPE_SECRET_KEY` | `sk_…` (**not** `whsec_…`) |
   | `STRIPE_WEBHOOK_SECRET` | `whsec_…` |
   | `APP_ORIGIN` | `https://medgift.us` |

   Do **not** swap these. `whsec_` in `STRIPE_SECRET_KEY` makes Buy fail with
   `Invalid API Key provided: whsec_…`. Health then shows
   `stripeConfigured: false` and `stripeMisconfig: "webhook_secret_in_api_key_slot"`.

4. Redeploy / restart. Health should show `"payments":{"stripeConfigured":true}`.
5. Shop → **Buy** opens Stripe Checkout; success returns to `/shop/success`.

Without a valid `sk_` secret the API stays up; checkout returns `STRIPE_NOT_CONFIGURED` and the app falls back to a 48-hour hold (or PayPal if configured).

## PayPal Checkout (sales marketplace)

Payments settle to the PayPal Business account for **`info@medgift.us`**.

1. [PayPal Developer Dashboard](https://developer.paypal.com/dashboard/applications) → create a **REST API** app under the Business account that owns `info@medgift.us`.
2. Copy **Client ID** and **Secret** (Live or Sandbox).
3. **Webhooks → Add webhook**
   - URL: `https://medgift-us-api.onrender.com/api/payments/paypal/webhook`
   - Events: `CHECKOUT.ORDER.APPROVED`, `PAYMENT.CAPTURE.COMPLETED`
   - Copy the **Webhook ID**.
4. Render → **medgift-us-api** → **Environment**:

   | Key | Value |
   |-----|--------|
   | `PAYPAL_CLIENT_ID` | from Developer Dashboard |
   | `PAYPAL_CLIENT_SECRET` | from Developer Dashboard |
   | `PAYPAL_MODE` | `live` or `sandbox` |
   | `PAYPAL_MERCHANT_EMAIL` | `info@medgift.us` |
   | `PAYPAL_WEBHOOK_ID` | webhook ID |

5. Redeploy / restart. Health should show `"paypalConfigured":true` and `"paypalMerchantEmail":"info@medgift.us"`.
6. Shop → **Buy** → **Pay with PayPal** opens PayPal; return hits `/shop/success?provider=paypal&token=…` and the app captures the order.

Local smoke (no PayPal key required):

```bash
cd server
npm run check:payments
```

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
