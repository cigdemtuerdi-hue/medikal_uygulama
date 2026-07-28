/**
 * Password-reset email HTML + plain-text bodies for Medgift LLC.
 *
 * Keep markup table-based and inline-styled for broad client support
 * (Gmail, Outlook, Apple Mail).
 */

/**
 * @param {{ resetUrl: string, recipientEmail?: string }} opts
 * @returns {{ subject: string, html: string, text: string }}
 */
function buildPasswordResetEmail({ resetUrl, recipientEmail }) {
  const subject = 'MedGift — Şifre Sıfırlama';
  const brand = 'Medgift LLC';
  const cta = 'Şifremi Sıfırla';
  const safeUrl = String(resetUrl || '').trim();

  const text = [
    `${brand}`,
    '',
    'Şifre sıfırlama talebinizi aldık.',
    '',
    'Hesabınızın şifresini yenilemek için aşağıdaki bağlantıyı kullanın:',
    safeUrl,
    '',
    'Bu bağlantı güvenlik nedeniyle 1 saat geçerlidir.',
    '',
    'Bu talebi siz yapmadıysanız, bu e-postayı yok sayabilirsiniz. Şifreniz değişmez.',
    '',
    `— ${brand}`,
    'https://medgift.us',
    recipientEmail ? `Alıcı: ${recipientEmail}` : '',
  ]
    .filter(Boolean)
    .join('\n');

  const html = `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f4f8;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1a2b3c;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f4f8;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background-color:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #d8e2ec;">
          <tr>
            <td style="background:linear-gradient(135deg,#0d6e6e 0%,#0a4f5c 100%);padding:28px 32px;text-align:center;">
              <div style="font-size:22px;font-weight:700;letter-spacing:0.04em;color:#ffffff;">MedGift</div>
              <div style="margin-top:6px;font-size:13px;color:#c5e8e8;">${brand}</div>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 32px 8px 32px;">
              <h1 style="margin:0 0 12px 0;font-size:20px;font-weight:600;color:#0a4f5c;">Şifre sıfırlama</h1>
              <p style="margin:0 0 16px 0;font-size:15px;line-height:1.55;color:#334155;">
                Hesabınız için bir şifre sıfırlama talebi aldık. Aşağıdaki düğmeye tıklayarak yeni şifrenizi belirleyebilirsiniz.
              </p>
              <p style="margin:0 0 28px 0;font-size:14px;line-height:1.5;color:#64748b;">
                Bu bağlantı <strong style="color:#0a4f5c;">güvenlik nedeniyle 1 saat</strong> geçerlidir.
              </p>
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto 28px auto;">
                <tr>
                  <td align="center" style="border-radius:8px;background-color:#0d6e6e;">
                    <a href="${safeUrl}" target="_blank" rel="noopener noreferrer"
                       style="display:inline-block;padding:14px 28px;font-size:15px;font-weight:600;color:#ffffff;text-decoration:none;border-radius:8px;">
                      ${cta}
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 8px 0;font-size:13px;line-height:1.5;color:#64748b;">
                Düğme çalışmazsa bu bağlantıyı tarayıcınıza yapıştırın:
              </p>
              <p style="margin:0 0 24px 0;font-size:12px;line-height:1.45;word-break:break-all;">
                <a href="${safeUrl}" style="color:#0d6e6e;">${safeUrl}</a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#94a3b8;">
                Bu talebi siz yapmadıysanız e-postayı yok sayın. Şifreniz değişmez.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px 32px;border-top:1px solid #e8eef4;">
              <p style="margin:0;font-size:12px;line-height:1.5;color:#94a3b8;text-align:center;">
                © ${new Date().getFullYear()} ${brand} ·
                <a href="https://medgift.us" style="color:#0d6e6e;text-decoration:none;">medgift.us</a>
                · info@medgift.us
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return { subject, html, text };
}

module.exports = {
  buildPasswordResetEmail,
};
