# MedGift US — SEO & Google listing

What is already shipped, and what still needs a human with account access.

## Shipped in the codebase

| Item | File |
|---|---|
| Keyword-bearing `<title>`, meta description, canonical, robots | `web/index.html` |
| Open Graph + Twitter card (link previews) | `web/index.html` |
| `Organization` + `WebSite` JSON-LD structured data | `web/index.html` |
| Crawlable text layer (headings, mission copy, contact) | `web/index.html` |
| Crawl rules, private routes excluded | `web/robots.txt` |
| Sitemap of public pages | `web/sitemap.xml` |
| PWA description, categories, locale | `web/manifest.json` |
| Runtime `<title>` matches the served one | `lib/main.dart` |

### Why there is a text layer in `index.html`

Flutter paints into a canvas, so a crawler that does not execute JavaScript sees
an empty document. The `#seo-content` block gives it real headings and copy, and
is removed once Flutter paints its first frame.

**Do not give `#seo-content` `position: fixed`.** Making it a full-screen overlay
above `<flutter-view>` stops the engine painting entirely and the app boots to a
blank page. It must stay in normal document flow.

## Still needed — requires your accounts and real business data

### 1. Verify the site in Google Search Console

1. Go to <https://search.google.com/search-console> and add property `medgift.us`.
2. Verify by DNS TXT record (the domain is on a custom CNAME, so DNS is the
   reliable method).
3. Submit `https://medgift.us/sitemap.xml`.
4. Use **URL Inspection → Test live URL** on `/` and confirm the rendered HTML
   contains the headings. This is the single best check that Google can read the
   site.

### 2. Google Business Profile

<https://business.google.com>. This is what puts the company panel on the right
side of search results. It requires data that is **not** in the codebase:

- Legal entity name and state of registration (codebase says `MedGift LLC`)
- A physical address, or a declared service area if you operate without a
  storefront
- A phone number
- Business category (suggested: *Medical equipment supplier* or *Charity*)
- Opening hours

### 3. Fill the gaps in structured data

`web/index.html` currently omits fields that would otherwise be fabricated. Once
you have them, add to the `Organization` JSON-LD block:

- `"telephone"`
- `"address"` (`PostalAddress` with street, city, state, ZIP)
- `"foundingDate"`
- `"sameAs"`: array of your Facebook / Instagram / LinkedIn / X / YouTube URLs

### 4. Brand icons — done, but regenerate after any logo change

The favicon, PWA icons, iOS app icons and the 1200×630 social card all used to
be Flutter's default logo, which meant a competitor-neutral blue "F" showed in
the address bar, on the home screen and in every shared link.

The logo only exists as Dart `CustomPaint` (`lib/widgets/medgift_logo.dart`), so
the rasters are exported from the widget itself rather than redrawn by hand:

```
flutter test test/generate_brand_icons_test.dart
```

That writes `web/favicon.png`, `web/icons/Icon-{192,512}.png`,
`web/icons/Icon-maskable-{192,512}.png`, `web/icons/social-card.png` and the
full `ios/Runner/Assets.xcassets/AppIcon.appiconset` set. **Re-run it whenever
the logo painter changes**, otherwise the shipped icons silently drift from the
in-app mark.

Two constraints are baked into the generator: iOS icons are re-encoded without
an alpha channel (App Store Connect rejects them otherwise), and maskable icons
inset the mark so Android's circular crop does not cut it.

### 5. Known limitation: no per-language URLs

Seven locales are supported, but language is chosen client-side and stored in
local preferences — every language serves from the same URL. `hreflang` tags need
distinct crawlable URLs per language (`/es/`, `/tr/`, …), so they are
deliberately not present yet. Adding locale-prefixed routing is a prerequisite.

### 6. Accuracy warning

MedGift LLC is **not** a 501(c)(3). The 501(c)(3) wording throughout the app
refers to the recipient nonprofits that donors give to. The structured data
therefore declares `Organization`, not `NGO`. Do not change this without
confirmed tax-exempt status — misdeclaring it is a misrepresentation to Google
and to donors.

Likewise, the home page statistics (`1,284` items, `312` organizations, `48`
states, `4,907` AI scans) are placeholder defaults, not measured values. Do not
put them in meta descriptions or structured data until they are real.
