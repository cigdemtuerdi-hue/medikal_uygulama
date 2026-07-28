import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import '../widgets/auth_form_scaffold.dart';

const int _kMinPasswordLength = 8;

enum _ForgotStep { choose, smsVerify }

/// `/forgot-password` — email link or SMS 4-digit code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  PasswordResetMethod _method = PasswordResetMethod.email;
  _ForgotStep _step = _ForgotStep.choose;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _emailSubmittedOk = false;
  String? _phoneHint;
  String? _devCode;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      ModalRoute.withName(AppRoutes.entry),
    );
  }

  String? _validateEmail(String? value, AppLocalizations loc) {
    if (_method == PasswordResetMethod.sms) return null;
    final email = value?.trim() ?? '';
    if (email.isEmpty) return loc.t('auth.emailRequired');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return loc.t('auth.emailInvalid');
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations loc) {
    if (_method != PasswordResetMethod.sms) return null;
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return loc.t('auth.phoneRequired');
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
      phone: _phoneController.text,
      method: _method,
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

    if (_method == PasswordResetMethod.sms) {
      setState(() {
        _loading = false;
        _step = _ForgotStep.smsVerify;
        _phoneHint = result.phoneHint;
        _devCode = result.devCode;
        _statusIsError = false;
        if (result.devCode != null && result.devCode!.isNotEmpty) {
          _statusMessage = loc.t('auth.smsDevCodeBanner', {
            'code': result.devCode!,
          });
          _codeController.text = result.devCode!;
        } else if (result.phoneHint != null && result.phoneHint!.isNotEmpty) {
          _statusMessage =
              loc.t('auth.smsCodeSentTo', {'phone': result.phoneHint!});
        } else {
          _statusMessage = loc.t('auth.forgotSmsSuccess');
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.requestFocus();
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

  Future<void> _submitSmsReset() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final loc = AppLocalizations.of(context);
    final result = await AuthApiService.instance.resetPasswordWithSms(
      email: _emailController.text,
      phone: _phoneController.text,
      code: _codeController.text,
      newPassword: _passwordController.text,
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
      _statusIsError = false;
      _statusMessage = loc.t('auth.resetSuccess');
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSmsStep = _step == _ForgotStep.smsVerify;

    return AuthFormScaffold(
      title: isSmsStep
          ? loc.t('auth.smsVerifyTitle')
          : loc.t('auth.forgotPasswordTitle'),
      subtitle: isSmsStep
          ? loc.t('auth.smsVerifySubtitle')
          : loc.t('auth.forgotPasswordSubtitle'),
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
              if (!isSmsStep) ...[
                Text(
                  loc.t('auth.resetMethodLabel'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
                const SizedBox(height: 8),
                _MethodCard(
                  selected: _method == PasswordResetMethod.email,
                  enabled: !_loading && !_emailSubmittedOk,
                  icon: Icons.mark_email_read_outlined,
                  title: loc.t('auth.resetMethodEmailTitle'),
                  subtitle: loc.t('auth.resetMethodEmailBody'),
                  onTap: () => setState(() => _method = PasswordResetMethod.email),
                ),
                const SizedBox(height: 10),
                _MethodCard(
                  selected: _method == PasswordResetMethod.sms,
                  enabled: !_loading && !_emailSubmittedOk,
                  icon: Icons.sms_outlined,
                  title: loc.t('auth.resetMethodSmsTitle'),
                  subtitle: loc.t('auth.resetMethodSmsBody'),
                  onTap: () => setState(() => _method = PasswordResetMethod.sms),
                ),
                const SizedBox(height: 16),
                if (_method == PasswordResetMethod.email)
                  Semantics(
                    textField: true,
                    label: loc.t('auth.emailLabel'),
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      enabled: !_loading && !_emailSubmittedOk,
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
                    ),
                  )
                else
                  Semantics(
                    textField: true,
                    label: loc.t('auth.phoneLabel'),
                    child: TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      enabled: !_loading && !_emailSubmittedOk,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        labelText: loc.t('auth.phoneLabel'),
                        hintText: loc.t('auth.phoneHint'),
                        helperText: loc.t('auth.phoneHelper'),
                        prefixIcon: const Icon(Icons.phone_iphone_outlined),
                      ),
                      validator: (v) => _validatePhone(v, loc),
                      onFieldSubmitted: (_) {
                        if (!_loading && !_emailSubmittedOk) _submitRequest();
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      (_loading || _emailSubmittedOk) ? null : _submitRequest,
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
                      : Text(
                          _method == PasswordResetMethod.sms
                              ? loc.t('auth.sendSmsCode')
                              : loc.t('auth.sendResetLink'),
                        ),
                ),
              ] else ...[
                if (_devCode == null &&
                    _phoneHint != null &&
                    _phoneHint!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      loc.t('auth.smsCodeSentTo', {'phone': _phoneHint!}),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                Semantics(
                  textField: true,
                  label: loc.t('auth.smsCodeLabel'),
                  child: TextFormField(
                    controller: _codeController,
                    focusNode: _codeFocus,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: loc.t('auth.smsCodeLabel'),
                      hintText: loc.t('auth.smsCodeHint'),
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().length != 4) {
                        return loc.t('auth.smsCodeInvalid');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  textField: true,
                  label: loc.t('auth.newPasswordLabel'),
                  child: TextFormField(
                    controller: _passwordController,
                    enabled: !_loading,
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
                    validator: (v) {
                      if ((v ?? '').length < _kMinPasswordLength) {
                        return loc.t('auth.passwordMinLength');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  textField: true,
                  label: loc.t('auth.confirmPasswordLabel'),
                  child: TextFormField(
                    controller: _confirmController,
                    enabled: !_loading,
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
                        onPressed: _loading
                            ? null
                            : () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return loc.t('auth.passwordsDoNotMatch');
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_loading) _submitSmsReset();
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submitSmsReset,
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _step = _ForgotStep.choose;
                            _codeController.clear();
                            _passwordController.clear();
                            _confirmController.clear();
                            _statusMessage = null;
                          }),
                  child: Text(loc.t('auth.changeResetMethod')),
                ),
              ],
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

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? AppTheme.primaryBlue
        : AppTheme.skyBlue.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: title,
      child: Material(
        color: selected
            ? AppTheme.skyBlue.withValues(alpha: 0.28)
            : AppTheme.cleanWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDeepBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryDeepBlue.withValues(alpha: 0.35),
                ),
              ],
            ),
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
