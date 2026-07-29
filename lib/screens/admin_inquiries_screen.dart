import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/contact_inquiry.dart';
import '../services/admin_access_service.dart';
import '../services/contact_inquiry_service.dart';
import '../services/donation_service.dart';

/// Admin-only inbox for Contact Us / Sponsorship messages.
class AdminInquiriesScreen extends StatefulWidget {
  const AdminInquiriesScreen({super.key});

  @override
  State<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends State<AdminInquiriesScreen> {
  final _access = AdminAccessService.instance;
  final _service = ContactInquiryService.instance;
  InquiryStatus? _filter;

  @override
  void initState() {
    super.initState();
    _access.addListener(_onChanged);
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _access.removeListener(_onChanged);
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_access.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Inquiries / Messages')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 40, color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text(
                      'Admin sign-in required',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDeepBlue,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open the Admin Console with your owner email and password '
                      'to manage inquiries.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/admin');
                      },
                      child: const Text('Go to Admin Console'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final inquiries = _service.inbox
        .where((i) => _filter == null || i.status == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Inquiries / Messages'),
        actions: [
          if (_service.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text('${_service.unreadCount} unread'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Lock admin panel',
            onPressed: () => _access.lock(),
            icon: const Icon(Icons.lock_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages arrive newest first. Email notifications go to '
                  '${AppConfig.adminNotifyEmail}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    FilterChip(
                      label: const Text('Unread'),
                      selected: _filter == InquiryStatus.unread,
                      onSelected: (_) =>
                          setState(() => _filter = InquiryStatus.unread),
                    ),
                    FilterChip(
                      label: const Text('Read'),
                      selected: _filter == InquiryStatus.read,
                      onSelected: (_) =>
                          setState(() => _filter = InquiryStatus.read),
                    ),
                    FilterChip(
                      label: const Text('Replied'),
                      selected: _filter == InquiryStatus.replied,
                      onSelected: (_) =>
                          setState(() => _filter = InquiryStatus.replied),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: inquiries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _filter == null
                                ? 'No inquiries yet'
                                : 'No ${_filter!.label.toLowerCase()} messages',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Landing-page Contact Us / Sponsorship messages '
                            'appear here in date order.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: inquiries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      return _InquiryCard(
                        inquiry: inquiry,
                        onOpen: () {
                          _service.markRead(inquiry.id);
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _InquiryDetailSheet(
                              inquiry: inquiry,
                              onMarkReplied: () =>
                                  _service.markReplied(inquiry.id),
                              onMarkUnread: () =>
                                  _service.markUnread(inquiry.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry, required this.onOpen});

  final ContactInquiry inquiry;
  final VoidCallback onOpen;

  Color _statusColor(InquiryStatus status) => switch (status) {
        InquiryStatus.unread => Colors.orange.shade800,
        InquiryStatus.read => AppTheme.primaryBlue,
        InquiryStatus.replied => Colors.green.shade700,
      };

  @override
  Widget build(BuildContext context) {
    final unread = inquiry.status == InquiryStatus.unread;

    return Card(
      color: unread ? AppTheme.skyBlue.withValues(alpha: 0.18) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(inquiry.subject.label),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(inquiry.status.label),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: _statusColor(inquiry.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor:
                        _statusColor(inquiry.status).withValues(alpha: 0.1),
                  ),
                  const Spacer(),
                  Text(
                    formatDonationDate(inquiry.submittedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                inquiry.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                    ),
              ),
              Text(inquiry.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                inquiry.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    inquiry.emailDelivered
                        ? Icons.mark_email_read_outlined
                        : Icons.mail_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inquiry.emailDeliveryNote ??
                          'Routed to ${inquiry.routedToEmail}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryDetailSheet extends StatelessWidget {
  const _InquiryDetailSheet({
    required this.inquiry,
    required this.onMarkReplied,
    required this.onMarkUnread,
  });

  final ContactInquiry inquiry;
  final VoidCallback onMarkReplied;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                inquiry.subject.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                inquiry.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(inquiry.email),
              const SizedBox(height: 4),
              Text(
                '${inquiry.id} · ${formatDonationDate(inquiry.submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(inquiry.message),
              const SizedBox(height: 16),
              Text(
                inquiry.emailDeliveryNote ??
                    'Email notification: ${inquiry.routedToEmail}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onMarkUnread();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Mark unread'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        onMarkReplied();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.reply_outlined),
                      label: const Text('Mark replied'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
