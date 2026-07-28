import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import '../widgets/auth_form_scaffold.dart';

/// `/forgot-password` — email set/reset link only.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _loading = false;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _emailSubmittedOk = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      ModalRoute.withName(AppRoutes.entry),
    );
  }

  String? _validateEmail(String? value, AppLocalizations loc) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return loc.t('auth.emailRequired');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^\s@]+$').hasMatch(email);
    if (!ok) return loc.t('auth.emailInvalid');
    return null;
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final loc = AppLocalizations.of(context);
    final result = await AuthApiService.instance.requestPasswordReset(
      email: _emailController.text,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _statusIsError = true;
        _statusMessage = result.message;
      });
      return;
    }

    setState(() {
      _loading = false;
      _emailSubmittedOk = true;
      _statusIsError = false;
      _statusMessage = loc.t('auth.forgotSuccess');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fieldsEnabled = !_loading && !_emailSubmittedOk;

    return AuthFormScaffold(
      title: loc.t('auth.forgotPasswordTitle'),
      subtitle: loc.t('auth.forgotPasswordSubtitle'),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_statusMessage != null) ...[
                AuthStatusBanner(
                  message: _statusMessage!,
                  isError: _statusIsError,
                ),
                const SizedBox(height: 16),
              ],
              Semantics(
                textField: true,
                label: loc.t('auth.emailLabel'),
                child: TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: fieldsEnabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
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
                  onFieldSubmitted: (_) {
                    if (fieldsEnabled) _submitRequest();
                  },
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: fieldsEnabled ? _submitRequest : null,
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
                    : Text(loc.t('auth.sendResetLink')),
              ),
              const SizedBox(height: 8),
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

class ForgotPasswordHost extends StatelessWidget {
  const ForgotPasswordHost({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiSupportHost(child: ForgotPasswordScreen());
  }
}
