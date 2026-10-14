import 'package:flutter/foundation.dart';

enum TaskStatus {
  todo('todo', 'To Do'),
  inProcess('in_process', 'In process'),
  completed('completed', 'Completed');

  const TaskStatus(this.value, this.label);

  /// Value stored in the database.
  final String value;
  final String label;

  static TaskStatus fromValue(String? value) => values.firstWhere(
        (s) => s.value == value,
        orElse: () => TaskStatus.todo,
      );
}

const List<String> kCategories = [
  'E-Commerce App',
  'Web Design',
  'Logo',
  'Web Development',
  'App Development',
];

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    this.description = '',
    this.status = TaskStatus.todo,
    this.progress = 0,
    this.estimatedHours = 8,
    this.category = 'App Development',
    this.isUrgent = false,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;

  /// 0 – 100
  final int progress;
  final int estimatedHours;
  final DateTime dueDate;
  final String category;
  final bool isUrgent;
  final DateTime createdAt;

  /// Hours used so far, derived from progress ("50 Hrs / 35 Hrs").
  int get spentHours => (estimatedHours * progress / 100).round();

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        status: TaskStatus.fromValue(map['status'] as String?),
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        estimatedHours: (map['estimated_hours'] as num?)?.toInt() ?? 8,
        dueDate: DateTime.parse(map['due_date'] as String),
        category: (map['category'] as String?) ?? 'App Development',
        isUrgent: (map['is_urgent'] as bool?) ?? false,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );

  /// Columns written on insert / update.
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'status': status.value,
        'progress': progress,
        'estimated_hours': estimatedHours,
        'due_date': _dateString(dueDate),
        'category': category,
        'is_urgent': isUrgent,
      };

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    int? progress,
    int? estimatedHours,
    DateTime? dueDate,
    String? category,
    bool? isUrgent,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        estimatedHours: estimatedHours ?? this.estimatedHours,
        dueDate: dueDate ?? this.dueDate,
        category: category ?? this.category,
        isUrgent: isUrgent ?? this.isUrgent,
        createdAt: createdAt,
      );
}

String _dateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
