import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'config/configure_url_strategy_stub.dart'
    if (dart.library.html) 'config/configure_url_strategy_web.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'services/emergency_mode_service.dart';
import 'services/item_lifecycle_service.dart';
import 'services/site_settings_service.dart';
import 'widgets/disaster_emergency_widgets.dart';
import 'widgets/session_idle_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppUrlStrategy();
  await dotenv.load(fileName: '.env', isOptional: true);
  await LocaleController.instance.loadSavedLocale();

  // Warm Pass-It-On demo inventory so My Received Items is ready on first open.
  // ignore: unnecessary_statements
  ItemLifecycleService.instance;
  // ignore: unnecessary_statements
  EmergencyModeService.instance;
  await SiteSettingsService.instance.ensureLoaded();

  if (!AppConfig.hasGoogleMapsApiKey) {
    debugPrint('WARNING: ${AppConfig.missingApiKeyMessage}');
  }

  runApp(const MedGiftApp());
}

class MedGiftApp extends StatelessWidget {
  const MedGiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, _) {
        return MaterialApp(
          // Must match the <title> in web/index.html: Flutter overwrites the
          // document title on boot, so a short title here would replace the
          // keyword-bearing one that search engines index after rendering.
          title: 'MedGift US — Donate & Receive Durable Medical Equipment '
              'Nationwide',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Web deep links: read Uri.base and build a single initial route.
          initialRoute: AppRoutes.initialRouteName,
          onGenerateInitialRoutes: AppRoutes.onGenerateInitialRoutes,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            final direction = LocaleController.instance.textDirection;
            return SessionIdleGuard(
              child: Directionality(
                textDirection: direction,
                child: Column(
                  children: [
                    const EmergencyResponseBanner(),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
