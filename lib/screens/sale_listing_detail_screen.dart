import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../services/cart_service.dart';
import '../services/checkout_launcher.dart';
import '../services/listing_api_service.dart';
import 'edit_sale_listing_sheet.dart';

/// Full-screen Shop listing details (photos, specs, buy / cart / edit).
class SaleListingDetailScreen extends StatefulWidget {
  const SaleListingDetailScreen({
    super.key,
    required this.listing,
    this.isOwner = false,
    this.onChanged,
  });

  final Listing listing;
  final bool isOwner;
  final VoidCallback? onChanged;

  @override
  State<SaleListingDetailScreen> createState() =>
      _SaleListingDetailScreenState();
}

class _SaleListingDetailScreenState extends State<SaleListingDetailScreen> {
  late Listing _listing;
  late final PageController _pageController;
  int _photoIndex = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final loc = AppLocalizations.of(context);
    final code = await CartService.instance.addListing(_listing);
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

  Future<void> _buy() async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
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
                  'title': _listing.title,
                  'price': _listing.priceLabel,
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
        final hold = await ListingApiService.instance.purchase(_listing.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hold.message)),
        );
        if (hold.success) widget.onChanged?.call();
        return;
      }

      final checkout = await ListingApiService.instance.checkout(
        _listing.id,
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
        widget.onChanged?.call();
        return;
      }

      if (checkout.code == 'STRIPE_NOT_CONFIGURED' ||
          checkout.code == 'PAYPAL_NOT_CONFIGURED' ||
          checkout.code == 'PAYMENT_NOT_CONFIGURED') {
        final hold = await ListingApiService.instance.purchase(_listing.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hold.message)),
        );
        if (hold.success) widget.onChanged?.call();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkout.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final updated = await showModalBottomSheet<Listing>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditSaleListingSheet(listing: _listing),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _listing = updated;
      _photoIndex = 0;
    });
    widget.onChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('shop.editSaved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photos = _listing.displayPhotos;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('shop.detailTitle')),
        actions: [
          if (widget.isOwner)
            IconButton(
              tooltip: loc.t('shop.editListing'),
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (photos.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (context, index) {
                    return Image.network(
                      ListingApiService.instance.photoUrlFor(photos[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                loc.t('shop.photoIndex', {
                  'current': '${_photoIndex + 1}',
                  'total': '${photos.length}',
                }),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: 16),
          ] else ...[
            AspectRatio(
              aspectRatio: 16 / 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _listing.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _listing.priceLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDeepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('shop.statusLine', {
              'status': _statusLabel(loc, _listing.status),
            }),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.category_outlined,
            label: loc.t('shop.categoryLabel'),
            value: _categoryLabel(loc, _listing.category),
          ),
          if (_listing.condition != null && _listing.condition!.isNotEmpty)
            _InfoRow(
              icon: Icons.verified_outlined,
              label: loc.t('shop.conditionLabel'),
              value: _conditionLabel(loc, _listing.condition!),
            ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: loc.t('shop.detailLocation'),
            value: _listing.locationLabel,
          ),
          if (_listing.sizeNote != null && _listing.sizeNote!.isNotEmpty)
            _InfoRow(
              icon: Icons.straighten,
              label: loc.t('shop.sizeLabel'),
              value: _listing.sizeNote!,
            ),
          if (widget.isOwner && _listing.commissionCents != null) ...[
            const SizedBox(height: 8),
            Text(
              loc.t('shop.commissionNetLine', {
                'commission': formatUsdCents(_listing.commissionCents!),
                'net': formatUsdCents(_listing.sellerNetCents ?? 0),
              }),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            loc.t('shop.descriptionLabel'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _listing.description.isEmpty
                ? loc.t('shop.detailNoDescription')
                : _listing.description,
            style: theme.textTheme.bodyLarge,
          ),
          if (widget.isOwner) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(loc.t('shop.editListing')),
            ),
          ],
        ],
      ),
      bottomNavigationBar: widget.isOwner
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _addToCart,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        label: Text(loc.t('cart.add')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _busy ? null : _buy,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(loc.t('shop.buyNow')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(AppLocalizations loc, String key) {
  if (key == 'woundCare') return loc.t('shop.category.woundCare');
  if (key == 'other') return loc.t('dme.type.other');
  final value = loc.t('dme.type.$key');
  return value == 'dme.type.$key' ? key : value;
}

String _conditionLabel(AppLocalizations loc, String key) {
  final mapped = switch (key) {
    'new' => 'new',
    'likeNew' || 'like_new' => 'likeNew',
    'good' => 'good',
    'fair' => 'fair',
    _ => key,
  };
  final value = loc.t('shop.condition.$mapped');
  return value == 'shop.condition.$mapped' ? key : value;
}

String _statusLabel(AppLocalizations loc, String status) {
  final key = 'shop.status.$status';
  final value = loc.t(key);
  return value == key ? status : value;
}
