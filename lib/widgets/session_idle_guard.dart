import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../services/auth_session_service.dart';

/// Tracks pointer/keyboard activity and forces re-login after 15 idle minutes.
class SessionIdleGuard extends StatefulWidget {
  const SessionIdleGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionIdleGuard> createState() => _SessionIdleGuardState();
}

class _SessionIdleGuardState extends State<SessionIdleGuard>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime _lastTouchWrite = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkIdle();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIdle();
    }
  }

  Future<void> _onActivity() async {
    final session = AuthSessionService.instance;
    await session.ensureLoaded();
    if (!session.isLoggedIn) return;

    final now = DateTime.now();
    // Throttle SharedPreferences writes.
    if (now.difference(_lastTouchWrite) < const Duration(seconds: 20)) {
      return;
    }
    _lastTouchWrite = now;
    await session.touchActivity();
  }

  Future<void> _checkIdle() async {
    final expired = await AuthSessionService.instance.enforceIdleTimeout();
    if (!expired || !mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);
    nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your session expired after 15 minutes of inactivity. Please sign in again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onActivity(),
      onPointerSignal: (_) => _onActivity(),
      child: widget.child,
    );
  }
}
