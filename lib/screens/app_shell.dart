import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/medgift_logo.dart';

enum _BottomNavItem { home, profile, myItems }

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab});

  final AppTab? initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab?.tabIndex ?? AppTab.home.tabIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onBottomNavTap(_BottomNavItem item) {
    setState(() {
      switch (item) {
        case _BottomNavItem.home:
          _selectedIndex = AppTab.home.tabIndex;
        case _BottomNavItem.profile:
          _selectedIndex = AppTab.profile.tabIndex;
        case _BottomNavItem.myItems:
          _selectedIndex = AppTab.myItems.tabIndex;
      }
    });
  }

  int get _bottomNavIndex {
    if (_selectedIndex == AppTab.myItems.tabIndex) return 2;
    if (_selectedIndex == AppTab.profile.tabIndex) return 1;
    if (_selectedIndex == AppTab.home.tabIndex) return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width > AppBreakpoints.medium;
    final isExtended = width > AppBreakpoints.medium;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Row(
        children: [
          if (showRail)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        extended: isExtended,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onDestinationSelected,
                        groupAlignment: -1,
                        minWidth: 72,
                        leading: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: isExtended ? 12 : 0,
                          ),
                          child: Align(
                            alignment: isExtended
                                ? AlignmentDirectional.centerStart
                                : Alignment.center,
                            child: MedGiftBrand(
                              compact: !isExtended,
                              showLabel: isExtended,
                              logoSize: isExtended ? 40 : 32,
                            ),
                          ),
                        ),
                        labelType: NavigationRailLabelType.none,
                        destinations: [
                          for (final tab in AppTab.values)
                            NavigationRailDestination(
                              icon: Icon(tab.icon),
                              selectedIcon: Icon(tab.selectedIcon),
                              label: Text(loc.t('nav.${tab.name}')),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (showRail) const VerticalDivider(width: 1),
          Expanded(child: AppTab.fromIndex(_selectedIndex).buildScreen()),
        ],
      ),
      bottomNavigationBar: showRail
          ? null
          : NavigationBar(
              selectedIndex: _bottomNavIndex,
              onDestinationSelected: (index) =>
                  _onBottomNavTap(_BottomNavItem.values[index]),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: loc.t('nav.home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: loc.t('nav.profile'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: loc.t('nav.myItems'),
                ),
              ],
            ),
    );
  }
}
