import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import '../widgets/auth_form_scaffold.dart';

/// `/login` — email + password form with a clear path to forgot-password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value, AppLocalizations loc) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return loc.t('auth.emailRequired');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return loc.t('auth.emailInvalid');
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations loc) {
    if ((value ?? '').isEmpty) return loc.t('auth.passwordRequired');
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.instance.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _loading = false);
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    setState(() {
      _loading = false;
      _errorMessage = result.message;
    });
  }

  void _openForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AuthFormScaffold(
      title: loc.t('auth.loginTitle'),
      subtitle: loc.t('auth.loginSubtitle'),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                AuthStatusBanner(message: _errorMessage!, isError: true),
                const SizedBox(height: 16),
              ],
              Semantics(
                textField: true,
                label: loc.t('auth.emailLabel'),
                child: TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: InputDecoration(
                    labelText: loc.t('auth.emailLabel'),
                    hintText: loc.t('auth.emailHint'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => _validateEmail(v, loc),
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                textField: true,
                label: loc.t('auth.passwordLabel'),
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: loc.t('auth.passwordLabel'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? loc.t('auth.showPassword')
                          : loc.t('auth.hidePassword'),
                      onPressed: _loading
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => _validatePassword(v, loc),
                  onFieldSubmitted: (_) {
                    if (!_loading) _submit();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _loading ? null : _openForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(48, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    loc.t('auth.forgotPasswordLink'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.login),
                label: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(loc.t('auth.logIn')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).pushNamed(
                          AppRoutes.forgotPassword,
                        ),
                child: Text(loc.t('auth.forgotPasswordCta')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginHost extends StatelessWidget {
  const LoginHost({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiSupportHost(child: LoginScreen());
  }
}
