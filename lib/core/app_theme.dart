import 'package:flutter/cupertino.dart';

/// Warm "dark glass + orange" palette. Surfaces are dynamic: smoky brown in
/// dark mode, soft cream in light mode. Resolve with `.resolveFrom(context)`.
class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFFF7A1A);
  static const Color orangeLight = Color(0xFFFFA24C);
  static const Color amber = Color(0xFFF5A623);

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orangeLight, orange],
  );

  static const CupertinoDynamicColor background =
      CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFF4E6),
    darkColor: Color(0xFF120C08),
  );

  /// Translucent "glass" card fill.
  static const CupertinoDynamicColor glass = CupertinoDynamicColor.withBrightness(
    color: Color(0xCCFFFFFF),
    darkColor: Color(0x14FFFFFF),
  );

  static const CupertinoDynamicColor glassBorder =
      CupertinoDynamicColor.withBrightness(
    color: Color(0x14000000),
    darkColor: Color(0x1FFFFFFF),
  );

  /// Unfilled part of progress bars and rings.
  static const CupertinoDynamicColor track = CupertinoDynamicColor.withBrightness(
    color: Color(0x1F000000),
    darkColor: Color(0x2EFFFFFF),
  );

  static Color secondaryText(BuildContext context) =>
      CupertinoColors.secondaryLabel.resolveFrom(context);
}

/// Screen background: solid colour with a soft orange glow in the corner.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.resolveFrom(context),
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.9),
          radius: 1.1,
          colors: [
            AppColors.orange.withValues(alpha: dark ? 0.20 : 0.22),
            AppColors.orange.withValues(alpha: 0),
          ],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Rounded translucent card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.glass.resolveFrom(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorder.resolveFrom(context)),
        ),
        child: child,
      ),
    );
  }
}

/// Thin horizontal progress bar with an amber fill.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value});

  /// 0.0 – 1.0
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: AppColors.track.resolveFrom(context),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: AppColors.amber),
        ),
      ),
    );
  }
}
