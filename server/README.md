# MedGift US API (Node / Express)

Auth & supporting APIs for [medgift.us](https://medgift.us).

## Prerequisites

- Node.js 18+
- MongoDB running locally (or a MongoDB Atlas URI)
- SMTP credentials for sending from `info@medgift.us`

## Setup

```bash
cd server
cp .env.example .env
# Edit .env — fill EMAIL_* and MONGODB_URI
npm install
npm run dev
```

Health check: `GET http://localhost:3001/api/health`

## Forgot / reset password

### `POST /api/auth/forgot-password`

Body: `{ "email": "user@example.com" }`

- Issues a one-hour reset token (SHA-256 stored in DB; raw token only in the email link).
- Emails a branded HTML message from `info@medgift.us` (CTA **Şifremi Sıfırla**).
- **Anti-enumeration:** well-formed emails always get the same success message, whether or not the account exists.
- Rate limit: **5 req / 15 min / IP**.

### `POST /api/auth/reset-password/:token`

Body: `{ "newPassword": "newSecurePass1" }`

- Hashes `:token` with SHA-256 and requires `resetPasswordExpires > Date.now()`.
- Hashes `newPassword` with **bcrypt** (12 rounds) into `passwordHash`.
- Clears `resetPasswordToken` + `resetPasswordExpires` (one-time use).
- Invalid/expired token → `400` with `"Sıfırlama bağlantısının süresi dolmuş veya geçersiz."`
- Rate limit: **10 req / 15 min / IP**.

```bash
curl -X POST http://localhost:3001/api/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"donor@medgift.us"}'

curl -X POST http://localhost:3001/api/auth/reset-password/<raw-token-from-email> \
  -H 'Content-Type: application/json' \
  -d '{"newPassword":"newSecurePass1"}'
```

Forgot success (200) — same body for known and unknown emails:

```json
{
  "success": true,
  "message": "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi."
}
```

Reset invalid/expired (400):

```json
{
  "success": false,
  "message": "Sıfırlama bağlantısının süresi dolmuş veya geçersiz.",
  "code": "RESET_TOKEN_INVALID"
}
```

Rate limited (429):

```json
{
  "success": false,
  "message": "Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.",
  "code": "RATE_LIMITED"
}
```

Flutter UI routes (path URL strategy on web):

- `/forgot-password`
- `/reset-password/:token`

Reset link shape: `https://medgift.us/reset-password/{token}`

## User schema (auth fields)

| Field | Type | Notes |
|-------|------|--------|
| `passwordHash` | String | bcrypt hash (`select: false`) |
| `resetPasswordToken` | String | SHA-256 of the emailed token |
| `resetPasswordExpires` | Date | `now + 1 hour` |

## Env

| Variable | Purpose |
|----------|---------|
| `PORT` | API port (default `3001`) |
| `MONGODB_URI` | Mongo connection string |
| `APP_ORIGIN` | Public web origin for reset URLs |
| `FROM_EMAIL` | Envelope From (default `info@medgift.us`) |
| `EMAIL_HOST` | SMTP host |
| `EMAIL_PORT` | SMTP port (`587` STARTTLS or `465` SSL) |
| `EMAIL_SECURE` | `true` for port 465 |
| `EMAIL_USER` / `EMAIL_PASS` | SMTP auth |
| `SEED_DEMO_USER_EMAIL` | Optional demo user on boot |
