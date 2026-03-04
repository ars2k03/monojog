import 'package:intl/intl.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { active, done }

enum TaskCategory { work, study, personal, health, creative, other }

class TaskModel {
  final String id;
  final String name;
  final String? description;
  final DateTime dueDate;
  final DateTime? dueTime;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool hasReminder;
  final String? attachmentPath;
  final TaskCategory category;
  final int estimatedMinutes;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final DateTime? timerStartedAt;
  final List<String> subtasks;
  final List<bool> subtasksDone;
  final String? recurringRule;

  TaskModel({
    required this.id,
    required this.name,
    this.description,
    required this.dueDate,
    this.dueTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.active,
    required this.createdAt,
    this.completedAt,
    this.hasReminder = false,
    this.attachmentPath,
    this.category = TaskCategory.other,
    this.estimatedMinutes = 0,
    this.elapsedSeconds = 0,
    this.isTimerRunning = false,
    this.timerStartedAt,
    this.subtasks = const [],
    this.subtasksDone = const [],
    this.recurringRule,
  });

  bool get isOverdue =>
      status == TaskStatus.active && dueDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  double get subtaskProgress {
    if (subtasks.isEmpty) return status == TaskStatus.done ? 1.0 : 0.0;
    final done = subtasksDone.where((b) => b).length;
    return done / subtasks.length;
  }

  String get formattedDueDate => DateFormat('MMM dd, yyyy').format(dueDate);

  String get formattedDueTime =>
      dueTime != null ? DateFormat('hh:mm a').format(dueTime!) : '';

  String get formattedElapsed {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${elapsedSeconds}s';
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.creative:
        return 'Creative';
      case TaskCategory.other:
        return 'Other';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case TaskCategory.work:
        return '💼';
      case TaskCategory.study:
        return '📚';
      case TaskCategory.personal:
        return '🙂';
      case TaskCategory.health:
        return '💪';
      case TaskCategory.creative:
        return '🎨';
      case TaskCategory.other:
        return '📌';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'due_date': dueDate.millisecondsSinceEpoch,
    'due_time': dueTime?.millisecondsSinceEpoch,
    'priority': priority.index,
    'status': status.index,
    'created_at': createdAt.millisecondsSinceEpoch,
    'completed_at': completedAt?.millisecondsSinceEpoch,
    'has_reminder': hasReminder ? 1 : 0,
    'attachment_path': attachmentPath,
    'category': category.index,
    'estimated_minutes': estimatedMinutes,
    'elapsed_seconds': elapsedSeconds,
    'subtasks': subtasks.join('|||'),
    'subtasks_done': subtasksDone.map((b) => b ? '1' : '0').join(','),
    'recurring_rule': recurringRule,
  };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
    dueTime: map['due_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['due_time'] as int)
        : null,
    priority: TaskPriority.values[map['priority'] as int? ?? 1],
    status: TaskStatus.values[map['status'] as int? ?? 0],
    createdAt:
    DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    completedAt: map['completed_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
        : null,
    hasReminder: (map['has_reminder'] as int? ?? 0) == 1,
    attachmentPath: map['attachment_path'] as String?,
    category: TaskCategory.values[(map['category'] as int?) ?? 5],
    estimatedMinutes: map['estimated_minutes'] as int? ?? 0,
    elapsedSeconds: map['elapsed_seconds'] as int? ?? 0,
    subtasks: (map['subtasks'] as String?)?.isNotEmpty == true
        ? (map['subtasks'] as String).split('|||')
        : [],
    subtasksDone: (map['subtasks_done'] as String?)?.isNotEmpty == true
        ? (map['subtasks_done'] as String)
        .split(',')
        .map((s) => s == '1')
        .toList()
        : [],
    recurringRule: map['recurring_rule'] as String?,
  );

  TaskModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? dueDate,
    DateTime? dueTime,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? hasReminder,
    String? attachmentPath,
    TaskCategory? category,
    int? estimatedMinutes,
    int? elapsedSeconds,
    bool? isTimerRunning,
    DateTime? timerStartedAt,
    List<String>? subtasks,
    List<bool>? subtasksDone,
    String? recurringRule,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      hasReminder: hasReminder ?? this.hasReminder,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      subtasks: subtasks ?? this.subtasks,
      subtasksDone: subtasksDone ?? this.subtasksDone,
      recurringRule: recurringRule ?? this.recurringRule,
    );
  }
}