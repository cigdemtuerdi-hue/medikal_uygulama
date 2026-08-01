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

### 4. A real logo file

There is no raster logo in the repo — the logo is drawn in Dart
(`lib/widgets/medgift_logo.dart`). `og:image` and the JSON-LD `logo` currently
point at `icons/Icon-512.png`. For good link previews, export a proper
**1200×630** social card and a square logo, then update both references.

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
