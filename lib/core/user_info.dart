import 'package:supabase_flutter/supabase_flutter.dart';

/// Name shown in the greeting: the name given at sign-up, else the part of the
/// email before the "@".
String displayName(User? user) {
  final meta = user?.userMetadata?['name'];
  if (meta is String && meta.trim().isNotEmpty) return meta.trim();
  final local = (user?.email ?? '').split('@').first;
  if (local.isEmpty) return 'there';
  return local[0].toUpperCase() + local.substring(1);
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return '?';
  if (list.length == 1) {
    final word = list.first;
    return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
  }
  return (list[0][0] + list[1][0]).toUpperCase();
}
