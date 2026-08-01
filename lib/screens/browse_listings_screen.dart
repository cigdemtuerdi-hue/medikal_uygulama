import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/listing.dart';
import '../models/user_onboarding_models.dart';
import '../services/auth_session_service.dart';
import '../services/listing_api_service.dart';
import '../services/onboarding_service.dart';

/// Counterpart browse + matching surface.
///
/// Donors see patient requests, patients see donor offers. Contact details
/// never leave the server — the API strips them before this screen renders.
class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  UserRole? _role;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AuthSessionService.instance.ensureLoaded();
    final role = AuthSessionService.instance.role ??
        await OnboardingService().loadRole();
    if (!mounted) return;
    setState(() {
      _role = role;
      _bootstrapping = false;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isDonor => _role == UserRole.donor;

  String get _browseTitle =>
      _isDonor ? 'Hasta talepleri' : 'Bağış ilanları';

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final token = AuthSessionService.instance.token;
    if (token == null || token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('İlanlar')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'İlanları görmek için tekrar giriş yapmanız gerekiyor. '
                  'Oturumunuz süresi dolmuş olabilir.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Giriş yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlar & Eşleşme'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: _browseTitle),
            const Tab(text: 'İlanlarım'),
            const Tab(text: 'Eşleşmeler'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        icon: const Icon(Icons.add),
        label: Text(_isDonor ? 'Bağış ilanı' : 'Talep oluştur'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BrowseTab(isDonor: _isDonor),
          _MineTab(
            isDonor: _isDonor,
            onOpenMatches: () => _tabs.animateTo(2),
          ),
          _MatchesTab(isDonor: _isDonor),
        ],
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateListingSheet(isDonor: _isDonor),
    );
    if (created == true && mounted) {
      _tabs.animateTo(1);
      setState(() {});
    }
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

const _categories = <(String, String)>[
  ('wheelchair', 'Tekerlekli sandalye'),
  ('walker', 'Yürüteç'),
  ('hospitalBed', 'Hasta yatağı'),
  ('oxygenEquipment', 'Oksijen ekipmanı'),
  ('nebulizer', 'Nebülizatör'),
  ('commode', 'Klozet sandalyesi'),
  ('showerChair', 'Duş sandalyesi'),
  ('woundCare', 'Yara bakımı'),
  ('other', 'Diğer'),
];

const _conditions = <(String, String)>[
  ('new', 'Sıfır'),
  ('likeNew', 'Sıfır ayarında'),
  ('good', 'İyi'),
  ('fair', 'Orta'),
];

String _categoryLabel(String code) {
  for (final entry in _categories) {
    if (entry.$1 == code) return entry.$2;
  }
  return code;
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    this.trailing,
    this.onReserve,
    this.onFindMatches,
    this.onMarkFulfilled,
  });

  final Listing listing;
  final Widget? trailing;
  final VoidCallback? onReserve;
  final VoidCallback? onFindMatches;
  final VoidCallback? onMarkFulfilled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = listing.matchScore;

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
                    listing.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (score != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%$score',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDeepBlue,
                      ),
                    ),
                  ),
                if (trailing != null) ...[const SizedBox(width: 6), trailing!],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_categoryLabel(listing.category)}'
              '${listing.condition != null ? ' · ${listing.condition}' : ''}'
              '${listing.isUrgent ? ' · Acil' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            Text(listing.locationLabel, style: theme.textTheme.bodySmall),
            if (listing.sizeNote != null && listing.sizeNote!.isNotEmpty)
              Text(
                'Ölçü: ${listing.sizeNote}',
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
            if (listing.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final reason in listing.matchReasons)
                    Chip(
                      label: Text(
                        _reasonLabel(reason),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            if (onReserve != null ||
                onFindMatches != null ||
                onMarkFulfilled != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (onFindMatches != null)
                    TextButton.icon(
                      onPressed: onFindMatches,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Eşleştir'),
                    ),
                  if (onReserve != null)
                    FilledButton.tonalIcon(
                      onPressed: onReserve,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('48s rezerve et'),
                    ),
                  if (onMarkFulfilled != null)
                    FilledButton.tonalIcon(
                      onPressed: onMarkFulfilled,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Teslim edildi'),
                    ),
                ],
              ),
            ],
            if (listing.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatDate(listing.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(String reason) => switch (reason) {
        'category' => 'Aynı kategori',
        'size' => 'Ölçü uyumu',
        'sameZip' => 'Aynı posta kodu',
        'nearby' => 'Yakın bölge',
        'sameState' => 'Aynı eyalet',
        'urgent' => 'Acil talep',
        'title' => 'Başlık benzerliği',
        _ => reason,
      };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inbox_outlined,
            size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

class _BrowseTab extends StatefulWidget {
  const _BrowseTab({required this.isDonor});

  final bool isDonor;

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  List<Listing> _listings = const [];
  bool _loading = true;
  String? _error;
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ListingApiService.instance.browse(category: _category);
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

  Future<void> _reserve(Listing listing) async {
    final result = await ListingApiService.instance.reserve(listing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Tümü'),
                  selected: _category == null,
                  onSelected: (_) {
                    setState(() => _category = null);
                    _load();
                  },
                ),
              ),
              for (final entry in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _category == entry.$1,
                    onSelected: (_) {
                      setState(() => _category = entry.$1);
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            widget.isDonor
                ? 'Hasta ve STK talepleri — iletişim bilgisi paylaşılmaz. '
                    'Uygun bulduğunuz ilanı 48 saat rezerve edebilirsiniz.'
                : 'Bağışçı ilanları — iletişim bilgisi paylaşılmaz. '
                    'Uygun bulduğunuz ilanı 48 saat rezerve edebilirsiniz.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _EmptyState(message: _error!, onRetry: _load)
                    : _listings.isEmpty
                        ? _EmptyState(
                            message: 'Bu filtreye uyan ilan yok.',
                            onRetry: _load,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: _listings.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final listing = _listings[index];
                              return _ListingCard(
                                listing: listing,
                                onReserve: () => _reserve(listing),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

class _MineTab extends StatefulWidget {
  const _MineTab({required this.isDonor, required this.onOpenMatches});

  final bool isDonor;
  final VoidCallback onOpenMatches;

  @override
  State<_MineTab> createState() => _MineTabState();
}

class _MineTabState extends State<_MineTab> {
  List<Listing> _listings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ListingApiService.instance.listMine();
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

  Future<void> _markFulfilled(Listing listing) async {
    final result =
        await ListingApiService.instance.updateStatus(listing.id, 'fulfilled');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _EmptyState(message: _error!, onRetry: _load)
              : _listings.isEmpty
                  ? _EmptyState(
                      message: widget.isDonor
                          ? 'Henüz bağış ilanı yayınlamadınız. '
                              'Sağ alttaki butondan ilk ilanınızı ekleyin.'
                          : 'Henüz talep oluşturmadınız. '
                              'Sağ alttaki butondan ilk talebinizi ekleyin.',
                      onRetry: _load,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: _listings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final listing = _listings[index];
                        return _ListingCard(
                          listing: listing,
                          trailing: Text(
                            listing.status,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          onFindMatches: listing.status == 'active'
                              ? widget.onOpenMatches
                              : null,
                          onMarkFulfilled: listing.status == 'active' ||
                                  listing.status == 'reserved'
                              ? () => _markFulfilled(listing)
                              : null,
                        );
                      },
                    ),
    );
  }
}

class _MatchesTab extends StatefulWidget {
  const _MatchesTab({required this.isDonor});

  final bool isDonor;

  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab> {
  List<Listing> _mine = const [];
  List<Listing> _matches = const [];
  String? _selectedId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  Future<void> _loadMine() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ListingApiService.instance.listMine();
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final active = (result.data ?? const [])
        .where((l) => l.status == 'active')
        .toList(growable: false);
    setState(() {
      _mine = active;
      _selectedId = active.isEmpty ? null : active.first.id;
      _loading = false;
    });
    if (_selectedId != null) await _loadMatches(_selectedId!);
  }

  Future<void> _loadMatches(String listingId) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedId = listingId;
    });
    final result = await ListingApiService.instance.matchesFor(listingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _matches = result.data ?? const [];
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _reserve(Listing listing) async {
    final result = await ListingApiService.instance.reserve(listing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success && _selectedId != null) {
      await _loadMatches(_selectedId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mine.isEmpty && !_loading) {
      return _EmptyState(
        message: widget.isDonor
            ? 'Eşleşme için önce bir bağış ilanı yayınlayın.'
            : 'Eşleşme için önce bir talep oluşturun.',
        onRetry: _loadMine,
      );
    }

    return Column(
      children: [
        if (_mine.length > 1)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final listing in _mine)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(listing.title),
                      selected: _selectedId == listing.id,
                      onSelected: (_) => _loadMatches(listing.id),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _selectedId == null
                ? _loadMine()
                : _loadMatches(_selectedId!),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _EmptyState(message: _error!, onRetry: _loadMine)
                    : _matches.isEmpty
                        ? _EmptyState(
                            message:
                                'Henüz bu ilan için uygun eşleşme bulunamadı. '
                                'Karşı tarafta yeni ilanlar yayınlandıkça skor yükselir.',
                            onRetry: () => _selectedId == null
                                ? _loadMine()
                                : _loadMatches(_selectedId!),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: _matches.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final listing = _matches[index];
                              return _ListingCard(
                                listing: listing,
                                onReserve: () => _reserve(listing),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create sheet
// ---------------------------------------------------------------------------

class _CreateListingSheet extends StatefulWidget {
  const _CreateListingSheet({required this.isDonor});

  final bool isDonor;

  @override
  State<_CreateListingSheet> createState() => _CreateListingSheetState();
}

class _CreateListingSheetState extends State<_CreateListingSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sizeNote = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  String _category = _categories.first.$1;
  String? _condition = 'good';
  String _urgency = 'normal';
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sizeNote.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık zorunlu.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await ListingApiService.instance.create(
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim(),
      condition: widget.isDonor ? _condition : null,
      sizeNote: _sizeNote.text.trim().isEmpty ? null : _sizeNote.text.trim(),
      urgency: widget.isDonor ? 'normal' : _urgency,
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isDonor ? 'Bağış ilanı oluştur' : 'Talep oluştur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Karşı taraf yalnızca şehir, eyalet ve posta kodu önekini görür. '
              'E-posta ve telefon paylaşılmaz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final entry in _categories)
                  DropdownMenuItem(value: entry.$1, child: Text(entry.$2)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            if (widget.isDonor) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final entry in _conditions)
                    DropdownMenuItem(value: entry.$1, child: Text(entry.$2)),
                ],
                onChanged: (value) => setState(() => _condition = value),
              ),
            ] else ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _urgency,
                decoration: const InputDecoration(
                  labelText: 'Aciliyet',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Düşük')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('Acil')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _urgency = value);
                },
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _sizeNote,
              decoration: const InputDecoration(
                labelText: 'Ölçü / özellik (ör. 18 inch seat)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _state,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'Eyalet',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _postal,
                    decoration: const InputDecoration(
                      labelText: 'ZIP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Yayınlanıyor…' : 'Yayınla'),
            ),
          ],
        ),
      ),
    );
  }
}
