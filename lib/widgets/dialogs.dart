import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/widgets.dart';

/// Native-feeling confirmation (iOS alert / Android dialog) that resolves to
/// true only when the user taps Delete.
Future<bool> confirmDelete(BuildContext context, String name) {
  final result = Completer<bool>();

  void finish(bool value) {
    if (!result.isCompleted) result.complete(value);
  }

  AdaptiveAlertDialog.show(
    context: context,
    title: 'Delete task?',
    message: '"$name" will be permanently removed.',
    actions: [
      AlertAction(
        title: 'Cancel',
        style: AlertActionStyle.cancel,
        onPressed: () => finish(false),
      ),
      AlertAction(
        title: 'Delete',
        style: AlertActionStyle.destructive,
        onPressed: () => finish(true),
      ),
    ],
  ).then((_) {
    // The dialog closed. If no button callback has fired shortly after (for
    // example a tap on the barrier), treat it as a cancel.
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      () => finish(false),
    );
  });

  return result.future;
}

void showError(BuildContext context, Object error) {
  AdaptiveSnackBar.show(
    context,
    message: error is String ? error : _message(error),
    type: AdaptiveSnackBarType.error,
  );
}

String _message(Object error) => error.toString().replaceFirst('Exception: ', '');
