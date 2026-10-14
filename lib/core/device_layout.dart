import 'dart:math' as math;
import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/cupertino.dart';

/// How the content area is divided.
enum PaneMode {
  /// One pane (phones, folded devices).
  single,

  /// List on one side, detail on the other (tablets, unfolded foldables,
  /// book posture split along the hinge).
  sideBySide,

  /// List above, detail below (tabletop / laptop posture split along the hinge).
  stacked;

  String get label => switch (this) {
        PaneMode.single => 'Single pane',
        PaneMode.sideBySide => 'Two panes (side by side)',
        PaneMode.stacked => 'Two panes (stacked)',
      };
}

/// Describes the current window: size class plus any fold or hinge that
/// Android (Jetpack WindowManager) or Windows reports to Flutter.
@immutable
class DeviceLayout {
  const DeviceLayout({
    required this.size,
    required this.paneMode,
    required this.isFoldable,
    required this.isSeparating,
    this.fold,
  });

  final Size size;
  final PaneMode paneMode;

  /// The device reported a fold or hinge (folded, half-open or flat).
  final bool isFoldable;

  /// The fold currently splits the screen into two usable areas
  /// (a hinge, or a fold that is half-open).
  final bool isSeparating;

  final DisplayFeature? fold;

  /// Width at and above which a two-pane layout is used.
  static const double expandedBreakpoint = 600;

  static DeviceLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final features = MediaQuery.displayFeaturesOf(context);

    DisplayFeature? found;
    for (final feature in features) {
      if (feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge) {
        found = feature;
        break;
      }
    }

    final fold = found;
    final separating = fold != null &&
        (fold.type == DisplayFeatureType.hinge ||
            fold.state == DisplayFeatureState.postureHalfOpened);

    final PaneMode mode;
    if (fold != null && separating) {
      final vertical = fold.bounds.height >= fold.bounds.width;
      mode = vertical ? PaneMode.sideBySide : PaneMode.stacked;
    } else if (size.width >= expandedBreakpoint) {
      mode = PaneMode.sideBySide;
    } else {
      mode = PaneMode.single;
    }

    return DeviceLayout(
      size: size,
      paneMode: mode,
      isFoldable: fold != null,
      isSeparating: separating,
      fold: fold,
    );
  }
}

/// Lays out two panes. When a fold or hinge splits the screen, the panes are
/// placed on either side of it so no content is hidden under the hinge.
class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final separator =
        CupertinoDynamicColor.resolve(CupertinoColors.separator, context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fold = layout.isSeparating ? layout.fold : null;

        if (layout.paneMode == PaneMode.stacked && fold != null) {
          final gap = fold.bounds.height < 1
              ? 1.0
              : fold.bounds.height.clamp(1.0, 80.0).toDouble();
          final minTop = constraints.maxHeight * 0.25;
          final maxTop = math.max(minTop, constraints.maxHeight * 0.75 - gap);
          final topHeight = ((fold.bounds.center.dy / layout.size.height) *
                      constraints.maxHeight -
                  gap / 2)
              .clamp(minTop, maxTop)
              .toDouble();
          return Column(
            children: [
              SizedBox(height: topHeight, child: primary),
              Container(height: gap, color: separator),
              Expanded(child: secondary),
            ],
          );
        }

        double primaryWidth;
        double gap = 1;
        if (fold != null) {
          primaryWidth = fold.bounds.left
              .clamp(constraints.maxWidth * 0.3, constraints.maxWidth * 0.7)
              .toDouble();
          gap = fold.bounds.width < 1 ? 1 : fold.bounds.width;
        } else {
          primaryWidth =
              (constraints.maxWidth * 0.4).clamp(320.0, 440.0).toDouble();
        }

        return Row(
          children: [
            SizedBox(width: primaryWidth, child: primary),
            Container(width: gap, color: separator),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}
