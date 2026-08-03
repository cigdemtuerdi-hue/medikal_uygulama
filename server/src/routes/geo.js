const express = require('express');

const router = express.Router();

/**
 * GET /api/geo/zip/:zip
 * Public ZIP → city/state lookup. Proxies Zippopotam so the Flutter web app
 * does not depend on third-party CORS / ad-blockers from the browser.
 */
router.get('/zip/:zip', async (req, res) => {
  const zip = String(req.params.zip || '').trim();
  if (!/^\d{5}$/.test(zip)) {
    return res.status(400).json({
      success: false,
      message: 'ZIP must be 5 digits.',
      code: 'ZIP_INVALID',
    });
  }

  try {
    const upstream = await fetch(`https://api.zippopotam.us/us/${zip}`, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(6000),
    });
    if (upstream.status === 404) {
      return res.status(404).json({
        success: false,
        message: 'ZIP not found.',
        code: 'ZIP_NOT_FOUND',
      });
    }
    if (!upstream.ok) {
      return res.status(502).json({
        success: false,
        message: 'ZIP lookup unavailable.',
        code: 'ZIP_UPSTREAM',
      });
    }

    const data = await upstream.json();
    const place = Array.isArray(data.places) ? data.places[0] : null;
    const city = String(place?.['place name'] || '').trim();
    const state = String(place?.['state abbreviation'] || '').trim();
    const lat = Number(place?.latitude);
    const lng = Number(place?.longitude);
    if (!city || !state) {
      return res.status(404).json({
        success: false,
        message: 'ZIP not found.',
        code: 'ZIP_NOT_FOUND',
      });
    }

    return res.status(200).json({
      success: true,
      zip,
      city,
      state,
      country: 'US',
      lat: Number.isFinite(lat) ? lat : null,
      lng: Number.isFinite(lng) ? lng : null,
      label: `${city}, ${state} ${zip}`,
    });
  } catch (err) {
    console.error('[geo] zip lookup failed:', err.message);
    return res.status(502).json({
      success: false,
      message: 'ZIP lookup unavailable.',
      code: 'ZIP_UPSTREAM',
    });
  }
});

module.exports = router;
