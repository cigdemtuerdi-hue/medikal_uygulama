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
  const subject = 'MedGift — Set or reset your password / Şifre belirle veya sıfırla';
  const brand = 'Medgift LLC';
  const cta = 'Set / Reset Password · Şifreyi Belirle';
  const safeUrl = String(resetUrl || '').trim();

  const text = [
    `${brand}`,
    '',
    'Set or reset your MedGift password / MedGift şifrenizi belirleyin veya sıfırlayın.',
    '',
    'If you never set a password, or forgot it, use this link:',
    'Şifre hiç belirlenmediyse veya unutulduysa bu bağlantıyı kullanın:',
    safeUrl,
    '',
    'This link expires in 1 hour for security. / Bu bağlantı güvenlik nedeniyle 1 saat geçerlidir.',
    '',
    'If you did not request this, ignore this email. Your password will not change.',
    'Bu talebi siz yapmadıysanız e-postayı yok sayın. Şifreniz değişmez.',
    '',
    `— ${brand}`,
    'https://medgift.us',
    recipientEmail ? `Recipient / Alıcı: ${recipientEmail}` : '',
  ]
    .filter(Boolean)
    .join('\n');

  const html = `<!DOCTYPE html>
<html lang="en">
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
              <h1 style="margin:0 0 12px 0;font-size:20px;font-weight:600;color:#0a4f5c;">Set or reset your password</h1>
              <p style="margin:0 0 12px 0;font-size:15px;line-height:1.55;color:#334155;">
                Never set a password, or forgot it? Use the button below to create a new MedGift password.
              </p>
              <p style="margin:0 0 16px 0;font-size:15px;line-height:1.55;color:#334155;">
                Şifre hiç belirlenmediyse veya unutulduysa aşağıdaki düğmeyle yeni MedGift şifrenizi oluşturabilirsiniz.
              </p>
              <p style="margin:0 0 28px 0;font-size:14px;line-height:1.5;color:#64748b;">
                This link is valid for <strong style="color:#0a4f5c;">1 hour</strong> /
                Bu bağlantı <strong style="color:#0a4f5c;">1 saat</strong> geçerlidir.
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
                If the button does not work, paste this link into your browser /
                Düğme çalışmazsa bu bağlantıyı tarayıcınıza yapıştırın:
              </p>
              <p style="margin:0 0 24px 0;font-size:12px;line-height:1.45;word-break:break-all;">
                <a href="${safeUrl}" style="color:#0d6e6e;">${safeUrl}</a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#94a3b8;">
                If you did not request this, ignore this email. Your password will not change. /
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
