import '../l10n/app_localizations.dart';

/// Topics MeGi can solve for MedGift US users (end-to-end app outcomes).
enum AiSupportTopic {
  greeting,
  thanks,
  login,
  signup,
  password,
  request,
  donate,
  reservation,
  shipping,
  qr,
  wishlist,
  passItOn,
  exchange,
  aiScan,
  ngo,
  profile,
  hipaa,
  emergency,
  language,
  esg,
  complaint,
  navigate,
  general,
}

/// MeGi — MedGift’s human-toned support guide.
/// Rule-based topic detection + localized, conversational replies for every
/// major in-app outcome (donate, reserve, QR, password, HIPAA, NGO, …).
class AiSupportAgentService {
  AiSupportAgentService._();

  static final AiSupportAgentService instance = AiSupportAgentService._();

  static const String agentName = 'MeGi';

  /// Detects topic from multilingual keywords, returns a localized MeGi reply.
  String reply({
    required String userMessage,
    required AppLocalizations loc,
  }) {
    final topic = detectTopic(userMessage);
    return switch (topic) {
      AiSupportTopic.greeting => loc.t('aiSupport.reply.greeting'),
      AiSupportTopic.thanks => loc.t('aiSupport.reply.thanks'),
      AiSupportTopic.login => loc.t('aiSupport.reply.login'),
      AiSupportTopic.signup => loc.t('aiSupport.reply.signup'),
      AiSupportTopic.password => loc.t('aiSupport.reply.password'),
      AiSupportTopic.request => loc.t('aiSupport.reply.request'),
      AiSupportTopic.donate => loc.t('aiSupport.reply.donate'),
      AiSupportTopic.reservation => loc.t('aiSupport.reply.reservation'),
      AiSupportTopic.shipping => loc.t('aiSupport.reply.shipping'),
      AiSupportTopic.qr => loc.t('aiSupport.reply.qr'),
      AiSupportTopic.wishlist => loc.t('aiSupport.reply.wishlist'),
      AiSupportTopic.passItOn => loc.t('aiSupport.reply.passItOn'),
      AiSupportTopic.exchange => loc.t('aiSupport.reply.exchange'),
      AiSupportTopic.aiScan => loc.t('aiSupport.reply.aiScan'),
      AiSupportTopic.ngo => loc.t('aiSupport.reply.ngo'),
      AiSupportTopic.profile => loc.t('aiSupport.reply.profile'),
      AiSupportTopic.hipaa => loc.t('aiSupport.reply.hipaa'),
      AiSupportTopic.emergency => loc.t('aiSupport.reply.emergency'),
      AiSupportTopic.language => loc.t('aiSupport.reply.language'),
      AiSupportTopic.esg => loc.t('aiSupport.reply.esg'),
      AiSupportTopic.complaint => loc.t('aiSupport.reply.complaint'),
      AiSupportTopic.navigate => loc.t('aiSupport.reply.navigate'),
      AiSupportTopic.general => loc.t('aiSupport.reply.fallback'),
    };
  }

  /// Human-like typing delay based on reply length (ms).
  int typingDelayMs(String reply) {
    final base = 720;
    final perChar = (reply.length * 16).clamp(280, 2400);
    return base + perChar;
  }

