import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:monojog/models/sleep_models.dart';
import 'package:monojog/models/sleep_recording.dart';
import 'package:monojog/services/database_service.dart';
import 'package:monojog/services/history_service.dart';
import 'package:monojog/providers/focus_provider.dart';

class SleepProvider extends ChangeNotifier {
  static const _platform = MethodChannel('com.monojog.app/focus');

  bool _isSleeping = false;
  DateTime? _bedtime;
  Timer? _sleepTimer;
  Duration _elapsed = Duration.zero;
  int _targetHours = 8;

  // Alarm / wake-up
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _bedtimeGoal;
  bool _alarmEnabled = false;
  Duration? _countdownToSleep;
  Timer? _countdownTimer;

  // ── Sleep app blocking ──
  bool _sleepBlockEnabled = false;
  bool _sleepBlockAll = false; // true = strict (block all), false = custom list
  List<String> _sleepBlockedPackages = []; // custom blocked packages

  List<SleepSession> _sleepHistory = [];
  SleepSession? _lastSession;

  // ── Sound Recording ──
  bool _recordingEnabled = false;
  AudioRecorder? _audioRecorder;
  Timer? _recordingMonitor;
  List<SleepRecording> _recordings = [];
  List<double> _noiseTimeline = []; // per-minute avg dB
  bool _isRecording = false;
  String? _currentRecordPath;
  DateTime? _currentRecordStart;
  double _currentMaxDb = 0;
  double _silenceThreshold = 35; // dB threshold to trigger recording
  // ignore: unused_field
  int _recordingSegmentCount = 0;

  // ── Dream Journal ──
  List<DreamEntry> _dreamJournal = [];

  // ── Ambient Sounds ──
  String? _activeAmbientSound; // null = off
  double _ambientVolume = 0.7;
  Timer? _ambientAutoStop;
  int _ambientTimerMinutes = 0; // 0 = play until sleep

  // ── Wind-down ──
  bool _windDownActive = false;
  int _windDownMinutes = 30;
  Timer? _windDownTimer;
  int _windDownSecondsLeft = 0;

  // ── Sleep Debt ──
  double get sleepDebt {
    if (_sleepHistory.isEmpty) return 0;
    final last7 = _sleepHistory.take(7).toList();
    double debt = 0;
    for (final s in last7) {
      final deficit = _targetHours - s.totalHours;
      if (deficit > 0) debt += deficit;
    }
    return double.parse(debt.toStringAsFixed(1));
  }

  // ── Consistency Score (0-100) ──
  int get consistencyScore {
    if (_sleepHistory.length < 3) return 0;
    final last7 = _sleepHistory.take(7).toList();
    if (last7.length < 2) return 50;

    // Check bedtime consistency
    final bedHours = last7.map((s) {
      var h = s.bedtime.hour.toDouble() + s.bedtime.minute / 60.0;
      if (h < 12) h += 24;
      return h;
    }).toList();

    final wakeHours = last7.where((s) => s.wakeTime != null).map((s) {
      return s.wakeTime!.hour.toDouble() + s.wakeTime!.minute / 60.0;
    }).toList();

    double bedVariance = 0;
    if (bedHours.length >= 2) {
      final bedAvg = bedHours.reduce((a, b) => a + b) / bedHours.length;
      bedVariance =
          bedHours.map((h) => (h - bedAvg).abs()).reduce((a, b) => a + b) /
              bedHours.length;
    }

    double wakeVariance = 0;
    if (wakeHours.length >= 2) {
      final wakeAvg = wakeHours.reduce((a, b) => a + b) / wakeHours.length;
      wakeVariance =
          wakeHours.map((h) => (h - wakeAvg).abs()).reduce((a, b) => a + b) /
              wakeHours.length;
    }

    // Duration consistency
    final hours = last7.map((s) => s.totalHours).toList();
    final hourAvg = hours.reduce((a, b) => a + b) / hours.length;
    final hourVariance =
        hours.map((h) => (h - hourAvg).abs()).reduce((a, b) => a + b) /
            hours.length;

    // Lower variance = higher score
    final bedScore = (1 - (bedVariance / 3).clamp(0, 1)) * 40;
    final wakeScore = (1 - (wakeVariance / 3).clamp(0, 1)) * 30;
    final durScore = (1 - (hourVariance / 2).clamp(0, 1)) * 30;

    return (bedScore + wakeScore + durScore).round().clamp(0, 100);
  }

