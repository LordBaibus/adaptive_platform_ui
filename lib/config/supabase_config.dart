/// Supabase connection settings.
///
/// The publishable key (sb_publishable_...) is designed to be shipped inside
/// client apps; access is limited by the Row Level Security policies in
/// supabase/schema.sql. NEVER put the database password or a secret /
/// service_role key in this app.
///
/// Both values can be overridden at run time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://brtfzfkoqcozfcfuhblp.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_wqQoq1feRWajuKl3c-XTcw_skbKSxNp',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.startsWith('sb_publishable_');
}
