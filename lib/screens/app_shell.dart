import 'package:flutter/material.dart';

import '../widgets/medgift_logo.dart';
import 'ai_vision_screen.dart';
import 'dme_donate_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'recipient_profile_screen.dart';
import 'requests_screen.dart';
import 'wound_care_donate_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _screens = const [
    HomeScreen(),
    DmeDonateScreen(),
    WoundCareDonateScreen(),
    AiVisionScreen(),
    RequestsScreen(),
    RecipientProfileScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isExtended = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExtended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            leading: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: isExtended ? 16 : 0,
              ),
              child: Align(
                alignment: isExtended ? Alignment.centerLeft : Alignment.center,
                child: MedGiftBrand(
                  compact: !isExtended,
                  showLabel: isExtended,
                  logoSize: isExtended ? 52 : 46,
                ),
              ),
            ),
            labelType: isExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.accessible_outlined),
                selectedIcon: Icon(Icons.accessible),
                label: Text('DME'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.healing_outlined),
                selectedIcon: Icon(Icons.healing),
                label: Text('Wound Care'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.document_scanner_outlined),
                selectedIcon: Icon(Icons.document_scanner),
                label: Text('AI Scan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism),
                label: Text('Requests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_pin_outlined),
                selectedIcon: Icon(Icons.person_pin),
                label: Text('Recipient'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
