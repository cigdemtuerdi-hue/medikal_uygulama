import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/donation_models.dart';
import '../models/listing.dart';
import '../services/ai_vision_service.dart';
import '../services/auth_session_service.dart';
import '../services/cart_service.dart';
import '../services/checkout_launcher.dart';
import '../services/listing_api_service.dart';
import '../services/listing_photo_publish_helper.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/listing_location_fields.dart';
import '../widgets/listing_photo_picker.dart';

/// Paid equipment marketplace — browse sales, publish your own, buy via Stripe.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    CartService.instance.ensureLoaded();
    AuthSessionService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _bump() => setState(() => _reloadToken++);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final token = AuthSessionService.instance.token;
    if (token == null || token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.t('shop.appBarTitle'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 12),
                Text(
                  loc.t('shop.loginRequired'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text(loc.t('auth.logIn')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('shop.appBarTitle')),
        actions: [
          const CartIconButton(),
          // App bar (not a bottom FAB) so MeGi stays clear at bottom-right.
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => _openCreateSheet(context),
              icon: const Icon(Icons.add),
              label: Text(loc.t('shop.fabCreate')),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: loc.t('shop.tabBrowse')),
            Tab(text: loc.t('shop.tabMine')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ShopBrowseTab(key: ValueKey('shop-$_reloadToken'), onChanged: _bump),
          _ShopMineTab(key: ValueKey('mine-$_reloadToken'), onChanged: _bump),
        ],
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateSaleSheet(),
    );
    if (created == true && mounted) {
      _tabs.animateTo(1);
      _bump();
    }
  }
}

const _categoryKeys = <String>[
  'wheelchair',
  'walker',
  'hospitalBed',
  'oxygenEquipment',
  'nebulizer',
  'commode',
  'showerChair',
  'woundCare',
  'other',
];

const _conditionKeys = <String>['new', 'likeNew', 'good', 'fair'];

const _commissionRate = 0.17;

String _categoryLabel(AppLocalizations loc, String key) {
  if (key == 'woundCare') return loc.t('shop.category.woundCare');
  if (key == 'other') return loc.t('dme.type.other');
  return loc.t('dme.type.$key');
}

String _conditionLabel(AppLocalizations loc, String key) =>
    loc.t('shop.condition.$key');

String _statusLabel(AppLocalizations loc, String status) {
  final key = 'shop.status.$status';
  final value = loc.t(key);
  return value == key ? status : value;
}

// ---------------------------------------------------------------------------
// Browse
// ---------------------------------------------------------------------------

