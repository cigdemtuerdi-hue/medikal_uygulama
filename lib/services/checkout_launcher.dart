import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a Stripe / PayPal hosted checkout URL.
///
/// On web, prefer navigating the current tab (`_self`) so Safari/Chrome do not
/// silently drop an "external application" launch. Falls back to a new tab,
/// then external application.
Future<bool> openCheckoutUrl(Uri uri) async {
  try {
    if (kIsWeb) {
      if (await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      )) {
        return true;
      }
      if (await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      )) {
        return true;
      }
    }

    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (err, stack) {
    debugPrint('[checkout] openCheckoutUrl failed: $err\n$stack');
    return false;
  }
}
