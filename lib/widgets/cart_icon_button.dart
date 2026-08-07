import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../services/cart_service.dart';

/// App-bar / shortcut control that opens Sepetim with a live badge count.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    CartService.instance.ensureLoaded();
    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.count;
        return IconButton(
          tooltip: loc.t('cart.appBarTitle'),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 9 ? '9+' : '$count'),
            child: Icon(Icons.shopping_cart_outlined, color: iconColor),
          ),
        );
      },
    );
  }
}
