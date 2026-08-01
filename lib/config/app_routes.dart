import 'package:flutter/material.dart';

import '../screens/admin_console_screen.dart';
import '../screens/ai_vision_screen.dart';
import '../screens/app_entry_screen.dart';
import '../screens/app_shell.dart';
import '../screens/browse_listings_screen.dart';
import '../screens/dme_donate_screen.dart';
import '../screens/exchange_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_items_screen.dart';
import '../screens/ngo_dashboard_screen.dart';
import '../screens/onboarding/role_selection_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipient_profile_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/urgent_wishlist_screen.dart';
import '../screens/wound_care_donate_screen.dart';
import '../widgets/ai_support_chat_widget.dart';
import '../widgets/hipaa_consent_widgets.dart';
import '../widgets/phi_access_gate.dart';

enum AppTab {
  home(
    route: AppRoutes.home,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  dme(
    route: AppRoutes.dme,
    label: 'DME',
    icon: Icons.accessible_outlined,
    selectedIcon: Icons.accessible,
  ),
  woundCare(
    route: AppRoutes.woundCare,
    label: 'Wound Care',
    icon: Icons.healing_outlined,
    selectedIcon: Icons.healing,
  ),
  aiScan(
    route: AppRoutes.aiScan,
    label: 'AI Scan',
    icon: Icons.document_scanner_outlined,
    selectedIcon: Icons.document_scanner,
  ),
  requests(
    route: AppRoutes.requests,
    label: 'Requests',
    icon: Icons.volunteer_activism_outlined,
    selectedIcon: Icons.volunteer_activism,
  ),
  urgentWishlist(
    route: AppRoutes.urgentWishlist,
    label: 'Urgent Wishlist',
    icon: Icons.priority_high_outlined,
    selectedIcon: Icons.priority_high,
  ),
  exchange(
    route: AppRoutes.exchange,
    label: 'Exchange',
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz,
  ),
  recipient(
    route: AppRoutes.recipient,
    label: 'Recipient',
    icon: Icons.person_pin_outlined,
    selectedIcon: Icons.person_pin,
  ),
  myItems(
    route: AppRoutes.myItems,
    label: 'My Items',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  ngoPortal(
    route: AppRoutes.ngoPortal,
    label: 'NGO Portal',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
  ),
  profile(
    route: AppRoutes.profile,
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  );

  const AppTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  int get tabIndex => AppTab.values.indexOf(this);

  static AppTab fromIndex(int index) => AppTab.values[index];

  static AppTab? fromRoute(String? route) {
    if (route == null) return null;
    for (final tab in AppTab.values) {
      if (tab.route == route) return tab;
    }
    return null;
  }

  Widget buildScreen() {
    return switch (this) {
      AppTab.home => const HomeScreen(),
      AppTab.dme => const DmeDonateScreen(),
      AppTab.woundCare => const WoundCareDonateScreen(),
      AppTab.aiScan => const AiVisionScreen(),
      AppTab.requests => const RequestsScreen(),
      AppTab.urgentWishlist => const UrgentWishlistScreen(),
      AppTab.exchange => const ExchangeScreen(),
      AppTab.recipient => const PhiAccessGate(
          child: RecipientProfileScreen(),
        ),
      AppTab.myItems => const MyItemsScreen(),
      AppTab.ngoPortal => const NgoDashboardScreen(),
      AppTab.profile => const ProfileScreen(),
    };
  }
}

class AppRoutes {
  static const entry = '/';
  static const home = '/home';
  static const dme = '/dme';
  static const woundCare = '/wound-care';
  static const aiScan = '/ai-scan';
  static const requests = '/requests';
  static const urgentWishlist = '/urgent-wishlist';
  static const exchange = '/exchange';
  static const recipient = '/recipient';
  static const myItems = '/my-items';
  static const browse = '/browse';
  static const ngoPortal = '/ngo-portal';
  static const profile = '/profile';
  static const roleSelection = '/onboarding/role';
  static const profileCreation = '/onboarding/profile';
  static const login = '/login';
  static const admin = '/admin';
  static const forgotPassword = '/forgot-password';
  static const resetPasswordPrefix = '/reset-password';
  static const hipaaPrivacyNotice = '/hipaa-privacy-notice';
  static const privacyPolicy = '/privacy-policy';

  /// Named route for reset screen when token is passed via [RouteSettings.arguments].
  static const resetPassword = '/reset-password';

  static String resetPasswordPath(String token) =>
      '$resetPasswordPrefix/${Uri.encodeComponent(token)}';

  /// Browser path for web deep links (`/forgot-password`, `/reset-password/:token`).
  static String get initialRouteName {
    final uri = Uri.base;
    final path = uri.path;
    final q = uri.queryParameters;

    // Explicit CMS entry: /admin, /admin/, ?admin=1, #/admin
    if (path == admin ||
        path == '$admin/' ||
        q['admin'] == '1' ||
        q['cms'] == '1' ||
        uri.fragment == 'admin' ||
        uri.fragment == '/admin') {
      return admin;
    }

    if (path == hipaaPrivacyNotice || path == '$hipaaPrivacyNotice/') {
      return hipaaPrivacyNotice;
    }
    if (path == privacyPolicy || path == '$privacyPolicy/') {
      return privacyPolicy;
    }

    if (path.isEmpty || path == '/') return entry;
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static Route<dynamic> _materialRoute(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  /// Single-route bootstrap so deep links are not buried under `/`.
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) {
    final raw = initialRoute.isEmpty ? entry : initialRoute;
    // Prefer live browser location (fixes GH Pages 404.html deep links).
    final live = initialRouteName;
    final candidate = (live == admin || live.startsWith('/')) ? live : raw;
    final path = Uri.tryParse(candidate)?.path ?? candidate;
    var name = path.isEmpty ? entry : path;
    if (name == '$admin/') name = admin;

    final settings = RouteSettings(name: name);
    final generated = onGenerateRoute(settings);
    if (generated != null) return [generated];

    final builder = routes[name];
    if (builder != null) {
      return [_materialRoute(settings, builder)];
    }

    return [
      _materialRoute(
        const RouteSettings(name: entry),
        routes[entry]!,
      ),
    ];
  }

  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.entry: (_) => const AppEntryScreen(),
        AppRoutes.login: (_) => const LoginHost(),
        AppRoutes.admin: (_) => const AdminConsoleScreen(),
        AppRoutes.browse: (_) =>
            const AiSupportHost(child: BrowseListingsScreen()),
        AppRoutes.roleSelection: (_) =>
            const AiSupportHost(child: RoleSelectionScreen()),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordHost(),
        AppRoutes.hipaaPrivacyNotice: (_) => const HipaaPrivacyNoticeScreen(),
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
        for (final tab in AppTab.values)
          tab.route: (_) => AiSupportHost(child: AppShell(initialTab: tab)),
      };

  /// Resolves `/reset-password/:token` deep links from email.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    if (name == admin || name == '$admin/') {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: admin),
        builder: (_) => const AdminConsoleScreen(),
      );
    }

    final resetMatch =
        RegExp(r'^/reset-password/([^/]+)/?$').firstMatch(name);
    if (resetMatch != null) {
      final token = Uri.decodeComponent(resetMatch.group(1)!);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ResetPasswordHost(token: token),
      );
    }

    // `/reset-password` with token in arguments (in-app navigation).
    if (name == AppRoutes.resetPassword) {
      final args = settings.arguments;
      final token = args is String
          ? args
          : (args is Map && args['token'] is String)
              ? args['token'] as String
              : '';
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ResetPasswordHost(token: token),
      );
    }

    return null;
  }
}