class _ShopBrowseTab extends StatefulWidget {
  const _ShopBrowseTab({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_ShopBrowseTab> createState() => _ShopBrowseTabState();
}

class _ShopBrowseTabState extends State<_ShopBrowseTab> {
  late Future<ListingApiResult<List<Listing>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ListingApiService.instance.shop();
  }

  Future<void> _reload() async {
    setState(() => _future = ListingApiService.instance.shop());
    await _future;
  }

  Future<void> _buy(Listing listing) async {
    final loc = AppLocalizations.of(context);
    final providers = await ListingApiService.instance.paymentProviders();
    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('shop.purchaseTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.t('shop.purchaseBody', {
                'title': listing.title,
                'price': listing.priceLabel,
              }),
            ),
            const SizedBox(height: 16),
            if (providers.stripe)
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'stripe'),
                icon: const Icon(Icons.credit_card),
                label: Text(loc.t('shop.payWithStripe')),
              ),
            if (providers.stripe && providers.paypal)
              const SizedBox(height: 8),
            if (providers.paypal)
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'paypal'),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(loc.t('shop.payWithPayPal')),
              ),
            if (!providers.stripe && !providers.paypal)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'hold'),
                child: Text(loc.t('shop.purchaseHold')),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('common.cancel')),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'hold') {
      final hold = await ListingApiService.instance.purchase(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hold.message)),
      );
      if (hold.success) {
        widget.onChanged();
        await _reload();
      }
      return;
    }

    final checkout = await ListingApiService.instance.checkout(
      listing.id,
      provider: choice,
    );
    if (!mounted) return;

    if (checkout.success && checkout.data != null) {
      final uri = Uri.tryParse(checkout.data!);
      if (uri == null || !(await openCheckoutUrl(uri))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('shop.checkoutOpenFailed'))),
        );
        return;
      }
      // Keep cart lines until /shop/success clears after paid checkout.
      widget.onChanged();
      await _reload();
      return;
    }

    if (checkout.code == 'STRIPE_NOT_CONFIGURED' ||
        checkout.code == 'PAYPAL_NOT_CONFIGURED' ||
        checkout.code == 'PAYMENT_NOT_CONFIGURED') {
      final hold = await ListingApiService.instance.purchase(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hold.message)),
      );
      if (hold.success) {
        widget.onChanged();
        await _reload();
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(checkout.message)),
    );
  }

  Future<void> _addToCart(Listing listing) async {
    final loc = AppLocalizations.of(context);
    final code = await CartService.instance.addListing(listing);
    if (!mounted) return;
    final message = switch (code) {
      'added' => loc.t('cart.added'),
      'duplicate' => loc.t('cart.alreadyInCart'),
      'full' => loc.t('cart.full'),
      _ => loc.t('cart.addFailed'),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: code == 'added'
            ? SnackBarAction(
                label: loc.t('cart.viewCart'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.cart),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          if (!result.success) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text(result.message)),
              ],
            );
          }
          final listings = result.data ?? const <Listing>[];
          if (listings.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text(loc.t('shop.emptyBrowse'))),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return _SaleCard(
                listing: listing,
                actionLabel: loc.t('shop.buy'),
                onAction: () => _buy(listing),
                secondaryLabel: loc.t('cart.add'),
                onSecondary: () => _addToCart(listing),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mine
// ---------------------------------------------------------------------------

class _ShopMineTab extends StatefulWidget {
  const _ShopMineTab({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_ShopMineTab> createState() => _ShopMineTabState();
}

class _ShopMineTabState extends State<_ShopMineTab> {
  late Future<ListingApiResult<List<Listing>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ListingApiService.instance.listMine();
  }

  Future<void> _reload() async {
    setState(() => _future = ListingApiService.instance.listMine());
    await _future;
  }

  Future<void> _withdraw(Listing listing) async {
    final result =
        await ListingApiService.instance.updateStatus(listing.id, 'withdrawn');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) {
      widget.onChanged();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          if (!result.success) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text(result.message)),
              ],
            );
          }
          final sales = (result.data ?? const <Listing>[])
              .where((l) => l.isSale)
              .toList(growable: false);
          if (sales.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text(loc.t('shop.emptyMine'))),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: sales.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final listing = sales[index];
              return _SaleCard(
                listing: listing,
                showCommission: true,
                actionLabel: listing.status == 'active'
                    ? loc.t('shop.withdraw')
                    : null,
                onAction: listing.status == 'active'
                    ? () => _withdraw(listing)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.listing,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.showCommission = false,
  });

  final Listing listing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showCommission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final photos = listing.displayPhotos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    ListingApiService.instance.photoUrlFor(photos.first),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  listing.priceLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_categoryLabel(loc, listing.category)} · ${listing.locationLabel}',
              style: theme.textTheme.bodySmall,
            ),
            if (listing.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                listing.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (showCommission && listing.commissionCents != null) ...[
              const SizedBox(height: 8),
              Text(
                loc.t('shop.commissionNetLine', {
                  'commission': formatUsdCents(listing.commissionCents!),
                  'net': formatUsdCents(listing.sellerNetCents ?? 0),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              loc.t('shop.statusLine', {
                'status': _statusLabel(loc, listing.status),
              }),
              style: theme.textTheme.labelMedium,
            ),
            if ((actionLabel != null && onAction != null) ||
                (secondaryLabel != null && onSecondary != null)) ...[
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (secondaryLabel != null && onSecondary != null)
                    OutlinedButton.icon(
                      onPressed: onSecondary,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: Text(secondaryLabel!),
                    ),
                  if (actionLabel != null && onAction != null)
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create sale
// ---------------------------------------------------------------------------

class _CreateSaleSheet extends StatefulWidget {
  const _CreateSaleSheet();

  @override
  State<_CreateSaleSheet> createState() => _CreateSaleSheetState();
}

class _CreateSaleSheetState extends State<_CreateSaleSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sizeNote = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _price = TextEditingController();
  final _photos = <ListingPhotoDraft>[];
  final _ai = AiVisionService();

  String _category = _categoryKeys.first;
  String? _condition = 'good';
  bool _submitting = false;
  bool _aiBusy = false;
  String? _aiHint;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sizeNote.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _price.dispose();
    super.dispose();
  }

  int? get _priceCents {
    final raw = _price.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final dollars = double.tryParse(raw);
    if (dollars == null || dollars < 1) return null;
    return (dollars * 100).round();
  }

  Future<String> _uploadPhoto(ListingPhotoDraft draft) async {
    final result = await ListingApiService.instance.uploadPhoto(
      bytes: draft.bytes,
      contentType: draft.contentType,
    );
    final path = result.data;
    if (!result.success || path == null) throw Exception(result.message);
    return path;
  }

  Future<void> _suggestWithAi() async {
    final loc = AppLocalizations.of(context);
    if (_photos.isEmpty) {
      _notify(loc.t('shop.needPhotoFirst'));
      return;
    }
    setState(() {
      _aiBusy = true;
      _aiHint = null;
    });
    try {
      final result = await _ai.analyzeImage(
        _photos.first.bytes,
        'listing-photo.jpg',
      );
      if (!mounted) return;
      setState(() {
        _title.text = [
          result.brand,
          result.model,
          result.productName,
        ].where((s) => s.trim().isNotEmpty).join(' · ');
        _category = _mapAiCategory(result);
        _condition = _mapCondition(result.suggestedCondition.name);
        _price.text = result.estimatedRetailValueUsd.toStringAsFixed(2);
        _description.text = result.recommendation;
        _aiHint = loc.t('shop.aiHint', {
          'confidence': (result.confidence * 100).round(),
          'percent': (_commissionRate * 100).round(),
        });
      });
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  String _mapAiCategory(AiVisionResult result) {
    final blob =
        '${result.category} ${result.productName} ${result.model}'.toLowerCase();
    if (blob.contains('wound') || blob.contains('dressing')) return 'woundCare';
    if (blob.contains('oxygen') || blob.contains('respir')) {
      return 'oxygenEquipment';
    }
    if (blob.contains('rollator') || blob.contains('walker')) return 'walker';
    if (blob.contains('bed')) return 'hospitalBed';
    if (blob.contains('wheel')) return 'wheelchair';
    return 'other';
  }

  String? _mapCondition(String name) {
    return switch (name) {
      'excellent' => 'likeNew',
      'fair' || 'needsRepair' || 'notDonatable' => 'fair',
      _ => 'good',
    };
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      _notify(loc.t('shop.titleRequired'));
      return;
    }
    final cents = _priceCents;
    if (cents == null) {
      _notify(loc.t('shop.priceRequired'));
      return;
    }
    if (_photos.any((p) => p.isPending)) {
      _notify(loc.t('shop.photosPending'));
      return;
    }
    if (_photos.any((p) => p.error != null)) {
      _notify(loc.t('shop.photosFailed'));
      return;
    }
    if (!ListingPhotoPublishHelper.hasUploadedPhoto(_photos)) {
      _notify(loc.t('photos.required'));
      return;
    }

    setState(() => _submitting = true);
    final result = await ListingApiService.instance.create(
      kind: 'sale',
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim(),
      condition: _condition,
      sizeNote: _sizeNote.text.trim().isEmpty ? null : _sizeNote.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
      priceCents: cents,
      photos: [
        for (final photo in _photos)
          if (photo.uploadedPath != null) photo.uploadedPath!,
      ],
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _notify(result.message);
    if (result.success) Navigator.of(context).pop(true);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cents = _priceCents;
    final commission =
        cents == null ? null : (cents * _commissionRate).round();
    final net = cents == null || commission == null ? null : cents - commission;
    final percent = (_commissionRate * 100).round();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.t('shop.createTitle'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              loc.t('shop.createSubtitle', {'percent': percent}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ListingPhotoPicker(
              photos: _photos,
              enabled: !_submitting,
              onUpload: _uploadPhoto,
              onChanged: (photos) => setState(() {
                _photos
                  ..clear()
                  ..addAll(photos);
              }),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _submitting || _aiBusy ? null : _suggestWithAi,
              icon: _aiBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _aiBusy ? loc.t('shop.aiBusy') : loc.t('shop.aiSuggest'),
              ),
            ),
            if (_aiHint != null) ...[
              const SizedBox(height: 8),
              Text(
                _aiHint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: loc.t('shop.titleLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: InputDecoration(
                labelText: loc.t('shop.categoryLabel'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final key in _categoryKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(_categoryLabel(loc, key)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _condition,
              decoration: InputDecoration(
                labelText: loc.t('shop.conditionLabel'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final key in _conditionKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(_conditionLabel(loc, key)),
                  ),
              ],
              onChanged: (value) => setState(() => _condition = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: loc.t('shop.priceLabel'),
                prefixText: r'$ ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (cents != null && commission != null && net != null) ...[
              const SizedBox(height: 10),
              _CommissionPanel(
                priceCents: cents,
                commissionCents: commission,
                netCents: net,
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _sizeNote,
              decoration: InputDecoration(
                labelText: loc.t('shop.sizeLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.t('shop.descriptionLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ListingLocationFields(
              cityController: _city,
              stateController: _state,
              postalController: _postal,
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(
                _submitting ? loc.t('shop.publishing') : loc.t('shop.publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionPanel extends StatelessWidget {
  const _CommissionPanel({
    required this.priceCents,
    required this.commissionCents,
    required this.netCents,
  });

  final int priceCents;
  final int commissionCents;
  final int netCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final percent = (_commissionRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('shop.commissionSummary'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDeepBlue,
            ),
          ),
          const SizedBox(height: 6),
          _row(loc.t('shop.salePrice'), formatUsdCents(priceCents)),
          _row(
            loc.t('shop.commissionLine', {'percent': percent}),
            formatUsdCents(commissionCents),
          ),
          const Divider(height: 14),
          _row(
            loc.t('shop.sellerNet'),
            formatUsdCents(netCents),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
