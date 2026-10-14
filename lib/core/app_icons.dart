import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

/// True on iOS and macOS, where Cupertino visuals are used.
bool get isCupertinoPlatform => PlatformInfo.isIOS || PlatformInfo.isMacOS;

/// iOS 26+ renders native SF Symbols (referenced by name).
bool get _isIOS26Plus => PlatformInfo.isIOS && PlatformInfo.isIOS26OrHigher();

/// Icons are chosen per platform with PlatformInfo ternaries. No Material
/// icons are used: everything is CupertinoIcons, or an SF Symbol on iOS 26+.
class AppIcons {
  AppIcons._();

  /// SF Symbol name on iOS 26+, otherwise the given IconData. For widgets
  /// whose icon parameter is `dynamic` (navigation items, popup menu items).
  static dynamic pick(String sfSymbol, IconData icon) =>
      _isIOS26Plus ? sfSymbol : icon;

  static IconData get add => CupertinoIcons.add;
  static IconData get clock => CupertinoIcons.clock;
  static IconData get email => CupertinoIcons.mail;
  static IconData get lock => CupertinoIcons.lock;
  static IconData get person => CupertinoIcons.person;
  static IconData get chevronLeft => CupertinoIcons.chevron_left;
  static IconData get chevronRight => CupertinoIcons.chevron_right;
  static IconData get home => CupertinoIcons.house;
  static IconData get tasks => CupertinoIcons.list_bullet;
  static IconData get account => CupertinoIcons.person_crop_circle;
  static IconData get more => CupertinoIcons.ellipsis_circle;
  static IconData get kebab => CupertinoIcons.ellipsis_vertical;
  static IconData get edit => CupertinoIcons.pencil;
  static IconData get delete => CupertinoIcons.delete;
  static IconData get refresh => CupertinoIcons.refresh;
  static IconData get signOut => CupertinoIcons.square_arrow_right;

  // Filled check on iOS / macOS, solid check mark circle elsewhere.
  static IconData get done => isCupertinoPlatform
      ? CupertinoIcons.checkmark_circle_fill
      : CupertinoIcons.check_mark_circled_solid;

  /// SF Symbol names, used by iOS 26+ native toolbar, tab bar and menus.
  static const String addSymbol = 'plus';
  static const String moreSymbol = 'ellipsis.circle';
  static const String kebabSymbol = 'ellipsis';
  static const String editSymbol = 'pencil';
  static const String doneSymbol = 'checkmark.circle';
  static const String deleteSymbol = 'trash';
  static const String refreshSymbol = 'arrow.clockwise';
  static const String signOutSymbol = 'rectangle.portrait.and.arrow.right';
  static const String homeSymbol = 'house';
  static const String tasksSymbol = 'list.bullet';
  static const String accountSymbol = 'person.crop.circle';
}
