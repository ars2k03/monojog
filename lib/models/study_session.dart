class StudySession {
  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String date;
  final bool isCompleted;

  StudySession({
    required this.id,
    required this.subject,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    required this.date,
    this.isCompleted = false,
  });

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      subject: map['subject'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      date: map['date'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'date': date,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  StudySession copyWith({
    String? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? date,
    bool? isCompleted,
  }) {
    return StudySession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
