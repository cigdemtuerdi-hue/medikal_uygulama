const {
  createUpload,
  findUploadById,
} = require('../models/uploadStore');

/** Formats the client downscales to. GIF is excluded — animation is pointless
 *  for equipment photos and would bypass the size budget. */
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

/** Per-image ceiling. The client targets ~250 kb, so this only catches abuse
 *  or a client that skipped compression. */
const MAX_BYTES = 2 * 1024 * 1024;

/**
 * Magic-number check. `Content-Type` is attacker-controlled, so a caller could
 * label an HTML or SVG payload as `image/png` and get it served back from our
 * origin — a stored-XSS primitive. Sniffing the actual bytes closes that.
 */
function sniffImageType(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12) return null;

  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return 'image/png';
  }
  if (
    buffer.toString('ascii', 0, 4) === 'RIFF' &&
    buffer.toString('ascii', 8, 12) === 'WEBP'
  ) {
    return 'image/webp';
  }
  return null;
}

/**
 * POST /api/uploads — store one image and return the URL to reference it.
 *
 * The body is raw bytes rather than multipart or base64: base64 inflates by a
 * third and would collide with the JSON body limit, and multipart would pull in
 * a parser dependency for a single field.
 */
async function uploadImage(req, res) {
  const body = req.body;

  if (!Buffer.isBuffer(body) || body.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Görsel verisi bulunamadı.',
      code: 'EMPTY_BODY',
    });
  }

  if (body.length > MAX_BYTES) {
    return res.status(413).json({
      success: false,
      message: 'Görsel çok büyük. En fazla 2 MB yükleyebilirsiniz.',
      code: 'TOO_LARGE',
    });
  }

  const sniffed = sniffImageType(body);
  if (!sniffed || !ALLOWED_TYPES.has(sniffed)) {
    return res.status(415).json({
      success: false,
      message: 'Yalnızca JPEG, PNG veya WebP görseller yüklenebilir.',
      code: 'UNSUPPORTED_TYPE',
    });
  }

  const created = await createUpload({
    ownerUserId: String(req.user.userId),
    contentType: sniffed,
    data: body,
  });

  return res.status(201).json({
    success: true,
    id: created.id,
    url: `/api/uploads/${created.id}`,
  });
}

/**
 * GET /api/uploads/:id — serve the bytes.
 *
 * Public on purpose: listing photos are shown to counterparts who are browsing,
 * and gating them behind the session token would mean every <img> needs an
 * Authorization header. Ids are unguessable, and photos carry no PHI — the
 * owner's contact details are stripped from the listing projection separately.
 */
async function serveImage(req, res) {
  const upload = await findUploadById(req.params.id);
  if (!upload) {
    return res.status(404).json({ success: false, message: 'Görsel bulunamadı.' });
  }

  res.set('Content-Type', upload.contentType);
  // Immutable: the bytes for a given id never change, so browsers and the CDN
  // can hold on to them indefinitely.
  res.set('Cache-Control', 'public, max-age=31536000, immutable');
  res.set('Content-Disposition', 'inline');
  res.set('X-Content-Type-Options', 'nosniff');
  return res.send(upload.data);
}

module.exports = {
  uploadImage,
  serveImage,
  MAX_BYTES,
  ALLOWED_TYPES,
};
