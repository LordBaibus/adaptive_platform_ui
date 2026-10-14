import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_icons.dart';
import '../core/app_theme.dart';
import '../services/auth_flow.dart';
import '../services/task_controller.dart';

/// Sign in, sign up, 6-digit code (OTP) verification and password reset.
/// Always shown in dark mode, whatever the system setting, so it matches the
/// dark glass + orange look of the app.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.dark),
      child: CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          brightness: Brightness.dark,
          primaryColor: AppColors.orange,
        ),
        child: const _AuthView(),
      ),
    );
  }
}

enum _Step { signIn, signUp, verifySignup, forgot, verifyRecovery, newPassword }

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  static const int _otpLength = 6;
  static const Color _white = CupertinoColors.white;
  static const TextStyle _fieldStyle = TextStyle(color: _white, fontSize: 16);

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();

  _Step _step = _Step.signIn;
  bool _busy = false;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  // ---- helpers -----------------------------------------------------------

  void _toast(String message, AdaptiveSnackBarType type, {int seconds = 4}) {
    if (!mounted) return;
    AdaptiveSnackBar.show(
      context,
      message: message,
      type: type,
      duration: Duration(seconds: seconds),
    );
  }

  /// Runs [action] with the busy flag set and shows any error as a snack bar.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast(errorMessage(e), AdaptiveSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(_Step step) {
    _code.clear();
    setState(() => _step = step);
  }

  bool get _emailOk {
    final email = _email.text.trim();
    return email.isNotEmpty && email.contains('@');
  }

  bool get _verifying =>
      _step == _Step.verifySignup || _step == _Step.verifyRecovery;

  // ---- actions -----------------------------------------------------------

  Future<void> _submitCredentials() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!_emailOk || password.length < 6) {
      _toast(
        'Enter a valid email and a password of at least 6 characters.',
        AdaptiveSnackBarType.warning,
      );
      return;
    }

    await _run(() async {
      if (_step == _Step.signIn) {
        try {
          await _auth.signInWithPassword(email: email, password: password);
        } on AuthException catch (e) {
          // Account exists but the email was never confirmed: send a new code.
          if (e.message.toLowerCase().contains('confirm')) {
            await _auth.resend(type: OtpType.signup, email: email);
            _toast('Confirm your email: we sent a $_otpLength-digit code.',
                AdaptiveSnackBarType.info);
            _go(_Step.verifySignup);
            return;
          }
          rethrow;
        }
        // On success the AuthGate swaps this screen for the home screen.
      } else {
        final response = await _auth.signUp(
          email: email,
          password: password,
          data: {'name': _name.text.trim()},
        );
        if (response.session == null) {
          _toast('We sent a $_otpLength-digit code to $email.',
              AdaptiveSnackBarType.success);
          _go(_Step.verifySignup);
        }
      }
    });
  }

  Future<void> _sendRecoveryCode() async {
    if (!_emailOk) {
      _toast('Enter the email you signed up with.', AdaptiveSnackBarType.warning);
      return;
    }
    await _run(() async {
      await _auth.resetPasswordForEmail(_email.text.trim());
      _toast('We sent a $_otpLength-digit code to ${_email.text.trim()}.',
          AdaptiveSnackBarType.success);
      _go(_Step.verifyRecovery);
    });
  }

  Future<void> _verifyCode() async {
    final token = _code.text.trim();
    if (token.length != _otpLength) {
      _toast('Enter the $_otpLength-digit code from your email.',
          AdaptiveSnackBarType.warning);
      return;
    }
    final recovery = _step == _Step.verifyRecovery;

    await _run(() async {
      // Verifying signs the user in. For a password reset, hold the auth
      // screen open until a new password is chosen.
      if (recovery) AuthFlow.recovering.value = true;
      try {
        await _auth.verifyOTP(
          email: _email.text.trim(),
          token: token,
          type: recovery ? OtpType.recovery : OtpType.signup,
        );
      } catch (_) {
        if (recovery) AuthFlow.recovering.value = false;
        _code.clear();
        rethrow;
      }
      if (recovery) _go(_Step.newPassword);
      // Sign-up: the AuthGate now shows the home screen.
    });
  }

  Future<void> _resendCode() async {
    final email = _email.text.trim();
    await _run(() async {
      if (_step == _Step.verifyRecovery) {
        await _auth.resetPasswordForEmail(email);
      } else {
        await _auth.resend(type: OtpType.signup, email: email);
      }
      _toast('A new code is on its way to $email.', AdaptiveSnackBarType.success);
    });
  }

  Future<void> _saveNewPassword() async {
    final password = _password.text;
    if (password.length < 6) {
      _toast('Use a password of at least 6 characters.', AdaptiveSnackBarType.warning);
      return;
    }
    if (password != _confirm.text) {
      _toast('The two passwords do not match.', AdaptiveSnackBarType.warning);
      return;
    }
    await _run(() async {
      await _auth.updateUser(UserAttributes(password: password));
      _toast('Password updated.', AdaptiveSnackBarType.success);
      AuthFlow.recovering.value = false; // AuthGate now shows the home screen.
    });
  }

  Future<void> _cancelRecovery() async {
    AuthFlow.recovering.value = false;
    await _auth.signOut();
    _password.clear();
    _confirm.clear();
    _go(_Step.signIn);
  }

  // ---- UI ----------------------------------------------------------------

  /// Text input using the library's own field: white text, the field's built-in
  /// placeholder and a leading icon. No extra box is drawn around it.
  Widget _input({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    bool centered = false,
    bool autofocus = false,
    int? maxLength,
    TextInputType? keyboardType,
    TextInputAction? action,
    TextCapitalization capitalization = TextCapitalization.none,
    TextStyle style = _fieldStyle,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return AdaptiveTextField(
      controller: controller,
      placeholder: hint,
      style: style,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      prefixIcon: icon == null ? null : Icon(icon, color: _white),
      obscureText: obscure,
      autofocus: autofocus,
      autocorrect: false,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: action,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  Widget _textLink(String label, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.orangeLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _primary(String label, String busyLabel, VoidCallback action) =>
      AdaptiveButton(
        label: _busy ? busyLabel : label,
        color: AppColors.orange,
        textColor: _white,
        onPressed: _busy ? null : action,
      );

  String get _subtitle {
    switch (_step) {
      case _Step.signIn:
        return 'Welcome back. Sign in to continue.';
      case _Step.signUp:
        return 'Create an account to get started.';
      case _Step.verifySignup:
        return 'Confirm your email';
      case _Step.forgot:
        return 'Reset your password';
      case _Step.verifyRecovery:
        return 'Check your email';
      case _Step.newPassword:
        return 'Choose a new password';
    }
  }

  List<Widget> _cardChildren() {
    switch (_step) {
      case _Step.signIn:
      case _Step.signUp:
        final signingIn = _step == _Step.signIn;
        return [
          _ModeToggle(
            signingIn: signingIn,
            onChanged: (value) => _go(value ? _Step.signIn : _Step.signUp),
          ),
          const SizedBox(height: 20),
          if (!signingIn) ...[
            _input(
              controller: _name,
              hint: 'Name',
              icon: AppIcons.person,
              action: TextInputAction.next,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
          ],
          _input(
            controller: _email,
            hint: 'Email',
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _input(
            controller: _password,
            hint: 'Password',
            icon: AppIcons.lock,
            obscure: true,
            action: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _submitCredentials(),
          ),
          const SizedBox(height: 24),
          _primary(signingIn ? 'Sign in' : 'Sign up', 'Please wait…',
              _submitCredentials),
          if (signingIn) _textLink('Forgot password?', () => _go(_Step.forgot)),
        ];

      case _Step.forgot:
        return [
          Text(
            'Enter your email and we will send you a $_otpLength-digit code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 20),
          _input(
            controller: _email,
            hint: 'Email',
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _sendRecoveryCode(),
          ),
          const SizedBox(height: 24),
          _primary('Send code', 'Sending…', _sendRecoveryCode),
          _textLink('Back to sign in', () => _go(_Step.signIn)),
        ];

      case _Step.verifySignup:
      case _Step.verifyRecovery:
        return [
          Text(
            'Enter the $_otpLength-digit code we sent to\n${_email.text.trim()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 20),
          _input(
            controller: _code,
            hint: '000000',
            centered: true,
            autofocus: true,
            maxLength: _otpLength,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
            ),
            // Verify automatically once all digits are entered.
            onChanged: (value) {
              if (value.length == _otpLength && !_busy) _verifyCode();
            },
          ),
          const SizedBox(height: 24),
          _primary('Verify', 'Verifying…', _verifyCode),
          _textLink("Didn't get a code? Resend", _resendCode),
          _textLink('Back', () {
            if (_step == _Step.verifyRecovery) {
              _go(_Step.forgot);
            } else {
              _go(_Step.signUp);
            }
          }),
        ];

      case _Step.newPassword:
        return [
          _input(
            controller: _password,
            hint: 'New password',
            icon: AppIcons.lock,
            obscure: true,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _input(
            controller: _confirm,
            hint: 'Confirm new password',
            icon: AppIcons.lock,
            obscure: true,
            action: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _saveNewPassword(),
          ),
          const SizedBox(height: 24),
          _primary('Save password', 'Saving…', _saveNewPassword),
          _textLink('Cancel', _cancelRecovery),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: AppColors.background.resolveFrom(context),
      body: AppBackdrop(
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: _white),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 88,
                            height: 88,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Adaptive Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                      const SizedBox(height: 28),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _cardChildren(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-option pill toggle (Sign in / Sign up) in the app's orange style.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.signingIn, required this.onChanged});

  final bool signingIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) {
      final selected = signingIn == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected ? AppColors.orangeGradient : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected
                    ? CupertinoColors.white
                    : CupertinoColors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.track.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [option('Sign in', true), option('Sign up', false)]),
    );
  }
}
