import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/listing.dart';
import '../services/listing_api_service.dart';

/// Read-only operator views for the admin console: who registered and what
/// they published. Both tabs talk to `/api/admin/*` with the admin token.

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

const _roleLabels = <String, String>{
  'donor': 'Bağışçı',
  'recipient': 'Hasta / Alıcı',
  'ngoPartner': 'STK Partneri',
};

const _statusLabels = <String, String>{
  'active': 'Yayında',
  'reserved': 'Rezerve',
  'fulfilled': 'Tamamlandı',
  'withdrawn': 'Geri çekildi',
};

/// Shared scaffolding: loading spinner, error retry, empty state, refresh.
class _AdminTabShell extends StatelessWidget {
  const _AdminTabShell({
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.emptyMessage,
    required this.onRefresh,
    required this.child,
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _CenteredNotice(
        icon: Icons.cloud_off_outlined,
        title: 'Veri alınamadı',
        message: error!,
        actionLabel: 'Tekrar dene',
        onAction: onRefresh,
      );
    }
    if (isEmpty) {
      return _CenteredNotice(
        icon: Icons.inbox_outlined,
        title: 'Kayıt yok',
        message: emptyMessage,
        actionLabel: 'Yenile',
        onAction: onRefresh,
      );
    }
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

class _CenteredNotice extends StatelessWidget {
  const _CenteredNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => onAction(),
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Lists every registered account, newest first, with a role filter.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key, required this.adminToken});

  final String? adminToken;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<AdminUser> _users = const [];
  AdminOverview? _overview;
  String? _roleFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.adminToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Admin oturumu bulunamadı. Yeniden giriş yapın.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final service = ListingApiService.instance;
    final results = await Future.wait([
      service.adminUsers(token, role: _roleFilter),
      service.adminOverview(token),
    ]);
    if (!mounted) return;

    final usersResult = results[0] as ListingApiResult<List<AdminUser>>;
    final overviewResult = results[1] as ListingApiResult<AdminOverview>;

    setState(() {
      _loading = false;
      if (usersResult.success) {
        _users = usersResult.data ?? const [];
        _overview = overviewResult.data ?? _overview;
      } else {
        _error = usersResult.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview != null) ...[
          _SummaryChips(
            entries: [
              ('toplam üye', '${overview.totalUsers}'),
              ('bağışçı', '${overview.usersByRole['donor'] ?? 0}'),
              ('hasta', '${overview.usersByRole['recipient'] ?? 0}'),
              ('STK', '${overview.usersByRole['ngoPartner'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in [
                (null, 'Tümü'),
                ('donor', 'Bağışçı'),
                ('recipient', 'Hasta'),
                ('ngoPartner', 'STK'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _roleFilter == entry.$1,
                    onSelected: (_) {
                      setState(() => _roleFilter = entry.$1);
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _AdminTabShell(
            loading: _loading,
            error: _error,
            isEmpty: _users.isEmpty,
            emptyMessage: 'Bu filtreye uyan kayıtlı kullanıcı yok.',
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _UserCard(user: _users[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = _roleLabels[user.role] ?? 'Rol seçilmemiş';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.email,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(role, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kayıt: ${_formatDate(user.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (user.phoneMasked != null)
              Text(
                'Telefon: ${user.phoneMasked}',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              user.hipaaConsentAt != null
                  ? 'HIPAA onayı: ${_formatDate(user.hipaaConsentAt)}'
                    ' (${user.hipaaConsentVersion ?? '—'})'
                  : 'HIPAA onayı yok',
              style: theme.textTheme.bodySmall?.copyWith(
                color: user.hipaaConsentAt != null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            if (!user.hasPassword)
              Text(
                'Şifre belirlenmemiş',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lists every published listing with the owner attached, filterable by kind.
class AdminListingsTab extends StatefulWidget {
  const AdminListingsTab({super.key, required this.adminToken});

  final String? adminToken;

  @override
  State<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends State<AdminListingsTab> {
  List<Listing> _listings = const [];
  String? _kindFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.adminToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Admin oturumu bulunamadı. Yeniden giriş yapın.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ListingApiService.instance.adminListings(
      token,
      kind: _kindFilter,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _listings = result.data ?? const [];
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final entry in [
              (null, 'Tümü'),
              ('offer', 'Bağış ilanları'),
              ('request', 'Hasta talepleri'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.$2),
                  selected: _kindFilter == entry.$1,
                  onSelected: (_) {
                    setState(() => _kindFilter = entry.$1);
                    _load();
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _AdminTabShell(
            loading: _loading,
            error: _error,
            isEmpty: _listings.isEmpty,
            emptyMessage: 'Henüz ilan yüklenmemiş.',
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AdminListingCard(
                listing: _listings[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminListingCard extends StatelessWidget {
  const _AdminListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kindLabel = listing.isOffer ? 'Bağış' : 'Talep';
    final kindColor =
        listing.isOffer ? AppTheme.primaryBlue : AppTheme.primaryDeepBlue;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kindColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kindLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kindColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    listing.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (listing.hidden)
                  const Icon(Icons.visibility_off_outlined, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.category} · ${_statusLabels[listing.status] ?? listing.status}'
              ' · ${listing.quantity} adet',
              style: theme.textTheme.bodySmall,
            ),
            Text(listing.locationLabel, style: theme.textTheme.bodySmall),
            Text(
              'Sahibi: ${listing.ownerEmail ?? '—'}'
              '${listing.ownerRole != null ? ' (${_roleLabels[listing.ownerRole] ?? listing.ownerRole})' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Yüklenme: ${_formatDate(listing.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (listing.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                listing.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
