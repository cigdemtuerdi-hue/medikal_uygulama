import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../services/cart_service.dart';
import '../services/listing_api_service.dart';

/// Deep-link target after Stripe / PayPal Checkout (`/shop/success`, `/shop/cancel`).
class ShopCheckoutResultScreen extends StatefulWidget {
  const ShopCheckoutResultScreen({
    super.key,
    required this.success,
    this.sessionId,
    this.orderId,
    this.cartCheckoutId,
    this.paypalToken,
  });

  final bool success;
  final String? sessionId;
  final String? orderId;
  final String? cartCheckoutId;

  /// PayPal returns `token=<ORDER_ID>` on the success redirect.
  final String? paypalToken;

  @override
  State<ShopCheckoutResultScreen> createState() =>
      _ShopCheckoutResultScreenState();
}

class _ShopCheckoutResultScreenState extends State<ShopCheckoutResultScreen> {
  SaleOrder? _order;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _load();
    } else {
      _releaseHolds();
    }
  }

  Future<void> _releaseHolds() async {
    final orderId = widget.orderId?.trim() ?? '';
    final cartId = widget.cartCheckoutId?.trim() ?? '';
    if (orderId.isEmpty && cartId.isEmpty) return;
    await ListingApiService.instance.cancelPendingCheckout(
      orderId: orderId.isEmpty ? null : orderId,
      cartCheckoutId: cartId.isEmpty ? null : cartId,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    ListingApiResult<SaleOrder> result;
    final paypalToken = widget.paypalToken?.trim() ?? '';
    if (paypalToken.isNotEmpty) {
      result = await ListingApiService.instance.capturePayPal(paypalToken);
    } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      result =
          await ListingApiService.instance.orderBySession(widget.sessionId!);
    } else {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _order = result.data;
        CartService.instance.clear();
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.success
              ? loc.t('shop.checkoutSuccessTitle')
              : loc.t('shop.checkoutCancelTitle'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.success
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 64,
                  color: widget.success
                      ? Colors.green.shade700
                      : AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.success
                      ? loc.t('shop.checkoutSuccessBody')
                      : loc.t('shop.checkoutCancelBody'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (_loading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                ],
                if (_order != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _order!.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t('shop.checkoutPaidAmount', {
                      'price': _order!.priceLabel,
                    }),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryDeepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_order!.isPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(loc.t('shop.checkoutPaidBadge')),
                    ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed(AppRoutes.shop),
                  child: Text(loc.t('shop.backToShop')),
                ),
                if (!widget.success) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed(AppRoutes.cart),
                    child: Text(loc.t('cart.viewCart')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
