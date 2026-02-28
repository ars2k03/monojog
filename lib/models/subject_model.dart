import 'package:flutter/material.dart';

/// A study subject with color, icon, and tracked time
class Subject {
  final String id;
  final String name;
  final String icon; // Emoji
  final int colorValue; // Color as int
  final int totalMinutes;
  final int dailyGoalMinutes;
  final int weeklyGoalMinutes;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    this.icon = '📚',
    this.colorValue = 0xFF6441A5,
    this.totalMinutes = 0,
    this.dailyGoalMinutes = 60,
    this.weeklyGoalMinutes = 300,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Subject copyWith({
    String? name,
    String? icon,
    int? colorValue,
    int? totalMinutes,
    int? dailyGoalMinutes,
    int? weeklyGoalMinutes,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color_value': colorValue,
        'total_minutes': totalMinutes,
        'daily_goal_minutes': dailyGoalMinutes,
        'weekly_goal_minutes': weeklyGoalMinutes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as String? ?? '📚',
        colorValue: m['color_value'] as int? ?? 0xFF6441A5,
        totalMinutes: m['total_minutes'] as int? ?? 0,
        dailyGoalMinutes: m['daily_goal_minutes'] as int? ?? 60,
        weeklyGoalMinutes: m['weekly_goal_minutes'] as int? ?? 300,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
      );
}

/// A goal (daily / weekly / subject-based)
class StudyGoal {
  final String id;
  final String title;
  final GoalType type;
  final int targetMinutes;
  final int currentMinutes;
  final String? subjectId;
  final String date; // e.g. '2026-02-22' or '2026-W08'

  StudyGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetMinutes,
    this.currentMinutes = 0,
    this.subjectId,
    required this.date,
  });

  double get progress =>
      targetMinutes > 0 ? (currentMinutes / targetMinutes).clamp(0.0, 1.0) : 0;
  bool get isCompleted => currentMinutes >= targetMinutes;

  StudyGoal copyWith({int? currentMinutes}) {
    return StudyGoal(
      id: id,
      title: title,
      type: type,
      targetMinutes: targetMinutes,
      currentMinutes: currentMinutes ?? this.currentMinutes,
      subjectId: subjectId,
      date: date,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type.name,
        'target_minutes': targetMinutes,
        'current_minutes': currentMinutes,
        'subject_id': subjectId,
        'date': date,
      };

  factory StudyGoal.fromMap(Map<String, dynamic> m) => StudyGoal(
        id: m['id'] as String,
        title: m['title'] as String,
        type: GoalType.values.firstWhere(
          (e) => e.name == (m['type'] as String? ?? 'daily'),
          orElse: () => GoalType.daily,
        ),
        targetMinutes: m['target_minutes'] as int? ?? 60,
        currentMinutes: m['current_minutes'] as int? ?? 0,
        subjectId: m['subject_id'] as String?,
        date: m['date'] as String? ?? '',
      );
}

enum GoalType { daily, weekly, subject }