  AiSupportTopic detectTopic(String raw) {
    final text = raw.toLowerCase().trim();
    if (text.isEmpty) return AiSupportTopic.general;

    // Short social openers first.
    if (_isGreeting(text)) return AiSupportTopic.greeting;
    if (_isThanks(text)) return AiSupportTopic.thanks;

    // Specific outcomes before broad keywords.
    if (_any(text, const [
      'forgot password',
      'reset password',
      'password reset',
      'şifre',
      'sifre',
      'contraseña',
      'reestablecer',
      'reset link',
      'email not received',
      'mail gelmedi',
      'token',
    ])) {
      return AiSupportTopic.password;
    }

    if (_any(text, const [
      'log in',
      'login',
      'sign in',
      'can\'t log',
      'cannot log',
      'wrong password',
      'giriş',
      'giris',
      'oturum',
      'iniciar sesión',
      'iniciar sesion',
      'logged out',
      'idle',
      'timeout',
      'session',
    ])) {
      return AiSupportTopic.login;
    }

    if (_any(text, const [
      'sign up',
      'signup',
      'register',
      'create account',
      'role',
      'donor or recipient',
      'kayıt',
      'kayit',
      'üyelik',
      'uyelik',
      'rol seç',
      'registr',
      'cuenta nueva',
    ])) {
      return AiSupportTopic.signup;
    }

    if (_any(text, const [
      'hipaa',
      'privacy',
      'consent',
      'phi',
      'gizlilik',
      'onay kutusu',
      'privacy policy',
      'privacidad',
    ])) {
      return AiSupportTopic.hipaa;
    }

    if (_any(text, const [
      'disaster',
      'emergency',
      'crisis',
      'relief',
      'afet',
      'acil',
      'emergencia',
      'desastre',
    ])) {
      return AiSupportTopic.emergency;
    }

    if (_any(text, const [
      'qr',
      'label',
      'scan code',
      'delivery confirm',
      'etiket',
      'barkod',
      'confirmar entrega',
      'print label',
      'pdf',
    ])) {
      return AiSupportTopic.qr;
    }

    if (_any(text, const [
      'wishlist',
      'instant match',
      'urgent',
      'match alert',
      'istek listesi',
      'favori',
      'eşleşme',
      'eslesme',
      'lista de deseos',
      'coincidencia',
    ])) {
      return AiSupportTopic.wishlist;
    }

    if (_any(text, const [
      'pass it on',
      'pass-it-on',
      'passiton',
      'my items',
      're-list',
      'relist',
      'eşyalarım',
      'esyalarim',
      'yeniden bağış',
      'mis artículos',
      'mis articulos',
    ])) {
      return AiSupportTopic.passItOn;
    }

    if (_any(text, const [
      'exchange',
      'swap',
      'tax receipt',
      'takas',
      'makbuz',
      'intercambio',
      'recibo',
    ])) {
      return AiSupportTopic.exchange;
    }

    if (_any(text, const [
      'ai scan',
      'scan equipment',
      'camera',
      'identify',
      'tarama',
      'kamera',
      'escaneo',
      'ai-scan',
    ])) {
      return AiSupportTopic.aiScan;
    }

    if (_any(text, const [
      'ngo',
      'nonprofit',
      'non-profit',
      'ein',
      'organization',
      'stk',
      'dernek',
      'organización',
      'organizacion',
      'partner portal',
    ])) {
      return AiSupportTopic.ngo;
    }

    if (_any(text, const [
      'profile',
      'address',
      'photo',
      'edit profile',
      'profil',
      'adres',
      'fotoğraf',
      'fotografia',
      'perfil',
    ])) {
      return AiSupportTopic.profile;
    }

    if (_any(text, const [
      'language',
      'español',
      'spanish',
      'turkish',
      'türkçe',
      'turkce',
      'arabic',
      'chinese',
      'dil değiştir',
      'idioma',
    ])) {
      return AiSupportTopic.language;
    }

    if (_any(text, const [
      '48',
      'reservation',
      'reserve',
      'hold',
      'reserv',
      'reserva',
      'reten',
      'rezerv',
      'beklet',
      'already reserved',
      'expired hold',
    ])) {
      return AiSupportTopic.reservation;
    }

    if (_any(text, const [
      'ship',
      'pickup',
      'pick up',
      'delivery',
      'handoff',
      'meetup',
      'transport',
      'envío',
      'envio',
      'recogida',
      'entrega',
      'encuentro',
      'asistencia',
      'teslim',
      'kargo',
      'buluşma',
      'bulusma',
    ])) {
      return AiSupportTopic.shipping;
    }

    if (_any(text, const [
      'esg',
      'co2',
      'carbon',
      'impact',
      'environment',
      'green',
      'impacto',
      'medio ambiente',
      'sostenib',
      'etki',
      'karbon',
    ])) {
      return AiSupportTopic.esg;
    }

    if (_any(text, const [
      'complaint',
      'complain',
      'issue',
      'problem',
      'report',
      'bug',
      'error',
      'broken',
      'not working',
      'queja',
      'reclamo',
      'problema',
      'denuncia',
      'şikayet',
      'sikayet',
      'hata',
      'çalışmıyor',
      'calismiyor',
    ])) {
      return AiSupportTopic.complaint;
    }

    if (_any(text, const [
      'request equipment',
      'how do i request',
      'request',
      'recipient',
      'need equipment',
      'browse equipment',
      'solicitar',
      'pedir',
      'beneficiario',
      'necesito',
      'talep',
      'alıcı',
      'alici',
      'ekipman ara',
    ])) {
      return AiSupportTopic.request;
    }

    if (_any(text, const [
      'how does donation',
      'donate',
      'donation',
      'donor',
      'add item',
      'dme',
      'wound care',
      'wound',
      'donar',
      'donación',
      'donacion',
      'donante',
      'bağış',
      'bagis',
      'bağışçı',
      'bagisci',
      'yara bakımı',
    ])) {
      return AiSupportTopic.donate;
    }

    if (_any(text, const [
      'navigate',
      'where',
      'how do i',
      'help',
      'menu',
      'dónde',
      'donde',
      'cómo',
      'como',
      'ayuda',
      'nerede',
      'nasıl',
      'nasil',
      'yardım',
      'yardim',
      'menü',
      'menu',
    ])) {
      return AiSupportTopic.navigate;
    }

    return AiSupportTopic.general;
  }

  bool _isGreeting(String text) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'merhaba',
      'selam',
      'günaydın',
      'gunaydin',
      'hola',
      'buenos',
      'salam',
      'megi',
    ];
    if (text.length <= 24) {
      for (final g in greetings) {
        if (text == g || text.startsWith('$g ') || text.startsWith('$g!') || text.startsWith('$g,')) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isThanks(String text) {
    return _any(text, const [
      'thank',
      'thanks',
      'thx',
      'teşekkür',
      'tesekkur',
      'sağ ol',
      'sag ol',
      'gracias',
      'appreciate',
    ]);
  }

  bool _any(String text, List<String> needles) {
    for (final n in needles) {
      if (text.contains(n)) return true;
    }
    return false;
  }
}