  // --- Getters ---
  bool get isSleeping => _isSleeping;
  DateTime? get bedtime => _bedtime;
  Duration get elapsed => _elapsed;
  int get targetHours => _targetHours;
  List<SleepSession> get sleepHistory => _sleepHistory;
  SleepSession? get lastSession => _lastSession;
  TimeOfDay? get wakeUpTime => _wakeUpTime;
  TimeOfDay? get bedtimeGoal => _bedtimeGoal;
  bool get alarmEnabled => _alarmEnabled;
  Duration? get countdownToSleep => _countdownToSleep;
  bool get isCountdownActive => _countdownTimer != null;
  bool get sleepBlockEnabled => _sleepBlockEnabled;
  bool get sleepBlockAll => _sleepBlockAll;
  List<String> get sleepBlockedPackages => _sleepBlockedPackages;
  bool get recordingEnabled => _recordingEnabled;
  bool get isRecording => _isRecording;
  List<SleepRecording> get recordings => _recordings;
  List<double> get noiseTimeline => _noiseTimeline;
  double get silenceThreshold => _silenceThreshold;

  // Dream Journal getters
  List<DreamEntry> get dreamJournal => List.unmodifiable(_dreamJournal);

  // Ambient Sound getters
  String? get activeAmbientSound => _activeAmbientSound;
  double get ambientVolume => _ambientVolume;
  int get ambientTimerMinutes => _ambientTimerMinutes;
  bool get isAmbientPlaying => _activeAmbientSound != null;

