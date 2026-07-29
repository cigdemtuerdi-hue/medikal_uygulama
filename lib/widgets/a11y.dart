import 'package:flutter/material.dart';

/// Small helpers for WCAG-oriented Semantics and focus behavior.
abstract final class A11y {
  /// Landmark-style container for primary page content.
  static Widget main({required Widget child, String? label}) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: child,
    );
  }

  /// Landmark-style container for primary navigation.
  static Widget navigation({required Widget child, required String label}) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: child,
    );
  }

  /// Live region for validation / status messages (aria-live equivalent).
  static Widget liveStatus({
    required String message,
    required Widget child,
  }) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: child,
    );
  }

  /// Ensures a control announces as a labeled button for screen readers.
  static Widget button({
    required String label,
    required Widget child,
    bool enabled = true,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      onTap: onTap,
      child: child,
    );
  }
}

/// Dialog wrapper that keeps focus traversal ordered inside the modal.
Future<T?> showAccessibleDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: builder(dialogContext),
      );
    },
  );
}

/// Bottom sheet with ordered focus traversal (modal dialog pattern).
Future<T?> showAccessibleModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (sheetContext) {
      return FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: builder(sheetContext),
      );
    },
  );
}
