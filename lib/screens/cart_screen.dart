import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/checkout_launcher.dart';
import '../services/listing_api_service.dart';

/// Shopping cart ("Sepetim") — review items and pay via Stripe / PayPal.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    CartService.instance.ensureLoaded();
  }

  Future<void> _checkout() async {
    final loc = AppLocalizations.of(context);
    final cart = CartService.instance;
    if (cart.isEmpty || _checkingOut) return;

    final providers = await ListingApiService.instance.paymentProviders();
    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('cart.checkoutTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.t('cart.checkoutBody', {
                'count': '${cart.count}',
                'total': cart.totalLabel,
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
              Text(loc.t('cart.paymentUnavailable')),
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

    setState(() => _checkingOut = true);
    final result = await ListingApiService.instance.checkoutCart(
      cart.listingIds,
      provider: choice,
    );
    if (!mounted) return;
    setState(() => _checkingOut = false);

    if (result.success && result.data != null) {
      final url = result.data!;
      final uri = Uri.tryParse(url);
      if (uri == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('shop.checkoutOpenFailed'))),
        );
        return;
      }

      final opened = await openCheckoutUrl(uri);
      if (!mounted) return;

      // Keep cart until /shop/success — if the payment tab fails to open,
      // the buyer must still see their items.
      if (!opened) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(loc.t('shop.checkoutOpenFailed')),
            content: SelectableText(url),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(ctx);
                },
                child: Text(loc.t('cart.copyCheckoutLink')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.t('common.close')),
              ),
            ],
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('cart.checkoutOpenedKeep'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('cart.appBarTitle')),
      ),
      body: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cart = CartService.instance;
          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 56,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.t('cart.emptyTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.t('cart.emptyBody'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.shop),
                      child: Text(loc.t('cart.browseShop')),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartTile(
                      item: item,
                      onRemove: () => cart.remove(item.listingId),
                    );
                  },
                ),
              ),
              Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loc.t('cart.itemCount', {
                                  'count': '${cart.count}',
                                }),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              loc.t('cart.total', {
                                'total': cart.totalLabel,
                              }),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDeepBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _checkingOut ? null : _checkout,
                          child: _checkingOut
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(loc.t('cart.checkout')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final photo = item.photoPath;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: photo == null || photo.isEmpty
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.medical_services_outlined),
                      )
                    : Image.network(
                        ListingApiService.instance.photoUrlFor(photo),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.locationLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    item.priceLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDeepBlue,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: loc.t('cart.remove'),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
