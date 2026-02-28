class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetDurationMinutes;
  final int actualDurationMinutes;
  final String date;
  final bool isCompleted;
  final List<String> blockedApps;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.targetDurationMinutes,
    this.actualDurationMinutes = 0,
    required this.date,
    this.isCompleted = false,
    this.blockedApps = const [],
  });

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      targetDurationMinutes: map['target_duration_minutes'] as int,
      actualDurationMinutes: map['actual_duration_minutes'] as int? ?? 0,
      date: map['date'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      blockedApps: map['blocked_apps'] != null
          ? (map['blocked_apps'] as String).split(',')
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'target_duration_minutes': targetDurationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'date': date,
      'is_completed': isCompleted ? 1 : 0,
      'blocked_apps': blockedApps.join(','),
    };
  }

  FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? targetDurationMinutes,
    int? actualDurationMinutes,
    String? date,
    bool? isCompleted,
    List<String>? blockedApps,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      blockedApps: blockedApps ?? this.blockedApps,
    );
  }

  String get formattedTargetDuration {
    final hours = targetDurationMinutes ~/ 60;
    final minutes = targetDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedActualDuration {
    final hours = actualDurationMinutes ~/ 60;
    final minutes = actualDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get completionPercentage {
    if (targetDurationMinutes == 0) return 0;
    return (actualDurationMinutes / targetDurationMinutes).clamp(0.0, 1.0);
  }
}
