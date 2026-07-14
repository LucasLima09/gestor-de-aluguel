import 'package:flutter/material.dart';
import '../util/app_button_styles.dart';

class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: AppButtonStyles.outlined(context),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: isDestructive
                ? AppButtonStyles.destructive(context)
                : AppButtonStyles.filled(context),
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppDialogActions(
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            isDestructive: isDestructive,
            onCancel: () => Navigator.pop(dialogContext, false),
            onConfirm: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    ),
  );
}
