import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

import '../core/app_theme.dart';

/// Native-feeling confirmation (iOS alert / Android dialog) that resolves to
/// true only when the user taps Delete.
Future<bool> confirmDelete(BuildContext context, String name) => _confirm(
      context,
      title: 'Delete task?',
      message: '"$name" will be permanently removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );

/// Asks whether a task that just reached 100% should be marked completed.
Future<bool> confirmComplete(BuildContext context, String name) => _confirm(
      context,
      title: 'Mark as completed?',
      message: '"$name" is at 100%. Do you want to mark it as completed?',
      confirmLabel: 'Mark completed',
      cancelLabel: 'Not yet',
      destructive: false,
    );

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  required bool destructive,
}) async {
  final value = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return value ?? false;
}

/// Same look on every platform: dark glass card, centred text, buttons
/// split evenly across the bottom.
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final divider = AppColors.glassBorder.resolveFrom(context);

    Widget button(String text, Color color, bool value, {bool bold = false}) {
      return Expanded(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => Navigator.of(context).pop(value),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: AppColors.background.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: divider),
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: label, decoration: TextDecoration.none),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: divider),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    button(cancelLabel, label, false),
                    Container(width: 1, color: divider),
                    button(
                      confirmLabel,
                      destructive
                          ? CupertinoColors.destructiveRed
                          : AppColors.orange,
                      true,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showError(BuildContext context, Object error) {
  AdaptiveSnackBar.show(
    context,
    message: error is String ? error : _message(error),
    type: AdaptiveSnackBarType.error,
  );
}

String _message(Object error) => error.toString().replaceFirst('Exception: ', '');
