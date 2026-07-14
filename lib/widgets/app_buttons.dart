import 'package:flutter/material.dart';
import '../util/app_button_styles.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: AppButtonStyles.primaryFullWidth(context),
        child: child,
      ),
    );
  }
}

class AppCompactButton extends StatelessWidget {
  const AppCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.compact(context),
      child: Text(label),
    );
  }
}

class AppOutlinedDangerButton extends StatelessWidget {
  const AppOutlinedDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: AppButtonStyles.destructiveOutlined(context),
        icon: Icon(icon ?? Icons.cancel_outlined, size: 20),
        label: Text(label),
      ),
    );
  }
}
