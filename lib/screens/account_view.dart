import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/ph_time.dart';
import '../core/user_info.dart';
import '../services/app_settings.dart';
import '../widgets/avatar.dart';

/// Profile tab: the user's details, the dark-mode setting and sign out.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  static const Color _clear = Color(0x00000000);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = displayName(user);
    final createdAt = DateTime.tryParse(user?.createdAt ?? '');
    final joined = createdAt == null ? null : toPhTime(createdAt);
    final secondary = AppColors.secondaryText(context);

    Widget row(String label, String value, {bool last = false}) => AdaptiveListTile(
          backgroundColor: _clear,
          hideBottomDivider: last,
          title: Text(label),
          trailing: Text(value, style: TextStyle(color: secondary)),
        );

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Center(child: Avatar(name: name, size: 96)),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('PROFILE DETAILS', secondary),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    row('Name', name),
                    row('Email', user?.email ?? '—'),
                    row('Member since', joined == null ? '—' : formatDate(joined),
                        last: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('APPEARANCE', secondary),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ValueListenableBuilder<bool>(
                  valueListenable: AppSettings.darkMode,
                  builder: (context, dark, _) => AdaptiveListTile(
                    backgroundColor: _clear,
                    hideBottomDivider: true,
                    title: const Text('Dark mode'),
                    trailing: AdaptiveSwitch(
                      value: dark,
                      activeColor: CupertinoColors.activeGreen,
                      onChanged: (value) => AppSettings.setDarkMode(value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AdaptiveButton(
                label: 'Sign out',
                style: AdaptiveButtonStyle.tinted,
                color: CupertinoColors.destructiveRed,
                textColor: CupertinoColors.destructiveRed,
                onPressed: () {
                  Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
