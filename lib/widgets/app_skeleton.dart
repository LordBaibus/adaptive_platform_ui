import 'package:flutter/cupertino.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Shimmering placeholder shown while data loads or refreshes. Wraps a normal
/// widget (or a sliver) and turns its text, icons and boxes into grey bones.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.enabled,
    required this.child,
    this.sliver = false,
  });

  final bool enabled;
  final Widget child;

  /// Set to true when [child] is a sliver.
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final effect = ShimmerEffect(
      baseColor: dark ? const Color(0x2EFFFFFF) : const Color(0x1F000000),
      highlightColor: dark ? const Color(0x66FFFFFF) : const Color(0x0A000000),
    );

    return sliver
        ? Skeletonizer.sliver(enabled: enabled, effect: effect, child: child)
        : Skeletonizer(enabled: enabled, effect: effect, child: child);
  }
}
