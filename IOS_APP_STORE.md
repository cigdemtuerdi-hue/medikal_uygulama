# MedGift iOS → App Store

Bundle ID: `us.medgift.app`  
Display name: **MedGift**  
Version: see `pubspec.yaml` (`1.0.0+2`)

## Apple Developer / D-U-N-S contact (important)

Company email used for Apple Developer Program enrollment and D-U-N-S:

- **`info@medgift.com`**

Watch this inbox (and spam) for Dun & Bradstreet + Apple enrollment mail.  
Do not mix with `info@medgift.us` for this Apple account unless Apple asks to update it.

## Blocker on this Mac (right now)

Full **Xcode** is not installed — only Command Line Tools. App Store archive/upload needs Xcode.

1. Install **Xcode** from the Mac App Store (large download).
2. Then run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods   # if flutter doctor still asks for CocoaPods
flutter doctor
```

3. You also need an **Apple Developer Program** membership ($99/year):  
   https://developer.apple.com/programs/

## One-time App Store Connect setup

1. https://appstoreconnect.apple.com → **My Apps** → **+** → New App  
   - Platform: iOS  
   - Name: MedGift  
   - Bundle ID: `us.medgift.app` (create the ID in Certificates, Identifiers & Profiles if missing)  
   - SKU: `medgift-us`  
   - Primary language: English (U.S.)
2. Privacy Policy URL: `https://medgift.us/privacy-policy`
3. Support URL: `https://medgift.us`
4. Category: Medical / Lifestyle (pick the closest fit)
5. Age rating questionnaire (no unrestricted web / gambling / etc.)
6. App Privacy nutrition labels (email, photos/files for app functionality — no tracking)

## Screenshots (required)

Prepare iPhone screenshots (at least 6.7" and 6.5" sizes Apple lists). Capture from Simulator after Xcode is installed:

```bash
open -a Simulator
flutter run -d "iPhone 16 Pro" \
  --dart-define=API_BASE_URL=https://medgift-us-api.onrender.com
```

## Build & upload

```bash
cd /Users/cigdem/Desktop/DEVELOPMENT/medikal_uygulama

# Brand icons (optional refresh)
flutter test test/generate_brand_icons_test.dart

# Release IPA → App Store Connect
flutter build ipa \
  --release \
  --dart-define=API_BASE_URL=https://medgift-us-api.onrender.com \
  --export-options-plist=ios/ExportOptions.plist
```

Then either:

- Open `build/ios/archive/Runner.xcarchive` in Xcode → **Distribute App** → App Store Connect, or  
- Use Transporter / `xcrun altool` with the generated IPA under `build/ios/ipa/`.

In Xcode before first archive: open `ios/Runner.xcworkspace` (or `.xcodeproj`), select **Runner** → **Signing & Capabilities** → Team = your Apple Developer team (Automatic signing).

## Google Maps (iOS)

Cloud Console → credentials → API key restrictions → add iOS apps bundle ID `us.medgift.app`.  
Enable **Maps SDK for iOS**.

## After upload

App Store Connect → your build → **TestFlight** (internal) → then submit for **App Review**.
