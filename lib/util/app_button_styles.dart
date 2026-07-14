import 'package:flutter/material.dart';

class AppButtonStyles {
  AppButtonStyles._();

  static const double _radius = 10;

  static ButtonStyle filled(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  static ButtonStyle outlined(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  static ButtonStyle destructive(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE53935),
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  static ButtonStyle destructiveOutlined(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE53935),
      side: const BorderSide(color: Color(0xFFE53935)),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle primaryFullWidth(BuildContext context) {
    return filled(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }

  static ButtonStyle compact(BuildContext context) {
    return filled(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ButtonStyle outlinedCompact(BuildContext context) {
    return outlined(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ButtonStyle textLink(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
