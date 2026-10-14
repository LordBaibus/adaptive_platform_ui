import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

/// True when the native iOS 26 toolbar / tab bar float over the page body.
bool get overlaysChrome => PlatformInfo.isIOS && PlatformInfo.isIOS26OrHigher();

/// On iOS 26+ the native toolbar and tab bar are drawn on top of the body, so
/// content must start below the toolbar and stop above the tab bar. Other
/// platforms lay the bars out themselves, so this is a no-op there.
class ChromeInsets extends StatelessWidget {
  const ChromeInsets({super.key, required this.child, this.bottomBar = true});

  final Widget child;

  /// Whether a bottom tab bar is shown on this page.
  final bool bottomBar;

  static const double _toolbar = 56;
  static const double _tabBar = 92;

  @override
  Widget build(BuildContext context) {
    if (!overlaysChrome) return child;
    final media = MediaQuery.of(context);
    final top = media.padding.top + _toolbar;
    final bottom = bottomBar ? _tabBar : media.padding.bottom;
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      // The insets are consumed here, so SafeArea below does not add them again.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
