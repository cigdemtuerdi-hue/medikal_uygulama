import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../services/admin_access_service.dart';
import '../services/contact_inquiry_service.dart';
import '../services/emergency_mode_service.dart';
import '../widgets/async_state_widgets.dart';
import 'admin_inquiries_screen.dart';

/// Owner-only admin console at `/admin`.
class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _access = AdminAccessService.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  Map<String, dynamic>? _health;

  @override
  void initState() {
    super.initState();
    _access.addListener(_onChanged);
    _emailController.text = AppConfig.adminEmail;
    if (_access.isAuthenticated) {
      _refreshHealth();
    }
  }

  @override
  void dispose() {
    _access.removeListener(_onChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_access.isAuthenticated) _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/health',
      );
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() => _health = decoded);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _health = null);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await _access.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _passwordController.clear();
      await _refreshHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_access.isAuthenticated) {
      return _AdminLoginView(
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocus: _emailFocus,
        passwordFocus: _passwordFocus,
        obscure: _obscure,
        submitting: _submitting,
        error: _access.lastError,
        onToggleObscure: () => setState(() => _obscure = !_obscure),
        onSubmit: _submit,
      );
    }

    final unread = ContactInquiryService.instance.unreadCount;
    final db = _health?['db']?.toString() ?? '—';
    final emailConfigured =
        (_health?['messaging'] is Map &&
            (_health!['messaging'] as Map)['emailConfigured'] == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedGift Admin Console'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _refreshHealth,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Lock admin panel',
            onPressed: _access.lock,
            icon: const Icon(Icons.lock_outline),
          ),
        ],
      ),
      body: ContentConstrained(
        maxWidth: 880,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              'Signed in as ${_access.email ?? AppConfig.adminEmail}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDeepBlue,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only this owner account can open the admin console. '
              'Use the tools below to control live site settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'API',
                      value: _health == null ? 'unreachable' : 'online',
                      ok: _health != null,
                    ),
                    _StatusRow(label: 'Database', value: db, ok: db == 'mongo'),
                    _StatusRow(
                      label: 'Transactional email',
                      value: emailConfigured ? 'configured' : 'not configured',
                      ok: emailConfigured,
                    ),
                    if (db == 'memory') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Warning: API is on in-memory storage. User passwords '
                        'reset when Render restarts. Connect MongoDB for permanence.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B3F00),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListenableBuilder(
                listenable: EmergencyModeService.instance,
                builder: (context, _) {
                  return SwitchListTile(
                    secondary: Icon(
                      Icons.crisis_alert,
                      color: EmergencyModeService.instance.enabled
                          ? const Color(0xFFC62828)
                          : AppTheme.mutedIcon,
                    ),
                    title: const Text('Emergency Response Mode'),
                    subtitle: const Text(
                      'Shows the red emergency banner and prioritizes relief hubs.',
                    ),
                    value: EmergencyModeService.instance.enabled,
                    onChanged: EmergencyModeService.instance.setEnabled,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.inbox_outlined),
                ),
                title: const Text('Contact / Sponsorship inbox'),
                subtitle: Text(
                  unread > 0
                      ? '$unread unread message(s)'
                      : 'Review Contact Us and partnership messages',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminInquiriesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content & code changes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Page copy, donation flows, and design updates still ship '
                      'through the MedGift codebase deploy. Use this console for '
                      'live operator controls (emergency mode + inbox).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 18,
            color: ok ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminLoginView extends StatelessWidget {
  const _AdminLoginView({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscure,
    required this.submitting,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscure;
  final bool submitting;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: SafeArea(
        child: Center(
          child: ContentConstrained(
            maxWidth: 440,
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 42,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Owner access only',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDeepBlue,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your MedGift admin email and password. '
                        'This area is not available to public users.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (error != null) ...[
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: emailController,
                        focusNode: emailFocus,
                        enabled: !submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onSubmitted: (_) => passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Admin email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        enabled: !submitting,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          labelText: 'Admin password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: obscure ? 'Show password' : 'Hide password',
                            onPressed: submitting ? null : onToggleObscure,
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: submitting ? null : onSubmit,
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enter admin console'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
