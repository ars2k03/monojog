/// Model for sleep sound recordings captured during a sleep session.
class SleepRecording {
  final String id;
  final String sessionId;
  final String filePath;
  final String label; // e.g. "Snored", "Talked", "Noise", "Cough"
  final DateTime timestamp;
  final int durationSeconds;
  final double peakDecibels;
  final String? emoji;

  SleepRecording({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.label,
    required this.timestamp,
    this.durationSeconds = 0,
    this.peakDecibels = 0,
    this.emoji,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'file_path': filePath,
        'label': label,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'duration_seconds': durationSeconds,
        'peak_decibels': peakDecibels,
        'emoji': emoji,
      };

  factory SleepRecording.fromMap(Map<String, dynamic> m) => SleepRecording(
        id: m['id'] as String,
        sessionId: m['session_id'] as String,
        filePath: m['file_path'] as String,
        label: m['label'] as String? ?? 'Noise',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            m['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
        durationSeconds: m['duration_seconds'] as int? ?? 0,
        peakDecibels: (m['peak_decibels'] as num?)?.toDouble() ?? 0,
        emoji: m['emoji'] as String?,
      );

  SleepRecording copyWith({
    String? label,
    String? emoji,
  }) =>
      SleepRecording(
        id: id,
        sessionId: sessionId,
        filePath: filePath,
        label: label ?? this.label,
        timestamp: timestamp,
        durationSeconds: durationSeconds,
        peakDecibels: peakDecibels,
        emoji: emoji ?? this.emoji,
      );

  String get formattedTime {
    final h = timestamp.hour;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'pm' : 'am';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get formattedDuration {
    if (durationSeconds < 60) return '${durationSeconds}s';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m}m ${s}s';
  }

  /// Auto-detect label based on sound characteristics
  static String detectLabel(double avgDb, double peakDb) {
    if (peakDb > 70) return 'You Snored';
    if (peakDb > 55) return 'You Talked';
    if (peakDb > 40) return 'Noise Detected';
    return 'Light Sound';
  }

  static String detectEmoji(String label) {
    switch (label) {
      case 'You Snored':
        return '😤';
      case 'You Talked':
        return '💬';
      case 'You Farted':
        return '💨';
      case 'Noise Detected':
        return '🔊';
      case 'Light Sound':
        return '🤫';
      case 'You Coughed':
        return '🤧';
      default:
        return '🔉';
    }
  }
}

/// Night noise level summary
class NightNoiseSummary {
  final double avgDecibels;
  final double maxDecibels;
  final int totalRecordings;
  final List<double> noiseTimeline; // per-minute dB levels
  final String healthNote;

  const NightNoiseSummary({
    required this.avgDecibels,
    required this.maxDecibels,
    required this.totalRecordings,
    required this.noiseTimeline,
    required this.healthNote,
  });

  String get avgLabel => '${avgDecibels.round()} dB';
  String get maxLabel => '${maxDecibels.round()} dB';
  bool get isSubHealth => maxDecibels > 60;
}
