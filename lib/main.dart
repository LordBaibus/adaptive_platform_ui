import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/app_theme.dart';
import 'core/material_bridge.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/auth_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey,
    );
  }

  await AppSettings.load();

  runApp(const AppRoot());
}

/// Forces the whole app (Cupertino and Material parts alike) into dark or
/// light mode according to the dark-mode setting, instead of following the
/// phone's own theme. Works by overriding the platform brightness that every
/// theme reads from MediaQuery.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkMode,
      builder: (context, dark, _) {
        final base =
            MediaQuery.maybeOf(context) ?? MediaQueryData.fromView(View.of(context));
        return MediaQuery(
          data: base.copyWith(
            platformBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkMode,
      builder: (context, dark, _) => AdaptiveApp(
        title: 'Adaptive Tasks',
        // Material theme for Android / Windows / Linux / web (see
        // lib/core/material_bridge.dart for why this is needed).
        themeMode: appThemeMode(dark),
        materialLightTheme: appMaterialTheme(dark: false),
        materialDarkTheme: appMaterialTheme(dark: true),
        // Applies dark / light to every screen (including pushed ones) the same
        // way the login screen does: override the brightness that the
        // Cupertino colours, glass cards and text resolve against.
        builder: (context, child) {
          final brightness = dark ? Brightness.dark : Brightness.light;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(platformBrightness: brightness),
            child: CupertinoTheme(
              data: CupertinoTheme.of(context).copyWith(
                brightness: brightness,
                primaryColor: AppColors.orange,
              ),
              child: Builder(
                builder: (context) => DefaultTextStyle.merge(
                  style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
        cupertinoLightTheme: const CupertinoThemeData(
          primaryColor: AppColors.orange,
          brightness: Brightness.light,
        ),
        cupertinoDarkTheme: const CupertinoThemeData(
          primaryColor: AppColors.orange,
          brightness: Brightness.dark,
        ),
        home: SupabaseConfig.isConfigured
            ? const AuthGate()
            : const _SetupRequiredScreen(),
      ),
    );
  }
}

/// Shows the sign-in screen or the app depending on the Supabase session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return ValueListenableBuilder<bool>(
      valueListenable: AuthFlow.recovering,
      builder: (context, recovering, _) => StreamBuilder<AuthState>(
        stream: auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ?? auth.currentSession;
          // Stay on the auth screen while the user is choosing a new password.
          if (session == null || recovering) return const AuthScreen();
          return HomeScreen(key: ValueKey(session.user.id));
        },
      ),
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'Setup required'),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase is not configured yet.\n\n'
              'Run the app with:\n'
              'flutter run --dart-define=SUPABASE_URL=<your url> '
              '--dart-define=SUPABASE_PUBLISHABLE_KEY=<your publishable key>\n\n'
              'or edit lib/config/supabase_config.dart.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
