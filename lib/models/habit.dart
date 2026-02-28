// Full-featured habit model with daily completion tracking,
// repeat schedule, reminders, and streak logic.

enum HabitRepeat { daily, weekdays, weekends, custom }

enum HabitCategory {
  custom,
  health,
  fitness,
  mindfulness,
  sleep,
  productivity,
  learning,
  social,
  nutrition,
}

extension HabitCategoryX on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.custom:
        return 'Custom';
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.sleep:
        return 'Sleep';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.nutrition:
        return 'Nutrition';
    }
  }

  String get emoji {
    switch (this) {
      case HabitCategory.custom:
        return '✏️';
      case HabitCategory.health:
        return '💊';
      case HabitCategory.fitness:
        return '🏋️';
      case HabitCategory.mindfulness:
        return '🧘';
      case HabitCategory.sleep:
        return '😴';
      case HabitCategory.productivity:
        return '🚀';
      case HabitCategory.learning:
        return '📚';
      case HabitCategory.social:
        return '👥';
      case HabitCategory.nutrition:
        return '🥗';
    }
  }
}

class Habit {
  final String id;
  final String title;
  final String emoji; // icon emoji
  final String color; // hex color
  final HabitRepeat repeat;
  final List<int> customDays; // 1=Mon..7=Sun (for custom repeat)
  final int? reminderHour;
  final int? reminderMinute;
  final HabitCategory category;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;
  final bool archived;

