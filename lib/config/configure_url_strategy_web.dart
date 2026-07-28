import 'package:flutter_web_plugins/url_strategy.dart';

/// Use clean paths (`/forgot-password`, `/reset-password/:token`) on web
/// so emailed reset links match the production domain shape.
void configureAppUrlStrategy() {
  usePathUrlStrategy();
}