  // Wind-down getters
  bool get windDownActive => _windDownActive;
  int get windDownMinutes => _windDownMinutes;
  int get windDownSecondsLeft => _windDownSecondsLeft;
  String get windDownFormatted {
    final m = _windDownSecondsLeft ~/ 60;
    final s = _windDownSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Available ambient sounds
  static const ambientSounds = [
    AmbientSound('rain', 'Rain', '🌧️', Color(0xFF4ECDC4)),
    AmbientSound('ocean', 'Ocean Waves', '🌊', Color(0xFF2196F3)),
    AmbientSound('forest', 'Forest', '🌲', Color(0xFF66BB6A)),
    AmbientSound('fire', 'Fireplace', '🔥', Color(0xFFFF7043)),
    AmbientSound('wind', 'Wind', '🍃', Color(0xFF78909C)),
    AmbientSound('thunder', 'Thunder', '⛈️', Color(0xFF5C6BC0)),
    AmbientSound('birds', 'Birds', '🐦', Color(0xFFFFCA28)),
    AmbientSound('whitenoise', 'White Noise', '📻', Color(0xFF90A4AE)),
  ];

  void setSleepBlockEnabled(bool v) {
    _sleepBlockEnabled = v;
    _saveSettings();
    notifyListeners();
  }

  void setSleepBlockAll(bool v) {
    _sleepBlockAll = v;
    _saveSettings();
    notifyListeners();
  }

  void setSleepBlockedPackages(List<String> pkgs) {
    _sleepBlockedPackages = pkgs;
    _saveSettings();
    notifyListeners();
  }

  void toggleSleepBlockedPackage(String pkg) {
    if (_sleepBlockedPackages.contains(pkg)) {
      _sleepBlockedPackages.remove(pkg);
    } else {
      _sleepBlockedPackages.add(pkg);
    }
    _saveSettings();
    notifyListeners();
  }

  String get formattedElapsed {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get elapsedHours => _elapsed.inMinutes / 60.0;

  String get formattedCountdown {
    if (_countdownToSleep == null) return '';
    final h = _countdownToSleep!.inHours;
    final m = _countdownToSleep!.inMinutes.remainder(60);
    final s = _countdownToSleep!.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get averageSleepHours {
    if (_sleepHistory.isEmpty) return 0;
    final total = _sleepHistory.fold<double>(0, (sum, s) => sum + s.totalHours);
    return total / _sleepHistory.length;
  }

  int get averageQuality {
    if (_sleepHistory.isEmpty) return 0;
    final total = _sleepHistory.fold<int>(0, (sum, s) => sum + s.qualityScore);
    return total ~/ _sleepHistory.length;
  }

  double get averageBedtimeHour {
    if (_sleepHistory.isEmpty) return 23;
    final total = _sleepHistory.fold<double>(0, (sum, s) {
      var h = s.bedtime.hour.toDouble() + s.bedtime.minute / 60.0;
      if (h < 12) h += 24; // late night normalization
      return sum + h;
    });
    return (total / _sleepHistory.length) % 24;
  }

  double get averageWakeHour {
    final completed = _sleepHistory.where((s) => s.wakeTime != null).toList();
    if (completed.isEmpty) return 7;
    final total = completed.fold<double>(0, (sum, s) {
      return sum + s.wakeTime!.hour.toDouble() + s.wakeTime!.minute / 60.0;
    });
    return total / completed.length;
  }

  int get sleepStreak {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final hasSession =
          _sleepHistory.any((s) => s.date == dateStr && s.isCompleted);
      if (hasSession) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  List<WeeklySleepData> get weeklyData {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <WeeklySleepData>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final session = _sleepHistory.where((s) => s.date == dateStr).firstOrNull;
      result.add(WeeklySleepData(
        dayLabel: days[date.weekday - 1],
        hours: session?.totalHours ?? 0,
        quality: session?.qualityScore ?? 0,
      ));
    }
    return result;
  }

  // --- AI Suggestions ---
  List<SleepSuggestion> get aiSuggestions {
    final suggestions = <SleepSuggestion>[];
    if (_sleepHistory.isEmpty) {
      suggestions.add(const SleepSuggestion(
        title: 'Start tracking your sleep',
        description:
            'Log your first sleep session to get personalized insights.',
        icon: '??',
        type: SuggestionType.habit,
      ));
      return suggestions;
    }

    final avgHours = averageSleepHours;
    final avgQuality = averageQuality;
    final avgBed = averageBedtimeHour;

    // Duration suggestions
    if (avgHours < 6) {
      suggestions.add(const SleepSuggestion(
        title: 'You need more sleep',
        description:
            'Your average is under 6 hours. Adults need 7-9 hours for optimal performance and health.',
        icon: '??',
        type: SuggestionType.warning,
      ));
    } else if (avgHours < 7) {
      suggestions.add(const SleepSuggestion(
        title: 'Slightly under target',
        description:
            'Try going to bed 30 minutes earlier to reach the recommended 7-9 hour range.',
        icon: '??',
        type: SuggestionType.bedtime,
      ));
    } else if (avgHours > 9.5) {
      suggestions.add(const SleepSuggestion(
        title: 'Oversleeping detected',
        description:
            'Sleeping more than 9 hours regularly can cause grogginess. Try setting a consistent wake-up time.',
        icon: '?',
        type: SuggestionType.wakeup,
      ));
    }

    // Bedtime consistency
    if (avgBed > 1 && avgBed < 5) {
      suggestions.add(const SleepSuggestion(
        title: 'Late bedtimes',
        description:
            'You tend to sleep after 1 AM. Going to bed before midnight improves deep sleep and recovery.',
        icon: '??',
        type: SuggestionType.bedtime,
      ));
    }

    // Quality
    if (avgQuality < 60) {
      suggestions.add(const SleepSuggestion(
        title: 'Improve sleep quality',
        description:
            'Avoid screens 1 hour before bed, keep your room cool (18-20�C), and try a relaxation routine.',
        icon: '??',
        type: SuggestionType.quality,
      ));
    } else if (avgQuality >= 80) {
      suggestions.add(const SleepSuggestion(
        title: 'Great sleep quality!',
        description:
            'Your sleep quality is excellent. Keep up your current routine to maintain this.',
        icon: '??',
        type: SuggestionType.quality,
      ));
    }

    // Consistency tip
    if (_sleepHistory.length >= 3) {
      final bedtimes = _sleepHistory.take(7).map((s) {
        var h = s.bedtime.hour.toDouble() + s.bedtime.minute / 60.0;
        if (h < 12) h += 24;
        return h;
      }).toList();
      final maxBed = bedtimes.reduce(max);
      final minBed = bedtimes.reduce(min);
      if (maxBed - minBed > 2.5) {
        suggestions.add(const SleepSuggestion(
          title: 'Inconsistent bedtimes',
          description:
              'Your bedtime varies by over 2.5 hours. A consistent schedule helps regulate your circadian rhythm.',
          icon: '??',
          type: SuggestionType.habit,
        ));
      }
    }

    // Streak motivation
    if (sleepStreak >= 7) {
      suggestions.add(SleepSuggestion(
        title: '$sleepStreak-day streak!',
        description:
            'You have been consistently tracking sleep. This habit is helping your health.',
        icon: '??',
        type: SuggestionType.habit,
      ));
    }

    return suggestions;
  }

  // --- Actions ---
  SleepProvider() {
    _loadHistory();
    _loadSettings();
    _loadDreamJournal();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _targetHours = prefs.getInt('sleep_target_hours') ?? 8;
      _alarmEnabled = prefs.getBool('sleep_alarm_enabled') ?? false;
      _sleepBlockEnabled = prefs.getBool('sleep_block_enabled') ?? false;
      _sleepBlockAll = prefs.getBool('sleep_block_all') ?? false;
      _recordingEnabled = prefs.getBool('sleep_recording_enabled') ?? false;
      _silenceThreshold = prefs.getDouble('sleep_silence_threshold') ?? 35;
      final pkgsStr = prefs.getString('sleep_blocked_packages');
      if (pkgsStr != null && pkgsStr.isNotEmpty) {
        _sleepBlockedPackages = pkgsStr.split(',');
      }
      final wakeH = prefs.getInt('sleep_wake_hour');
      final wakeM = prefs.getInt('sleep_wake_minute');
      if (wakeH != null) {
        _wakeUpTime = TimeOfDay(hour: wakeH, minute: wakeM ?? 0);
      }
      final bedH = prefs.getInt('sleep_bed_hour');
      final bedM = prefs.getInt('sleep_bed_minute');
      if (bedH != null) {
        _bedtimeGoal = TimeOfDay(hour: bedH, minute: bedM ?? 0);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('sleep_target_hours', _targetHours);
      prefs.setBool('sleep_alarm_enabled', _alarmEnabled);
      prefs.setBool('sleep_block_enabled', _sleepBlockEnabled);
      prefs.setBool('sleep_block_all', _sleepBlockAll);
      prefs.setBool('sleep_recording_enabled', _recordingEnabled);
      prefs.setDouble('sleep_silence_threshold', _silenceThreshold);
      prefs.setString(
          'sleep_blocked_packages', _sleepBlockedPackages.join(','));
      if (_wakeUpTime != null) {
        prefs.setInt('sleep_wake_hour', _wakeUpTime!.hour);
        prefs.setInt('sleep_wake_minute', _wakeUpTime!.minute);
      }
      if (_bedtimeGoal != null) {
        prefs.setInt('sleep_bed_hour', _bedtimeGoal!.hour);
        prefs.setInt('sleep_bed_minute', _bedtimeGoal!.minute);
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sleep_sessions (
          id TEXT PRIMARY KEY,
          bedtime INTEGER NOT NULL,
          wake_time INTEGER,
          quality_score INTEGER DEFAULT 0,
          total_hours REAL DEFAULT 0,
          rem_hours REAL DEFAULT 0,
          core_hours REAL DEFAULT 0,
          deep_hours REAL DEFAULT 0,
          light_hours REAL DEFAULT 0,
          date TEXT NOT NULL,
          is_completed INTEGER DEFAULT 0,
          notes TEXT,
          target_hours INTEGER DEFAULT 8
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sleep_recordings (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          label TEXT DEFAULT 'Noise',
          timestamp INTEGER NOT NULL,
          duration_seconds INTEGER DEFAULT 0,
          peak_decibels REAL DEFAULT 0,
          emoji TEXT
        )
      ''');

      final maps =
          await db.query('sleep_sessions', orderBy: 'bedtime DESC', limit: 30);
      _sleepHistory = maps.map((m) => SleepSession.fromMap(m)).toList();
      if (_sleepHistory.isNotEmpty) _lastSession = _sleepHistory.first;
      notifyListeners();
    } catch (_) {}
  }

  void setTargetHours(int hours) {
    _targetHours = hours.clamp(4, 12);
    _saveSettings();
    notifyListeners();
  }

  void setWakeUpTime(TimeOfDay time) {
    _wakeUpTime = time;
    _saveSettings();
    _scheduleAlarm();
    notifyListeners();
  }

  void setBedtimeGoal(TimeOfDay time) {
    _bedtimeGoal = time;
    _saveSettings();
    _startBedtimeCountdown();
    notifyListeners();
  }

  void setAlarmEnabled(bool enabled) {
    _alarmEnabled = enabled;
    _saveSettings();
    if (enabled) _scheduleAlarm();
    notifyListeners();
  }

  void _scheduleAlarm() {
    if (_wakeUpTime == null || !_alarmEnabled) return;
    // Use platform channel to schedule native alarm
    try {
      const channel = MethodChannel('com.monojog.app/focus');
      channel.invokeMethod('scheduleAlarm', {
        'hour': _wakeUpTime!.hour,
        'minute': _wakeUpTime!.minute,
      });
    } catch (_) {}
  }

  void _startBedtimeCountdown() {
    _countdownTimer?.cancel();
    if (_bedtimeGoal == null) return;

    final now = DateTime.now();
    var bedTarget = DateTime(
        now.year, now.month, now.day, _bedtimeGoal!.hour, _bedtimeGoal!.minute);
    if (bedTarget.isBefore(now)) {
      bedTarget = bedTarget.add(const Duration(days: 1));
    }

    _countdownToSleep = bedTarget.difference(now);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = bedTarget.difference(DateTime.now());
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        _countdownToSleep = null;
      } else {
        _countdownToSleep = remaining;
      }
      notifyListeners();
    });
  }

  /// Returns null on success, or a conflict message if another session is active.
  String? startSleep() {
    if (_isSleeping) return null;
    // Cross-provider session sync
    if (FocusProvider.isAnySessionActive) {
      return 'A ${FocusProvider.globalActiveSession} session is active. End it first.';
    }
    FocusProvider.claimSession('sleep');

    _isSleeping = true;
    _bedtime = DateTime.now();
    _elapsed = Duration.zero;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownToSleep = null;

    // Activate app blocking during sleep
    if (_sleepBlockEnabled) {
      _startSleepBlocking();
    }

    // Start audio recording
    if (_recordingEnabled) {
      _startSleepRecording();
    }

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_bedtime!);
      notifyListeners();
    });
    notifyListeners();
    return null;
  }

  Future<void> _startSleepBlocking() async {
    try {
      if (_sleepBlockAll) {
        // Block all apps (strict sleep)
        await _platform.invokeMethod('startFocusMode', {
          'blockedApps': <String>[], // empty = block all in strict
          'durationMinutes': _targetHours * 60,
        });
      } else if (_sleepBlockedPackages.isNotEmpty) {
        await _platform.invokeMethod('startFocusMode', {
          'blockedApps': _sleepBlockedPackages,
          'durationMinutes': _targetHours * 60,
        });
      }
      // Enable DND for sleep
      await _platform.invokeMethod('enableDND');
    } catch (e) {
      debugPrint('Sleep blocking failed: $e');
    }
  }

  Future<void> _stopSleepBlocking() async {
    try {
      await _platform.invokeMethod('stopFocusMode');
      await _platform.invokeMethod('disableDND');
    } catch (e) {
      debugPrint('Stop sleep blocking failed: $e');
    }
  }

  Future<void> stopSleep() async {
    if (!_isSleeping || _bedtime == null) return;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _isSleeping = false;

    // Stop app blocking
    if (_sleepBlockEnabled) {
      await _stopSleepBlocking();
    }
    // Stop sound recording
    await _stopSleepRecording();
    FocusProvider.releaseSession('sleep');

    final wakeTime = DateTime.now();
    final totalHours = wakeTime.difference(_bedtime!).inMinutes / 60.0;

    final rng = Random();
    final remPercent = 0.20 + rng.nextDouble() * 0.05;
    final deepPercent = 0.15 + rng.nextDouble() * 0.10;
    final corePercent = 0.40 + rng.nextDouble() * 0.10;
    final lightPercent = 1.0 - remPercent - deepPercent - corePercent;

    int quality = 50;
    if (totalHours >= 7 && totalHours <= 9) {
      quality += 30;
    } else if (totalHours >= 6) {
      quality += 15;
    } else if (totalHours < 5) {
      quality -= 20;
    }
    quality += (deepPercent * 40).round();
    quality += (remPercent * 20).round();
    quality = quality.clamp(0, 100);

    final session = SleepSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bedtime: _bedtime!,
      wakeTime: wakeTime,
      qualityScore: quality,
      totalHours: double.parse(totalHours.toStringAsFixed(2)),
      remHours: double.parse((totalHours * remPercent).toStringAsFixed(2)),
      coreHours: double.parse((totalHours * corePercent).toStringAsFixed(2)),
      deepHours: double.parse((totalHours * deepPercent).toStringAsFixed(2)),
      lightHours: double.parse((totalHours * lightPercent).toStringAsFixed(2)),
      date: DateFormat('yyyy-MM-dd').format(_bedtime!),
      isCompleted: true,
      targetHours: _targetHours,
    );

    try {
      final db = await DatabaseService.instance.database;
      await db.insert('sleep_sessions', session.toMap());
    } catch (_) {}

    // Log to history
    try {
      await HistoryService.instance.logEvent(
        'sleep_session',
        'Sleep session completed',
        '${totalHours.toStringAsFixed(1)}h sleep, quality $quality%',
        duration: (totalHours * 60).round(),
        xp: 5 + (totalHours >= 7 ? 10 : 0),
        gold: quality >= 80 ? 3 : 1,
        metadata: {
          'quality': quality,
          'total_hours': totalHours,
          'deep_hours': totalHours * deepPercent,
          'rem_hours': totalHours * remPercent,
          'block_enabled': _sleepBlockEnabled,
          'block_all': _sleepBlockAll,
        },
      );
    } catch (_) {}

    _lastSession = session;
    _sleepHistory.insert(0, session);
    _bedtime = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('sleep_sessions', where: 'id = ?', whereArgs: [id]);
      // Also delete recordings for this session
      final recs = await db
          .query('sleep_recordings', where: 'session_id = ?', whereArgs: [id]);
      for (final r in recs) {
        final path = r['file_path'] as String?;
        if (path != null) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
      await db
          .delete('sleep_recordings', where: 'session_id = ?', whereArgs: [id]);
      _sleepHistory.removeWhere((s) => s.id == id);
      if (_lastSession?.id == id) {
        _lastSession = _sleepHistory.isNotEmpty ? _sleepHistory.first : null;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ══════════════════════════════════════════
  // SLEEP SOUND RECORDING
  // ══════════════════════════════════════════

  void setRecordingEnabled(bool v) {
    _recordingEnabled = v;
    _saveSettings();
    notifyListeners();
  }

  void setSilenceThreshold(double v) {
    _silenceThreshold = v.clamp(20, 60);
    _saveSettings();
    notifyListeners();
  }

  Future<void> _startSleepRecording() async {
    if (!_recordingEnabled) return;
    try {
      _audioRecorder = AudioRecorder();
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        _recordingEnabled = false;
        notifyListeners();
        return;
      }

      _recordings = [];
      _noiseTimeline = [];
      _recordingSegmentCount = 0;

      // Start monitoring ambient noise every 5 seconds
      _recordingMonitor = Timer.periodic(const Duration(seconds: 5), (_) async {
        await _monitorNoise();
      });
    } catch (e) {
      debugPrint('Failed to start sleep recording: $e');
    }
  }

  Future<void> _monitorNoise() async {
    if (!_isSleeping || _audioRecorder == null) return;

    try {
      // Get amplitude (this works even when not recording)
      if (_isRecording) {
        // Check if we should stop
        final amp = await _audioRecorder!.getAmplitude();
        final db = _dbFromAmplitude(amp.current);
        if (db > _currentMaxDb) _currentMaxDb = db;

        // Record for at least 10 seconds, then stop if quiet
        final elapsed =
            DateTime.now().difference(_currentRecordStart ?? DateTime.now());
        if (elapsed.inSeconds >= 10 && db < _silenceThreshold) {
          await _stopSegmentRecording();
        }
        // Max 60 seconds per segment
        if (elapsed.inSeconds >= 60) {
          await _stopSegmentRecording();
        }
      } else {
        // Start a short probe recording to check levels
        final dir = await getApplicationDocumentsDirectory();
        final probePath =
            '${dir.path}/sleep_probe_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 22050,
          ),
          path: probePath,
        );

        // Brief pause to get amplitude
        await Future.delayed(const Duration(milliseconds: 500));
        final amp = await _audioRecorder!.getAmplitude();
        final db = _dbFromAmplitude(amp.current);
        _noiseTimeline.add(db);

        if (db >= _silenceThreshold) {
          // Sound detected - keep recording this segment
          _isRecording = true;
          _currentRecordPath = probePath;
          _currentMaxDb = db;
          _currentRecordStart = DateTime.now();
          _recordingSegmentCount++;
          notifyListeners();
        } else {
          // Quiet, stop probe
          await _audioRecorder!.stop();
          try {
            final f = File(probePath);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Noise monitor error: $e');
    }
  }

  Future<void> _stopSegmentRecording() async {
    if (!_isRecording || _audioRecorder == null) return;
    try {
      final path = await _audioRecorder!.stop();
      _isRecording = false;

      if (path != null && _currentRecordPath != null && _bedtime != null) {
        final duration = _currentRecordStart != null
            ? DateTime.now().difference(_currentRecordStart!).inSeconds
            : 0;

        final label = SleepRecording.detectLabel(
            _noiseTimeline.isNotEmpty ? _noiseTimeline.last : 0, _currentMaxDb);

        final recording = SleepRecording(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: _bedtime!.millisecondsSinceEpoch.toString(),
          filePath: _currentRecordPath!,
          label: label,
          timestamp: _currentRecordStart ?? DateTime.now(),
          durationSeconds: duration,
          peakDecibels: _currentMaxDb,
          emoji: SleepRecording.detectEmoji(label),
        );
        _recordings.add(recording);

        // Save to DB
        try {
          final db = await DatabaseService.instance.database;
          await db.insert('sleep_recordings', recording.toMap());
        } catch (_) {}
      }

      _currentRecordPath = null;
      _currentRecordStart = null;
      _currentMaxDb = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Stop segment error: $e');
    }
  }

  Future<void> _stopSleepRecording() async {
    _recordingMonitor?.cancel();
    _recordingMonitor = null;
    if (_isRecording) {
      await _stopSegmentRecording();
    }
    try {
      _audioRecorder?.dispose();
    } catch (_) {}
    _audioRecorder = null;
    _isRecording = false;
  }

  double _dbFromAmplitude(double amplitude) {
    // amplitude is typically in range -160..0 from the recorder
    // Convert to a positive dB-like scale (rough approximation)
    if (amplitude <= -160) return 0;
    return (amplitude + 160).clamp(0, 120).toDouble();
  }

  /// Load recordings for a specific session
  Future<List<SleepRecording>> getRecordingsForSession(String sessionId) async {
    try {
      final db = await DatabaseService.instance.database;
      final maps = await db.query('sleep_recordings',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'timestamp ASC');
      return maps.map((m) => SleepRecording.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get noise summary for current session
  NightNoiseSummary? get noiseSummary {
    if (_noiseTimeline.isEmpty) return null;
    final avg = _noiseTimeline.reduce((a, b) => a + b) / _noiseTimeline.length;
    final maxDb = _noiseTimeline.reduce(max);
    String note;
    if (maxDb > 70) {
      note = 'Loud noises detected. Consider checking snoring patterns.';
    } else if (maxDb > 50) {
      note = 'Moderate noise levels. Your room is slightly noisy.';
    } else {
      note = 'Quiet night! Great sleeping environment.';
    }
    return NightNoiseSummary(
      avgDecibels: avg,
      maxDecibels: maxDb,
      totalRecordings: _recordings.length,
      noiseTimeline: List.from(_noiseTimeline),
      healthNote: note,
    );
  }

  // ══════════════════════════════════════════
  // DREAM JOURNAL
  // ══════════════════════════════════════════

  Future<void> _loadDreamJournal() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dream_journal (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          mood TEXT,
          tags TEXT,
          lucid INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      final maps = await db.query('dream_journal',
          orderBy: 'created_at DESC', limit: 50);
      _dreamJournal = maps.map((m) => DreamEntry.fromMap(m)).toList();
    } catch (_) {}
  }

  Future<void> addDream({
    required String title,
    String? description,
    String? mood,
    List<String> tags = const [],
    bool lucid = false,
  }) async {
    final entry = DreamEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      title: title,
      description: description,
      mood: mood ?? '😴',
      tags: tags,
      lucid: lucid,
      createdAt: DateTime.now(),
    );
    _dreamJournal.insert(0, entry);
    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      await db.insert('dream_journal', entry.toMap());
    } catch (_) {}
  }

  Future<void> deleteDream(String id) async {
    _dreamJournal.removeWhere((d) => d.id == id);
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('dream_journal', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  // ══════════════════════════════════════════
  // AMBIENT SOUNDS
  // ══════════════════════════════════════════

  void setAmbientSound(String? soundId) {
    _activeAmbientSound = soundId;
    notifyListeners();
  }

  void setAmbientVolume(double v) {
    _ambientVolume = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setAmbientTimer(int minutes) {
    _ambientTimerMinutes = minutes;
    _ambientAutoStop?.cancel();
    if (minutes > 0 && _activeAmbientSound != null) {
      _ambientAutoStop = Timer(Duration(minutes: minutes), () {
        _activeAmbientSound = null;
        _ambientAutoStop = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void stopAmbientSound() {
    _activeAmbientSound = null;
    _ambientAutoStop?.cancel();
    _ambientAutoStop = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════
  // WIND-DOWN ROUTINE
  // ══════════════════════════════════════════

  void setWindDownMinutes(int m) {
    _windDownMinutes = m.clamp(5, 120);
    _saveSettings();
    notifyListeners();
  }

  void startWindDown() {
    _windDownActive = true;
    _windDownSecondsLeft = _windDownMinutes * 60;
    _windDownTimer?.cancel();
    _windDownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_windDownSecondsLeft > 0) {
        _windDownSecondsLeft--;
        notifyListeners();
      } else {
        stopWindDown();
        // Auto-start sleep when wind-down completes
        startSleep();
      }
    });
    notifyListeners();
  }

  void stopWindDown() {
    _windDownActive = false;
    _windDownSecondsLeft = 0;
    _windDownTimer?.cancel();
    _windDownTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    _recordingMonitor?.cancel();
    _windDownTimer?.cancel();
    _ambientAutoStop?.cancel();
    try {
      _audioRecorder?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
