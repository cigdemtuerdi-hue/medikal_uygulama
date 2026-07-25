import 'package:flutter/material.dart';

import '../screens/ai_vision_screen.dart';
import '../screens/app_shell.dart';
import '../screens/auth_landing_screen.dart';
import '../screens/dme_donate_screen.dart';
import '../screens/exchange_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_items_screen.dart';
import '../screens/ngo_dashboard_screen.dart';
import '../screens/onboarding/role_selection_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipient_profile_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/urgent_wishlist_screen.dart';
import '../screens/wound_care_donate_screen.dart';
import '../widgets/ai_support_chat_widget.dart';

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
      AppTab.recipient => const RecipientProfileScreen(),
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
  static const ngoPortal = '/ngo-portal';
  static const profile = '/profile';
  static const roleSelection = '/onboarding/role';
  static const profileCreation = '/onboarding/profile';

  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.entry: (_) =>
            const AiSupportHost(child: AuthLandingScreen()),
        AppRoutes.roleSelection: (_) =>
            const AiSupportHost(child: RoleSelectionScreen()),
        for (final tab in AppTab.values)
          tab.route: (_) => AiSupportHost(child: AppShell(initialTab: tab)),
      };
}
