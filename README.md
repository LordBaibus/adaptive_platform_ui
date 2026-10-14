# adaptive_ui

Tasks CRUD app built with `adaptive_platform_ui` and Supabase (auth + Postgres).

- Native look per platform: Cupertino / iOS 26 liquid glass on iOS & macOS,
  Material on Android, Windows, Linux and web, chosen with `PlatformInfo`.
- Foldable aware: reads the fold/hinge reported by the OS and lays the list and
  editor out on either side of it (book posture), stacked (tabletop posture),
  or side by side on any wide screen. See `lib/core/device_layout.dart`.

## Setup

1. Create a Supabase project, then run `supabase/schema.sql` in the SQL Editor.
2. (Optional) Authentication -> Providers -> Email: turn off "Confirm email"
   while developing so sign-up logs in immediately.
3. The project URL and publishable key are already set in
   `lib/config/supabase_config.dart`. Then run:

```
flutter pub get
flutter run
```

`adaptive_platform_ui` needs an iOS deployment target of 15.0 or higher.
