import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:monojog/models/study_session.dart';
import 'package:monojog/services/database_service.dart';

class StudyProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<StudySession> _todaySessions = [];
  StudySession? _currentSession;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _totalMinutesToday = 0;
  int _currentStreak = 0;
  bool _isStudying = false;
  String _currentSubject = 'General Study';

  // Getters
  List<StudySession> get todaySessions => _todaySessions;
  StudySession? get currentSession => _currentSession;
  int get elapsedSeconds => _elapsedSeconds;
  int get totalMinutesToday => _totalMinutesToday;
  int get currentStreak => _currentStreak;
  bool get isStudying => _isStudying;
  String get currentSubject => _currentSubject;

  String get formattedElapsedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedTotalToday {
    final hours = _totalMinutesToday ~/ 60;
    final minutes = _totalMinutesToday % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  StudyProvider() {
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final sessions = await _db.getStudySessionsByDate(today);
    _todaySessions = sessions.map((s) => StudySession.fromMap(s)).toList();
    _totalMinutesToday = await _db.getTotalStudyMinutesToday();
    _currentStreak = await _db.getCurrentStreak();
    notifyListeners();
  }

  void setSubject(String subject) {
    _currentSubject = subject;
    notifyListeners();
  }

  Future<void> startStudySession({String? subject}) async {
    if (_isStudying) return;

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    _currentSession = StudySession(
      id: _uuid.v4(),
      subject: subject ?? _currentSubject,
      startTime: now,
      date: today,
    );

    _isStudying = true;
    _elapsedSeconds = 0;

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });

    // Save to database
    await _db.insertStudySession(_currentSession!.toMap());

    notifyListeners();
  }

  Future<void> stopStudySession() async {
    if (!_isStudying || _currentSession == null) return;

    _timer?.cancel();
    _timer = null;

    final now = DateTime.now();
    final durationMinutes = _elapsedSeconds ~/ 60;

    final completedSession = _currentSession!.copyWith(
      endTime: now,
      durationMinutes: durationMinutes,
      isCompleted: true,
    );

    // Update in database
    await _db.updateStudySession(completedSession.id, completedSession.toMap());

    // Update daily stats
    await _updateDailyStats(durationMinutes);

    _isStudying = false;
    _currentSession = null;
    _elapsedSeconds = 0;

    // Reload today's data
    await _loadTodayData();

    notifyListeners();
  }

  Future<void> _updateDailyStats(int additionalMinutes) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existingStats = await _db.getDailyStats(today);

    if (existingStats != null) {
      await _db.insertOrUpdateDailyStats({
        'id': existingStats['id'],
        'date': today,
        'total_study_minutes':
            (existingStats['total_study_minutes'] as int) + additionalMinutes,
        'total_focus_minutes': existingStats['total_focus_minutes'],
        'sessions_completed': (existingStats['sessions_completed'] as int) + 1,
        'streak_days': existingStats['streak_days'],
      });
    } else {
      await _db.insertOrUpdateDailyStats({
        'id': _uuid.v4(),
        'date': today,
        'total_study_minutes': additionalMinutes,
        'total_focus_minutes': 0,
        'sessions_completed': 1,
        'streak_days': 1,
      });
    }
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteStudySession(id);
    await _loadTodayData();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    return await _db.getWeeklyStats();
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    return await _db.getMonthlyStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
