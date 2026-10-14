import 'formatters.dart';

/// The app always works in Philippine time (UTC+8, no daylight saving),
/// whatever timezone the phone is set to.
const Duration _phOffset = Duration(hours: 8);

DateTime _wallClock(DateTime instant) {
  final u = instant.toUtc().add(_phOffset);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// Current date and time in the Philippines, as a plain wall-clock DateTime.
DateTime phNow() => _wallClock(DateTime.now());

/// Today's date in the Philippines (midnight).
DateTime phToday() => dateOnly(phNow());

/// Converts an absolute instant (for example a Supabase timestamptz) to
/// Philippine wall-clock time.
DateTime toPhTime(DateTime instant) => _wallClock(instant);
