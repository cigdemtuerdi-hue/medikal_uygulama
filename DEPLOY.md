# MedGift US — Web canlı yayın rehberi

`flutter build web` çıktısı: `build/web` (~43 MB). Aşağıda üç seçenek var; **en hızlısı GitHub Pages**.

## 0) Yerelde derleme (hazır)

```bash
cd /Users/cigdem/Desktop/DEVELOPMENT/medikal_uygulama
flutter build web --release
```

Önizleme:

```bash
cd build/web && python3 -m http.server 8080
# → http://localhost:8080
```

veya:

```bash
./scripts/deploy_web.sh build
```

## 1) GitHub Pages (önerilen — ekstra hesap yok)

Repo zaten GitHub’da: `cigdemtuerdi-hue/medikal_uygulama`

1. GitHub → **Settings → Pages → Build and deployment → Source: GitHub Actions**
2. **Settings → Secrets and variables → Actions** altına ekleyin:
   - `GOOGLE_MAPS_API_KEY` (zorunlu haritalar için)
   - `ADMIN_NOTIFY_EMAIL` (opsiyonel)
   - `ADMIN_EMAIL_ENDPOINT` (opsiyonel)
   - `ADMIN_PIN` (opsiyonel)
3. `main` / `master` branch’e push edin veya **Actions → Deploy Web → Run workflow**
4. Yayın adresi:
   - `https://cigdemtuerdi-hue.github.io/medikal_uygulama/`

> Workflow `--base-href /medikal_uygulama/` kullanır (proje sayfası için zorunlu).

Google Cloud Console’da Maps API anahtarını HTTP referrer ile kısıtlayın:
`https://cigdemtuerdi-hue.github.io/*`

Ayrıca `web/index.html` içindeki Maps script `key=` değerini aynı anahtarla güncel tutun.

## 2) Firebase Hosting (özel domain için iyi)

```bash
npm i -g firebase-tools
firebase login
firebase projects:create medgift-us   # veya mevcut proje id
# .firebaserc içindeki "medgift-us"yi kendi project id’nizle değiştirin
flutter build web --release --base-href /
firebase deploy --only hosting
```

veya:

```bash
./scripts/deploy_web.sh firebase
```

CI ile: workflow’ta target = `firebase` + secret `FIREBASE_SERVICE_ACCOUNT` (Firebase service account JSON).

Canlı URL örneği: `https://medgift-us.web.app`

## 3) Vercel (statik çıktı)

Vercel Flutter derlemez; önce lokal/CI’da `build/web` üretilir.

```bash
npm i -g vercel
flutter build web --release --base-href /
vercel ./build/web --prod
```

veya:

```bash
./scripts/deploy_web.sh vercel
```

`vercel.json` SPA rewrite’ları (`/**` → `index.html`) içerir.

## Yayın öncesi kontrol listesi

- [ ] `flutter build web --release` hatasız
- [ ] Dil seçici + RTL (AR/UG) smoke test
- [ ] Maps anahtarı domain’e kısıtlı
- [ ] `.env` git’e commit edilmedi (`.gitignore`’da)
- [ ] Formspree / admin endpoint üretim değeri (isteğe bağlı)
- [ ] Custom domain (Firebase/Vercel DNS) bağlandı

## Notlar

- `build/` klasörü git’e eklenmez; CI her seferinde yeniden derler.
- `.env` asset olarak paketlenir; CI’da GitHub Secrets’tan üretilir.
- Named route’lar için Firebase/Vercel/Pages tarafında SPA rewrite şarttır (bu repoda ayarlı).
