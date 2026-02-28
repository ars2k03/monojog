class StudyHabit {
  final String id;
  final String title;
  final String? notes;
  final bool isPositive; // + or - habit
  final int difficulty; // 1=easy, 2=medium, 3=hard
  final int streak;
  final int counterUp;
  final int counterDown;
  final String color; // hex
  final DateTime createdAt;

  StudyHabit({
    required this.id,
    required this.title,
    this.notes,
    this.isPositive = true,
    this.difficulty = 2,
    this.streak = 0,
    this.counterUp = 0,
    this.counterDown = 0,
    this.color = '#7C3AED',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'is_positive': isPositive ? 1 : 0,
        'difficulty': difficulty,
        'streak': streak,
        'counter_up': counterUp,
        'counter_down': counterDown,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory StudyHabit.fromMap(Map<String, dynamic> m) => StudyHabit(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        isPositive: (m['is_positive'] as int? ?? 1) == 1,
        difficulty: m['difficulty'] as int? ?? 2,
        streak: m['streak'] as int? ?? 0,
        counterUp: m['counter_up'] as int? ?? 0,
        counterDown: m['counter_down'] as int? ?? 0,
        color: m['color'] as String? ?? '#7C3AED',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      );

  StudyHabit copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isPositive,
    int? difficulty,
    int? streak,
    int? counterUp,
    int? counterDown,
    String? color,
  }) =>
      StudyHabit(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        isPositive: isPositive ?? this.isPositive,
        difficulty: difficulty ?? this.difficulty,
        streak: streak ?? this.streak,
        counterUp: counterUp ?? this.counterUp,
        counterDown: counterDown ?? this.counterDown,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  /// Points earned per positive tap
  int get pointsPerTap {
    switch (difficulty) {
      case 1:
        return 2;
      case 3:
        return 6;
      default:
        return 4;
    }
  }
}

class StudyDaily {
  final String id;
  final String title;
  final String? notes;
  final int targetMinutes; // daily target study time
  final bool isDoneToday;
  final int streak;
  final int difficulty;
  final String color;
  final DateTime createdAt;
  final String? lastCompletedDate;

  StudyDaily({
    required this.id,
    required this.title,
    this.notes,
    this.targetMinutes = 30,
    this.isDoneToday = false,
    this.streak = 0,
    this.difficulty = 2,
    this.color = '#6366F1',
    DateTime? createdAt,
    this.lastCompletedDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'target_minutes': targetMinutes,
        'is_done_today': isDoneToday ? 1 : 0,
        'streak': streak,
        'difficulty': difficulty,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_completed_date': lastCompletedDate,
      };

  factory StudyDaily.fromMap(Map<String, dynamic> m) => StudyDaily(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        targetMinutes: m['target_minutes'] as int? ?? 30,
        isDoneToday: (m['is_done_today'] as int? ?? 0) == 1,
        streak: m['streak'] as int? ?? 0,
        difficulty: m['difficulty'] as int? ?? 2,
        color: m['color'] as String? ?? '#6366F1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
        lastCompletedDate: m['last_completed_date'] as String?,
      );

  StudyDaily copyWith({
    String? title,
    String? notes,
    int? targetMinutes,
    bool? isDoneToday,
    int? streak,
    int? difficulty,
    String? color,
    String? lastCompletedDate,
  }) =>
      StudyDaily(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        isDoneToday: isDoneToday ?? this.isDoneToday,
        streak: streak ?? this.streak,
        difficulty: difficulty ?? this.difficulty,
        color: color ?? this.color,
        createdAt: createdAt,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );
}

class StudyTodo {
  final String id;
  final String title;
  final String? notes;
  final bool isDone;
  final int difficulty;
  final String? dueDate;
  final String color;
  final DateTime createdAt;

  StudyTodo({
    required this.id,
    required this.title,
    this.notes,
    this.isDone = false,
    this.difficulty = 2,
    this.dueDate,
    this.color = '#06B6D4',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'is_done': isDone ? 1 : 0,
        'difficulty': difficulty,
        'due_date': dueDate,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory StudyTodo.fromMap(Map<String, dynamic> m) => StudyTodo(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        isDone: (m['is_done'] as int? ?? 0) == 1,
        difficulty: m['difficulty'] as int? ?? 2,
        dueDate: m['due_date'] as String?,
        color: m['color'] as String? ?? '#06B6D4',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            m['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      );

  StudyTodo copyWith({
    String? title,
    String? notes,
    bool? isDone,
    int? difficulty,
    String? dueDate,
    String? color,
  }) =>
      StudyTodo(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        isDone: isDone ?? this.isDone,
        difficulty: difficulty ?? this.difficulty,
        dueDate: dueDate ?? this.dueDate,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
