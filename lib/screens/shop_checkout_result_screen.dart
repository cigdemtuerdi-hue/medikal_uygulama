import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../services/listing_api_service.dart';

/// Deep-link target after Stripe Checkout (`/shop/success`, `/shop/cancel`).
class ShopCheckoutResultScreen extends StatefulWidget {
  const ShopCheckoutResultScreen({
    super.key,
    required this.success,
    this.sessionId,
    this.orderId,
  });

  final bool success;
  final String? sessionId;
  final String? orderId;

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
    if (widget.success &&
        widget.sessionId != null &&
        widget.sessionId!.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await ListingApiService.instance.orderBySession(widget.sessionId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _order = result.data;
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
