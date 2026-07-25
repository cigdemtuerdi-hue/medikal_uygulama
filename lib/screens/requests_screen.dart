import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../services/donation_service.dart';
import '../services/urgent_need_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/request_tracking_card.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  RequestStatus? _filter;

  @override
  void initState() {
    super.initState();
    UrgentNeedService.instance.refreshExpirations();
  }

  List<OrganizationRequest> get _filteredRequests {
    UrgentNeedService.instance.refreshExpirations();
    final requests = DonationService.openRequests;
    final filtered = _filter == null
        ? requests
        : requests.where((r) => r.status == _filter);
    return UrgentNeedService.instance.sortedPartnerRequests(filtered);
  }

  int _countFor(RequestStatus? status) {
    if (status == null) return DonationService.openRequests.length;
    return DonationService.openRequests.where((r) => r.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pending = _countFor(RequestStatus.pending);
    final shipped = _countFor(RequestStatus.shipped);
    final delivered = _countFor(RequestStatus.delivered);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('requests.appBarTitle')),
        actions: [
          IconButton(
            onPressed: () => setState(() => _filter = null),
            icon: const Icon(Icons.refresh),
            tooltip: loc.t('common.refresh'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: loc.t('requests.sectionTitle'),
              subtitle: loc.t('requests.sectionSubtitle'),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final children = [
                  _StatusSummaryCard(
                    label: loc.t('requests.statusPending'),
                    count: pending,
                    color: Colors.orange.shade700,
                    icon: Icons.hourglass_top_outlined,
                    isSelected: _filter == RequestStatus.pending,
                    onTap: () => setState(() {
                      _filter = _filter == RequestStatus.pending ? null : RequestStatus.pending;
                    }),
                  ),
                  _StatusSummaryCard(
                    label: loc.t('requests.statusShipped'),
                    count: shipped,
                    color: AppTheme.primaryBlue,
                    icon: Icons.local_shipping_outlined,
                    isSelected: _filter == RequestStatus.shipped,
                    onTap: () => setState(() {
                      _filter = _filter == RequestStatus.shipped ? null : RequestStatus.shipped;
                    }),
                  ),
                  _StatusSummaryCard(
                    label: loc.t('requests.statusDelivered'),
                    count: delivered,
                    color: AppTheme.accentTeal,
                    icon: Icons.check_circle_outline,
                    isSelected: _filter == RequestStatus.delivered,
                    onTap: () => setState(() {
                      _filter = _filter == RequestStatus.delivered ? null : RequestStatus.delivered;
                    }),
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        Expanded(child: children[i]),
                        if (i < children.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i < children.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  _filter == null
                      ? loc.t('requests.allRequests', {
                          'count': _filteredRequests.length,
                        })
                      : loc.t('requests.filteredTitle', {
                          'status': locRequestStatus(loc, _filter!),
                          'count': _filteredRequests.length,
                        }),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_filter != null)
                  TextButton(
                    onPressed: () => setState(() => _filter = null),
                    child: Text(loc.t('requests.clearFilter')),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_filteredRequests.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      loc.t('requests.empty'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              )
            else
              ..._filteredRequests.map(
                (request) => RequestTrackingCard(request: request),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
