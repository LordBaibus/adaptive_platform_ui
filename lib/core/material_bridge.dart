// ---------------------------------------------------------------------------
// The ONLY file in the app that imports anything from material.dart.
//
// On Android the app bar, bottom bar, list rows, dialogs and switches drawn by
// adaptive_platform_ui are Material components. They take their colours from
// Material's own theme, so without this file they follow the phone's
// light / dark setting and do not match the rest of the app (the bars looked
// like separate pages). Only theme *data* is used here: no Material widgets.
//
// To remove Material completely: delete this file and the three
// `material*` / `themeMode` lines in main.dart. The app still runs, but the
// Android bars will follow the phone's theme again.
// ---------------------------------------------------------------------------
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        AppBarTheme,
        BottomNavigationBarThemeData,
        ColorScheme,
        NavigationBarThemeData,
        ThemeData,
        ThemeMode;

import 'app_theme.dart';

ThemeMode appThemeMode(bool dark) => dark ? ThemeMode.dark : ThemeMode.light;

/// Material theme whose surfaces match [AppColors.background], so the bars and
/// the page behind them are exactly the same colour.
ThemeData appMaterialTheme({required bool dark}) {
  final bg = dark ? const Color(0xFF120C08) : const Color(0xFFFFF4E6);
  final text = dark ? const Color(0xFFFFFFFF) : const Color(0xFF2B1708);
  const clear = Color(0x00000000);

  final scheme = dark
      ? ColorScheme.dark(
          primary: AppColors.orange,
          onPrimary: const Color(0xFFFFFFFF),
          secondary: AppColors.orangeLight,
          surface: bg,
          onSurface: text,
          surfaceContainer: bg,
          surfaceContainerHigh: const Color(0xFF1C130D),
          surfaceTint: clear,
        )
      : ColorScheme.light(
          primary: AppColors.orange,
          onPrimary: const Color(0xFFFFFFFF),
          secondary: AppColors.orangeLight,
          surface: bg,
          onSurface: text,
          surfaceContainer: bg,
          surfaceContainerHigh: const Color(0xFFFFFFFF),
          surfaceTint: clear,
        );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: clear,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      surfaceTintColor: clear,
      elevation: 0,
      indicatorColor: AppColors.orange,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bg,
      elevation: 0,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: text.withValues(alpha: 0.6),
    ),
  );
}
