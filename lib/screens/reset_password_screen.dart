import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import '../widgets/auth_form_scaffold.dart';

/// Minimum password length enforced client-side (server should match).
const int kMinPasswordLength = 8;

/// `/reset-password/:token` — set a new password using the emailed token.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _completed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _hasToken => widget.token.trim().isNotEmpty;

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      ModalRoute.withName(AppRoutes.entry),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });

    final loc = AppLocalizations.of(context);

    if (!_hasToken) {
      setState(() {
        _statusIsError = true;
        _statusMessage = loc.t('auth.resetInvalidToken');
      });
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final result = await AuthApiService.instance.resetPassword(
      token: widget.token.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _loading = false;
        _completed = true;
        _statusIsError = false;
        _statusMessage = loc.t('auth.resetSuccess');
      });
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      _goToLogin();
      return;
    }

    setState(() {
      _loading = false;
      _statusIsError = true;
      _statusMessage = result.message;
    });
  }

  String? _validatePassword(String? value, AppLocalizations loc) {
    final password = value ?? '';
    if (password.length < kMinPasswordLength) {
      return loc.t('auth.passwordMinLength');
    }
    return null;
  }

  String? _validateConfirm(String? value, AppLocalizations loc) {
    if (value != _passwordController.text) {
      return loc.t('auth.passwordsDoNotMatch');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fieldsEnabled = !_loading && !_completed && _hasToken;

    return AuthFormScaffold(
      title: loc.t('auth.resetPasswordTitle'),
      subtitle: loc.t('auth.resetPasswordSubtitle'),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasToken) ...[
                AuthStatusBanner(
                  message: loc.t('auth.resetInvalidToken'),
                  isError: true,
                ),
                const SizedBox(height: 16),
              ],
              if (_statusMessage != null) ...[
                AuthStatusBanner(
                  message: _statusMessage!,
                  isError: _statusIsError,
                ),
                const SizedBox(height: 16),
              ],
              Semantics(
                textField: true,
                label: loc.t('auth.newPasswordLabel'),
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: fieldsEnabled,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: loc.t('auth.newPasswordLabel'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? loc.t('auth.showPassword')
                          : loc.t('auth.hidePassword'),
                      onPressed: fieldsEnabled
                          ? () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              )
                          : null,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => _validatePassword(v, loc),
                  onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                textField: true,
                label: loc.t('auth.confirmPasswordLabel'),
                child: TextFormField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  enabled: fieldsEnabled,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: loc.t('auth.confirmPasswordLabel'),
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirm
                          ? loc.t('auth.showPassword')
                          : loc.t('auth.hidePassword'),
                      onPressed: fieldsEnabled
                          ? () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              )
                          : null,
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => _validateConfirm(v, loc),
                  onFieldSubmitted: (_) {
                    if (fieldsEnabled) _submit();
                  },
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: fieldsEnabled ? _submit : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(loc.t('auth.saveNewPassword')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _goToLogin,
                child: Text(loc.t('auth.backToLogin')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPasswordHost extends StatelessWidget {
  const ResetPasswordHost({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return AiSupportHost(child: ResetPasswordScreen(token: token));
  }
}
