import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

/// Turns any thrown error into a short, user-presentable message.
String errorMessage(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is AuthException) return error.message;
  return error.toString();
}

/// CRUD for the `tasks` table. Row Level Security on the server guarantees a
/// user only ever sees and edits their own rows.
class TaskController extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  List<Task> _tasks = const [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;

  List<Task> byStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  int count(TaskStatus status) => _tasks.where((t) => t.status == status).length;

  /// Share of tasks that are completed, 0.0 – 1.0.
  double get completedShare =>
      _tasks.isEmpty ? 0 : count(TaskStatus.completed) / _tasks.length;

  /// The most pressing unfinished urgent task (earliest due date).
  Task? get nextUrgent {
    for (final t in _tasks) {
      if (t.isUrgent && t.status != TaskStatus.completed) return t;
    }
    return null;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _set(List<Task> tasks) {
    _tasks = [...tasks]..sort((a, b) {
        final byDate = a.dueDate.compareTo(b.dueDate);
        return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
      });
    notifyListeners();
  }

  // READ
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _db.from('tasks').select();
      _set(rows.map<Task>(Task.fromMap).toList());
    } catch (e) {
      _error = errorMessage(e);
    }
    _loading = false;
    notifyListeners();
  }

  // CREATE
  Future<Task> create(Task draft) async {
    final row =
        await _db.from('tasks').insert(draft.toMap()).select().single();
    final task = Task.fromMap(row);
    _set([..._tasks, task]);
    return task;
  }

  // UPDATE
  Future<Task> update(Task task) async {
    final row = await _db
        .from('tasks')
        .update(task.toMap())
        .eq('id', task.id)
        .select()
        .single();
    final saved = Task.fromMap(row);
    _set([for (final t in _tasks) t.id == saved.id ? saved : t]);
    return saved;
  }

  /// Moves a task to another status instantly, rolling back on failure.
  Future<void> setStatus(Task task, TaskStatus status) async {
    var progress = task.progress;
    if (status == TaskStatus.completed) progress = 100;
    if (status == TaskStatus.todo) progress = 0;
    if (status == TaskStatus.inProcess && (progress == 0 || progress == 100)) {
      progress = 25;
    }
    final previous = _tasks;
    _set([
      for (final t in _tasks)
        t.id == task.id ? t.copyWith(status: status, progress: progress) : t,
    ]);
    try {
      await _db
          .from('tasks')
          .update({'status': status.value, 'progress': progress}).eq('id', task.id);
    } catch (e) {
      _set(previous);
      rethrow;
    }
  }

  // DELETE (optimistic: the row disappears at once and returns on failure)
  Future<void> remove(String id) async {
    final previous = _tasks;
    _set(_tasks.where((t) => t.id != id).toList());
    try {
      await _db.from('tasks').delete().eq('id', id);
    } catch (e) {
      _set(previous);
      rethrow;
    }
  }
}