  Habit({
    required this.id,
    required this.title,
    this.emoji = '✅',
    this.color = '#7C4DFF',
    this.repeat = HabitRepeat.daily,
    this.customDays = const [],
    this.reminderHour,
    this.reminderMinute,
    this.category = HabitCategory.custom,
    this.currentStreak = 0,
    this.bestStreak = 0,
    DateTime? createdAt,
    this.archived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'color': color,
        'repeat_type': repeat.index,
        'custom_days': customDays.join(','),
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
        'category': category.index,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'created_at': createdAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory Habit.fromMap(Map<String, dynamic> m) {
    final daysStr = m['custom_days'] as String? ?? '';
    final days = daysStr.isEmpty
        ? <int>[]
        : daysStr.split(',').map((s) => int.tryParse(s) ?? 1).toList();

    return Habit(
      id: m['id'] as String,
      title: m['title'] as String,
      emoji: m['emoji'] as String? ?? '✅',
      color: m['color'] as String? ?? '#7C4DFF',
      repeat: HabitRepeat.values[(m['repeat_type'] as int?) ?? 0],
      customDays: days,
      reminderHour: m['reminder_hour'] as int?,
      reminderMinute: m['reminder_minute'] as int?,
      category: HabitCategory.values[(m['category'] as int?) ?? 0],
      currentStreak: m['current_streak'] as int? ?? 0,
      bestStreak: m['best_streak'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          m['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      archived: (m['archived'] as int? ?? 0) == 1,
    );
  }

  Habit copyWith({
    String? title,
    String? emoji,
    String? color,
    HabitRepeat? repeat,
    List<int>? customDays,
    int? reminderHour,
    int? reminderMinute,
    HabitCategory? category,
    int? currentStreak,
    int? bestStreak,
    bool? archived,
  }) =>
      Habit(
        id: id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        repeat: repeat ?? this.repeat,
        customDays: customDays ?? this.customDays,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        category: category ?? this.category,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );

  String get repeatLabel {
    switch (repeat) {
      case HabitRepeat.daily:
        return 'Every day';
      case HabitRepeat.weekdays:
        return 'Weekdays';
      case HabitRepeat.weekends:
        return 'Weekends';
      case HabitRepeat.custom:
        const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return customDays.map((d) => names[d]).join(', ');
    }
  }

  String get reminderLabel {
    if (reminderHour == null) return 'Off';
    final h = reminderHour! > 12
        ? reminderHour! - 12
        : (reminderHour == 0 ? 12 : reminderHour!);
    final m = (reminderMinute ?? 0).toString().padLeft(2, '0');
    final p = reminderHour! >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  /// Whether this habit is scheduled for a given weekday (1=Mon..7=Sun)
  bool isScheduledFor(int weekday) {
    switch (repeat) {
      case HabitRepeat.daily:
        return true;
      case HabitRepeat.weekdays:
        return weekday <= 5;
      case HabitRepeat.weekends:
        return weekday >= 6;
      case HabitRepeat.custom:
        return customDays.contains(weekday);
    }
  }
}

/// One row per habit per date — records completion.
class HabitCompletion {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final bool completed;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date,
        'completed': completed ? 1 : 0,
      };

  factory HabitCompletion.fromMap(Map<String, dynamic> m) => HabitCompletion(
        id: m['id'] as String,
        habitId: m['habit_id'] as String,
        date: m['date'] as String,
        completed: (m['completed'] as int? ?? 1) == 1,
      );
}

/// Built-in template for quick habit creation
class HabitTemplate {
  final String title;
  final String emoji;
  final String color;
  final HabitCategory category;

  const HabitTemplate({
    required this.title,
    required this.emoji,
    required this.color,
    required this.category,
  });
}

/// Pre-built template packs
class HabitTemplatePack {
  final String name;
  final String subtitle;
  final String emoji;
  final List<HabitTemplate> templates;

  const HabitTemplatePack({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.templates,
  });

  static const List<HabitTemplatePack> all = [
    HabitTemplatePack(
      name: 'Must-have habits',
      subtitle: 'Small habits, big results',
      emoji: '⭐',
      templates: [
        HabitTemplate(
            title: 'Drink water',
            emoji: '💧',
            color: '#00B4D8',
            category: HabitCategory.health),
        HabitTemplate(
            title: 'Read 10 pages',
            emoji: '📖',
            color: '#7C4DFF',
            category: HabitCategory.learning),
        HabitTemplate(
            title: 'Walk 10 min',
            emoji: '🚶',
            color: '#4CAF50',
            category: HabitCategory.fitness),
        HabitTemplate(
            title: 'Journal',
            emoji: '📝',
            color: '#FF9F43',
            category: HabitCategory.mindfulness),
        HabitTemplate(
            title: 'No social media',
            emoji: '📵',
            color: '#FF4D6D',
            category: HabitCategory.productivity),
      ],
    ),
    HabitTemplatePack(
      name: 'Morning routine',
      subtitle: 'Start your day right',
      emoji: '🌅',
      templates: [
        HabitTemplate(
            title: 'Wake up early',
            emoji: '⏰',
            color: '#FF6B35',
            category: HabitCategory.sleep),
        HabitTemplate(
            title: 'Make bed',
            emoji: '🛏️',
            color: '#8B5CF6',
            category: HabitCategory.productivity),
        HabitTemplate(
            title: 'Stretch',
            emoji: '🤸',
            color: '#06D6A0',
            category: HabitCategory.fitness),
        HabitTemplate(
            title: 'Healthy breakfast',
            emoji: '🥣',
            color: '#F59E0B',
            category: HabitCategory.nutrition),
        HabitTemplate(
            title: 'Plan the day',
            emoji: '📋',
            color: '#3B82F6',
            category: HabitCategory.productivity),
      ],
    ),
    HabitTemplatePack(
      name: 'Better sleep',
      subtitle: 'Quality rest every night',
      emoji: '🌙',
      templates: [
        HabitTemplate(
            title: 'Sleep by 11 PM',
            emoji: '😴',
            color: '#6366F1',
            category: HabitCategory.sleep),
        HabitTemplate(
            title: 'No screens before bed',
            emoji: '📵',
            color: '#EC4899',
            category: HabitCategory.sleep),
        HabitTemplate(
            title: 'Read before sleep',
            emoji: '📚',
            color: '#8B5CF6',
            category: HabitCategory.learning),
        HabitTemplate(
            title: 'Meditate',
            emoji: '🧘',
            color: '#14B8A6',
            category: HabitCategory.mindfulness),
      ],
    ),
    HabitTemplatePack(
      name: 'Getting stuff done',
      subtitle: 'Boost your productivity',
      emoji: '🚀',
      templates: [
        HabitTemplate(
            title: 'Code daily',
            emoji: '💻',
            color: '#06B6D4',
            category: HabitCategory.learning),
        HabitTemplate(
            title: 'Review goals',
            emoji: '🎯',
            color: '#EF4444',
            category: HabitCategory.productivity),
        HabitTemplate(
            title: 'Deep work 2h',
            emoji: '🔥',
            color: '#FF6B35',
            category: HabitCategory.productivity),
        HabitTemplate(
            title: 'Learn something new',
            emoji: '💡',
            color: '#F59E0B',
            category: HabitCategory.learning),
        HabitTemplate(
            title: 'Inbox zero',
            emoji: '📧',
            color: '#10B981',
            category: HabitCategory.productivity),
      ],
    ),
    HabitTemplatePack(
      name: 'Fitness & Health',
      subtitle: 'Build a stronger you',
      emoji: '💪',
      templates: [
        HabitTemplate(
            title: 'Go to gym',
            emoji: '🏋️',
            color: '#F59E0B',
            category: HabitCategory.fitness),
        HabitTemplate(
            title: 'Do skincare',
            emoji: '🧴',
            color: '#EC4899',
            category: HabitCategory.health),
        HabitTemplate(
            title: 'Eat fruits & veggies',
            emoji: '🥗',
            color: '#4CAF50',
            category: HabitCategory.nutrition),
        HabitTemplate(
            title: 'No junk food',
            emoji: '🚫',
            color: '#EF4444',
            category: HabitCategory.nutrition),
        HabitTemplate(
            title: 'Take vitamins',
            emoji: '💊',
            color: '#06B6D4',
            category: HabitCategory.health),
      ],
    ),
  ];
}
