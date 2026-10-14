import 'package:flutter/foundation.dart';

/// Shared auth UI state.
///
/// Verifying a password-reset code signs the user in. While [recovering] is
/// true the app keeps showing the auth screen so the user can choose a new
/// password before entering the app.
class AuthFlow {
  AuthFlow._();

  static final ValueNotifier<bool> recovering = ValueNotifier<bool>(false);
}
