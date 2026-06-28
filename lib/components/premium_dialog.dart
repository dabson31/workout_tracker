import 'package:flutter/material.dart';

// drop-in replacement for showDialog that adds a smoother, more premium-feeling
// entrance: a gentle fade combined with a soft scale-up (rather than the
// default Material dialog's slightly abrupt pop), and a softer barrier.
//
// Usage is identical to showDialog: showPremiumDialog(context: context,
// builder: (context) => AlertDialog(...))
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
