import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../services/donation_service.dart';
import 'urgent_need_badge.dart';

class RequestTrackingCard extends StatelessWidget {
  const RequestTrackingCard({
    super.key,
    required this.request,
  });

  final OrganizationRequest request;

  Color _urgencyColor(String urgency) {
    return switch (urgency.toLowerCase()) {
      'critical' => Colors.red.shade700,
      'high' => Colors.orange.shade800,
      'medium' => AppTheme.primaryBlue,
      _ => Colors.grey.shade700,
    };
  }

  Color _statusColor(RequestStatus status) {
    return switch (status) {
      RequestStatus.pending => Colors.orange.shade700,
      RequestStatus.shipped => AppTheme.primaryBlue,
      RequestStatus.delivered => AppTheme.accentOnSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final progress = request.unitsRequested == 0
        ? 0.0
        : request.unitsFulfilled / request.unitsRequested;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _statusColor(request.status).withValues(alpha: 0.12),
                  child: Icon(
                    request.category == DonationCategory.dme
                        ? Icons.accessible
                        : Icons.healing,
                    color: _statusColor(request.status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${request.city}, ${request.state}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(request.urgency),
                  backgroundColor: _urgencyColor(request.urgency).withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: _urgencyColor(request.urgency)),
                ),
              ],
            ),
            if (request.isActivelyUrgent()) ...[
              const SizedBox(height: 10),
              UrgentNeedBadge(
                status: request.effectiveVerificationStatus(),
                showCountdownHours: request.hoursRemaining(),
              ),
            ],
            const SizedBox(height: 12),
            Text(request.itemNeeded, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: _statusColor(request.status),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.t('requestCard.unitsProgress', {
                    'fulfilled': request.unitsFulfilled,
                    'requested': request.unitsRequested,
                  }),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            RequestStatusTimeline(request: request),
          ],
        ),
      ),
    );
  }
}

class RequestStatusTimeline extends StatelessWidget {
  const RequestStatusTimeline({super.key, required this.request});

  final OrganizationRequest request;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final steps = [
      _TimelineStepData(
        status: RequestStatus.pending,
        label: locRequestStatus(loc, RequestStatus.pending),
        date: request.requestedAt,
        icon: Icons.hourglass_top_outlined,
      ),
      _TimelineStepData(
        status: RequestStatus.shipped,
        label: locRequestStatus(loc, RequestStatus.shipped),
        date: request.shippedAt,
        icon: Icons.local_shipping_outlined,
      ),
      _TimelineStepData(
        status: RequestStatus.delivered,
        label: locRequestStatus(loc, RequestStatus.delivered),
        date: request.deliveredAt,
        icon: Icons.check_circle_outline,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(child: _TimelineStep(step: steps[i], request: request)),
            if (i < steps.length - 1)
              _TimelineConnector(
                isActive: _stepIndex(request.status) > i,
              ),
          ],
        ],
      ),
    );
  }

  static int _stepIndex(RequestStatus status) {
    return switch (status) {
      RequestStatus.pending => 0,
      RequestStatus.shipped => 1,
      RequestStatus.delivered => 2,
    };
  }
}

class _TimelineStepData {
  const _TimelineStepData({
    required this.status,
    required this.label,
    required this.date,
    required this.icon,
  });

  final RequestStatus status;
  final String label;
  final DateTime? date;
  final IconData icon;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.request,
  });

  final _TimelineStepData step;
  final OrganizationRequest request;

  bool get _isCompleted {
    final current = RequestStatusTimeline._stepIndex(request.status);
    final stepIndex = RequestStatusTimeline._stepIndex(step.status);
    return current >= stepIndex;
  }

  bool get _isCurrent => request.status == step.status;

  Color _color() {
    if (_isCurrent) return AppTheme.primaryBlue;
    if (_isCompleted) return AppTheme.accentOnSurface;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCompleted || _isCurrent
                ? _color().withValues(alpha: 0.15)
                : Colors.grey.shade200,
            border: Border.all(
              color: _isCompleted || _isCurrent ? _color() : Colors.grey.shade300,
              width: _isCurrent ? 2 : 1,
            ),
          ),
          child: Icon(step.icon, size: 18, color: _color()),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: _isCurrent ? FontWeight.bold : FontWeight.normal,
                color: _isCompleted || _isCurrent ? null : Colors.grey.shade500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          step.date != null ? formatDonationDate(step.date!) : '—',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Container(
        height: 2,
        width: 24,
        color: isActive ? AppTheme.accentOnSurface : Colors.grey.shade300,
      ),
    );
  }
}
