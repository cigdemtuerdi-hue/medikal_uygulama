import '../l10n/app_localizations.dart';

enum AiSupportTopic {
  request,
  donate,
  reservation,
  shipping,
  esg,
  complaint,
  navigate,
  general,
}

/// Empathic, multilingual MedGift AI Support — rule-based Instant replies for demo.
class AiSupportAgentService {
  AiSupportAgentService._();

  static final AiSupportAgentService instance = AiSupportAgentService._();

  /// Detects topic from EN/ES (and common) keywords, then returns a localized reply.
  String reply({
    required String userMessage,
    required AppLocalizations loc,
  }) {
    final topic = detectTopic(userMessage);
    return switch (topic) {
      AiSupportTopic.request => loc.t('aiSupport.reply.request'),
      AiSupportTopic.donate => loc.t('aiSupport.reply.donate'),
      AiSupportTopic.reservation => loc.t('aiSupport.reply.reservation'),
      AiSupportTopic.shipping => loc.t('aiSupport.reply.shipping'),
      AiSupportTopic.esg => loc.t('aiSupport.reply.esg'),
      AiSupportTopic.complaint => loc.t('aiSupport.reply.complaint'),
      AiSupportTopic.navigate => loc.t('aiSupport.reply.navigate'),
      AiSupportTopic.general => loc.t('aiSupport.reply.fallback'),
    };
  }

  AiSupportTopic detectTopic(String raw) {
    final text = raw.toLowerCase().trim();

    if (_any(text, const [
      '48',
      'reservation',
      'reserve',
      'hold',
      'reserv',
      'reserva',
      'reten',
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
    ])) {
      return AiSupportTopic.esg;
    }

    if (_any(text, const [
      'complaint',
      'complain',
      'issue',
      'problem',
      'report',
      'queja',
      'reclamo',
      'problema',
      'denuncia',
    ])) {
      return AiSupportTopic.complaint;
    }

    if (_any(text, const [
      'request equipment',
      'how do i request',
      'request',
      'recipient',
      'need equipment',
      'wishlist',
      'solicitar',
      'pedir',
      'beneficiario',
      'necesito',
      'lista de deseos',
    ])) {
      return AiSupportTopic.request;
    }

    if (_any(text, const [
      'how does donation',
      'donate',
      'donation',
      'donor',
      'add item',
      'donar',
      'donación',
      'donacion',
      'donante',
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
    ])) {
      return AiSupportTopic.navigate;
    }

    return AiSupportTopic.general;
  }

  bool _any(String text, List<String> needles) {
    for (final n in needles) {
      if (text.contains(n)) return true;
    }
    return false;
  }
}
