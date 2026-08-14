import 'priority.dart';

/// Abstract base class representing a task.
///
/// Implements [Comparable] so a list of tasks can be sorted directly with
/// `list.sort()` (by priority, then by due date). Concrete subclasses
/// ([NormalTask] and [UrgentTask]) decide how a task is rendered via
/// [describe] and may carry their own extra fields.
abstract class Task implements Comparable<Task> {
  final String id;
  final String title;
  final Priority priority;
  final DateTime? dueDate;
  bool completed;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.dueDate,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (title.trim().isEmpty) {
      throw ArgumentError('Le titre de la tâche ne peut pas être vide.');
    }
  }

  /// A short machine-readable label for the task type, used for JSON
  /// (de)serialization ("normal" or "urgent").
  String get type;

  /// Renders the task as a one-line, human readable description.
  String describe();

  /// Serializes the task to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
      };

  /// Rebuilds the correct [Task] subtype from a JSON map produced by
  /// [toJson]. This is the one place that needs to know about every
  /// concrete subtype.
  factory Task.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'normal';
    final id = json['id'] as String;
    final title = json['title'] as String;
    final dueDate = json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null;
    final completed = json['completed'] as bool? ?? false;
    final createdAt = DateTime.parse(json['createdAt'] as String);

    if (type == 'urgent') {
      return UrgentTask(
        id: id,
        title: title,
        dueDate: dueDate,
        completed: completed,
        createdAt: createdAt,
        reason: json['reason'] as String? ?? 'Non spécifiée',
      );
    }

    final priority = Priority.fromString(json['priority'] as String);
    return NormalTask(
      id: id,
      title: title,
      priority: priority,
      dueDate: dueDate,
      completed: completed,
      createdAt: createdAt,
    );
  }

  /// Sorts tasks by priority (highest first), then by due date (soonest
  /// first, with tasks that have no due date sorted last).
  @override
  int compareTo(Task other) {
    final priorityCompare = other.priority.weight.compareTo(priority.weight);
    if (priorityCompare != 0) return priorityCompare;
    if (dueDate == null && other.dueDate == null) return 0;
    if (dueDate == null) return 1;
    if (other.dueDate == null) return -1;
    return dueDate!.compareTo(other.dueDate!);
  }
}

/// A standard task with a priority chosen explicitly by the user.
class NormalTask extends Task {
  NormalTask({
    required String id,
    required String title,
    required Priority priority,
    DateTime? dueDate,
    bool completed = false,
    DateTime? createdAt,
  }) : super(
          id: id,
          title: title,
          priority: priority,
          dueDate: dueDate,
          completed: completed,
          createdAt: createdAt,
        );

  @override
  String get type => 'normal';

  @override
  String describe() {
    final status = completed ? '[x]' : '[ ]';
    final due = dueDate != null ? ' (échéance: ${_formatDate(dueDate!)})' : '';
    return '$status $title — priorité: ${priority.name}$due';
  }
}

/// An escalated task. It is always high priority — that cannot be
/// overridden — and carries a [reason] explaining the escalation. This is
/// the `Task -> UrgentTask` inheritance relationship required by the
/// project brief.
class UrgentTask extends Task {
  final String reason;

  UrgentTask({
    required String id,
    required String title,
    DateTime? dueDate,
    bool completed = false,
    DateTime? createdAt,
    required this.reason,
  }) : super(
          id: id,
          title: title,
          priority: Priority.high,
          dueDate: dueDate,
          completed: completed,
          createdAt: createdAt,
        );

  @override
  String get type => 'urgent';

  @override
  String describe() {
    final status = completed ? '[x]' : '[ ]';
    final due = dueDate != null ? ' (échéance: ${_formatDate(dueDate!)})' : '';
    return '$status 🚨 URGENT: $title — raison: $reason$due';
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'reason': reason,
      };
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
