import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/contact_inquiry.dart';
import '../services/contact_inquiry_service.dart';
import '../services/site_settings_service.dart';

/// Opens the Contact Us / Sponsorship inquiry bottom sheet.
void openPartnershipInquiry(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ContactInquirySheet(),
  );
}

/// Landing-page footer for sponsorship and collaboration inquiries.
class PartnershipFooter extends StatelessWidget {
  const PartnershipFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final s = cms.settings.partner;
        final title = cms.text(s.title, loc.t('partner.title'));
        final subtitle = cms.text(s.subtitle, loc.t('partner.subtitle'));
        final button =
            cms.text(s.contactButton, loc.t('partner.contactButton'));
        final line = cms.text(
          s.contactLine,
          'MedGift US · ${s.contactEmail}',
        );

        return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDeepBlue,
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => openPartnershipInquiry(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryDeepBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: const Icon(Icons.handshake_outlined),
            label: Text(button),
          ),
          const SizedBox(height: 20),
          Text(
            line,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _ContactInquirySheet extends StatefulWidget {
  const _ContactInquirySheet();

  @override
  State<_ContactInquirySheet> createState() => _ContactInquirySheetState();
}

class _ContactInquirySheetState extends State<_ContactInquirySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  InquirySubject _subject = InquirySubject.sponsorship;
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    final inquiry = await ContactInquiryService.instance.submit(
      name: _nameController.text,
      email: _emailController.text,
      subject: _subject,
      message: _messageController.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (_) => _InquirySuccessDialog(inquiry: inquiry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contact Us / Sponsorship Inquiry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your message is delivered to the MedGift admin inbox and '
                'routed to ${ContactInquiryService.adminEmail}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final loc = AppLocalizations.of(context);
                  return DropdownButtonFormField<InquirySubject>(
                    initialValue: _subject,
                    decoration: InputDecoration(
                      labelText: loc.t('inquiry.subjectLabel'),
                      prefixIcon: const Icon(Icons.topic_outlined),
                    ),
                    items: InquirySubject.values
                        .map(
                          (subject) => DropdownMenuItem(
                            value: subject,
                            child: Text(locInquirySubject(loc, subject)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _subject = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).t('inquiry.messageLabel'),
                  alignLabelWithHint: true,
                  hintText:
                      AppLocalizations.of(context).t('inquiry.messageHint'),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Please write a short message (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_sending ? 'Sending...' : 'Send Message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquirySuccessDialog extends StatelessWidget {
  const _InquirySuccessDialog({required this.inquiry});

  final ContactInquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 36,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Thank You',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thank you, ${inquiry.name}. Your '
                '${inquiry.subject.label.toLowerCase()} inquiry has been '
                'delivered to our admin team by email and saved in the '
                'Admin Inquiries inbox.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      inquiry.id,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryDeepBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confirmation reference',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      inquiry.emailDeliveryNote ??
                          'Notification sent to ${inquiry.routedToEmail}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We typically respond within 2 business days.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).t('partner.backHome')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
