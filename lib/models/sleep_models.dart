import 'dart:ui' show Color;

class SleepSession {
  final String id;
  final DateTime bedtime;
  final DateTime? wakeTime;
  final int qualityScore; // 0-100
  final double totalHours;
  final double remHours;
  final double coreHours;
  final double deepHours;
  final double lightHours;
  final String date;
  final bool isCompleted;
  final String? notes;
  final int targetHours;

  SleepSession({
    required this.id,
    required this.bedtime,
    this.wakeTime,
    this.qualityScore = 0,
    this.totalHours = 0,
    this.remHours = 0,
    this.coreHours = 0,
    this.deepHours = 0,
    this.lightHours = 0,
    required this.date,
    this.isCompleted = false,
    this.notes,
    this.targetHours = 8,
  });

  factory SleepSession.fromMap(Map<String, dynamic> map) {
    return SleepSession(
      id: map['id'] as String,
      bedtime: DateTime.fromMillisecondsSinceEpoch(map['bedtime'] as int),
      wakeTime: map['wake_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['wake_time'] as int)
          : null,
      qualityScore: map['quality_score'] as int? ?? 0,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0,
      remHours: (map['rem_hours'] as num?)?.toDouble() ?? 0,
      coreHours: (map['core_hours'] as num?)?.toDouble() ?? 0,
      deepHours: (map['deep_hours'] as num?)?.toDouble() ?? 0,
      lightHours: (map['light_hours'] as num?)?.toDouble() ?? 0,
      date: map['date'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      targetHours: map['target_hours'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bedtime': bedtime.millisecondsSinceEpoch,
      'wake_time': wakeTime?.millisecondsSinceEpoch,
      'quality_score': qualityScore,
      'total_hours': totalHours,
      'rem_hours': remHours,
      'core_hours': coreHours,
      'deep_hours': deepHours,
      'light_hours': lightHours,
      'date': date,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
      'target_hours': targetHours,
    };
  }

  SleepSession copyWith({
    String? id,
    DateTime? bedtime,
    DateTime? wakeTime,
    int? qualityScore,
    double? totalHours,
    double? remHours,
    double? coreHours,
    double? deepHours,
    double? lightHours,
    String? date,
    bool? isCompleted,
    String? notes,
    int? targetHours,
  }) {
    return SleepSession(
      id: id ?? this.id,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      qualityScore: qualityScore ?? this.qualityScore,
      totalHours: totalHours ?? this.totalHours,
      remHours: remHours ?? this.remHours,
      coreHours: coreHours ?? this.coreHours,
      deepHours: deepHours ?? this.deepHours,
      lightHours: lightHours ?? this.lightHours,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      targetHours: targetHours ?? this.targetHours,
    );
  }

  String get qualityLabel {
    if (qualityScore >= 85) return 'Excellent';
    if (qualityScore >= 70) return 'Good';
    if (qualityScore >= 50) return 'Fair';
    if (qualityScore >= 30) return 'Poor';
    return 'Bad';
  }

  String get formattedTotal {
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get formattedBedtime {
    final hour = bedtime.hour;
    final min = bedtime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$min $period';
  }

  String get formattedWakeTime {
    if (wakeTime == null) return '--:--';
    final hour = wakeTime!.hour;
    final min = wakeTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$min $period';
  }
}

class WeeklySleepData {
  final String dayLabel;
  final double hours;
  final int quality;

  const WeeklySleepData({
    required this.dayLabel,
    required this.hours,
    required this.quality,
  });
}

/// AI-generated sleep suggestion based on user patterns
class SleepSuggestion {
  final String title;
  final String description;
  final String icon; // emoji
  final SuggestionType type;

  const SleepSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });
}

enum SuggestionType { bedtime, wakeup, quality, habit, warning }

/// Dream journal entry
class DreamEntry {
  final String id;
  final String date;
  final String title;
  final String? description;
  final String mood; // emoji
  final List<String> tags;
  final bool lucid;
  final DateTime createdAt;

  DreamEntry({
    required this.id,
    required this.date,
    required this.title,
    this.description,
    this.mood = '😴',
    this.tags = const [],
    this.lucid = false,
    required this.createdAt,
  });

  factory DreamEntry.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    return DreamEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      mood: map['mood'] as String? ?? '😴',
      tags: tagsStr.isEmpty ? [] : tagsStr.split(','),
      lucid: (map['lucid'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'title': title,
        'description': description,
        'mood': mood,
        'tags': tags.join(','),
        'lucid': lucid ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

/// Ambient sound definition
class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const AmbientSound(this.id, this.name, this.emoji, this.color);
}
