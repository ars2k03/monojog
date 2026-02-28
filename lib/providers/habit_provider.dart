import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:monojog/models/habit.dart';
import 'package:monojog/services/database_service.dart';
import 'package:monojog/services/history_service.dart';

class HabitProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Habit> _habits = [];
  Map<String, Set<String>> _completions = {}; // habitId -> set of date strings

  List<Habit> get habits => _habits.where((h) => !h.archived).toList();
  List<Habit> get archivedHabits => _habits.where((h) => h.archived).toList();
  int get activeCount => habits.length;

  HabitProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _ensureTable();
    await _loadHabits();
    await _loadCompletions();
    _recalcStreaks();
  }

  // ── DB Table creation (migration-safe) ──
  Future<void> _ensureTable() async {
    final db = await _db.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits_v2 (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        emoji TEXT DEFAULT '✅',
        color TEXT DEFAULT '#7C4DFF',
        repeat_type INTEGER DEFAULT 0,
        custom_days TEXT DEFAULT '',
        reminder_hour INTEGER,
        reminder_minute INTEGER,
        category INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        best_streak INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        archived INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER DEFAULT 1,
        UNIQUE(habit_id, date)
      )
    ''');
  }

  // ── Load ──
  Future<void> _loadHabits() async {
    final db = await _db.database;
    final rows = await db.query('habits_v2', orderBy: 'created_at ASC');
    _habits = rows.map((r) => Habit.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> _loadCompletions() async {
    final db = await _db.database;
    final rows = await db.query('habit_completions', where: 'completed = 1');
    _completions = {};
    for (final r in rows) {
      final hid = r['habit_id'] as String;
      final date = r['date'] as String;
      _completions.putIfAbsent(hid, () => {}).add(date);
    }
    notifyListeners();
  }

  // ── Queries ──
  bool isCompletedOn(String habitId, String date) {
    return _completions[habitId]?.contains(date) ?? false;
  }

  bool isCompletedToday(String habitId) {
    return isCompletedOn(habitId, _todayStr());
  }

  int completedTodayCount() {
    final today = _todayStr();
    return habits.where((h) {
      if (!h.isScheduledFor(DateTime.now().weekday)) return false;
      return isCompletedOn(h.id, today);
    }).length;
  }

  int scheduledTodayCount() {
    return habits.where((h) => h.isScheduledFor(DateTime.now().weekday)).length;
  }

  double get todayProgress {
    final scheduled = scheduledTodayCount();
    if (scheduled == 0) return 0;
    return completedTodayCount() / scheduled;
  }

  /// Get completions for a habit in date range (for calendar / weekly grid)
  Set<String> getCompletionsForHabit(String habitId) {
    return _completions[habitId] ?? {};
  }

  /// Get completed dates for a given month
  List<DateTime> getMonthCompletions(String habitId, int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final dates = _completions[habitId] ?? {};
    return dates
        .where((d) => d.startsWith(prefix))
        .map((d) => DateTime.parse(d))
        .toList()
      ..sort();
  }

  /// Weekly data: returns list of 7 booleans (Mon-Sun) for given week
  List<bool> getWeekCompletions(String habitId, DateTime weekStart) {
    final result = <bool>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dateStr = _dateStr(day);
      result.add(isCompletedOn(habitId, dateStr));
    }
    return result;
  }

  /// Get the last N days completion map for a habit
  List<MapEntry<DateTime, bool>> getRecentDays(String habitId, int days) {
    final result = <MapEntry<DateTime, bool>>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      result.add(MapEntry(day, isCompletedOn(habitId, _dateStr(day))));
    }
    return result;
  }

  // ── CRUD ──
  Future<void> addHabit(Habit habit) async {
    final db = await _db.database;
    await db.insert('habits_v2', habit.toMap());
    await _loadHabits();
  }

  Future<Habit> createHabit({
    required String title,
    String emoji = '✅',
    String color = '#7C4DFF',
    HabitRepeat repeat = HabitRepeat.daily,
    List<int> customDays = const [],
    int? reminderHour,
    int? reminderMinute,
    HabitCategory category = HabitCategory.custom,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      emoji: emoji,
      color: color,
      repeat: repeat,
      customDays: customDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      category: category,
    );
    await addHabit(habit);
    return habit;
  }

  Future<void> createFromTemplate(HabitTemplate template) async {
    await createHabit(
      title: template.title,
      emoji: template.emoji,
      color: template.color,
      category: template.category,
    );
  }

  Future<void> createFromPack(HabitTemplatePack pack) async {
    for (final t in pack.templates) {
      await createFromTemplate(t);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _db.database;
    await db.update('habits_v2', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
    await _loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    final db = await _db.database;
    await db.delete('habits_v2', where: 'id = ?', whereArgs: [id]);
    await db
        .delete('habit_completions', where: 'habit_id = ?', whereArgs: [id]);
    _completions.remove(id);
    await _loadHabits();
  }

  Future<void> archiveHabit(String id) async {
    final habit = _habits.firstWhere((h) => h.id == id);
    await updateHabit(habit.copyWith(archived: true));
  }

  // ── Toggle completion ──
  Future<void> toggleCompletion(String habitId, {String? date}) async {
    final d = date ?? _todayStr();
    final db = await _db.database;

    if (isCompletedOn(habitId, d)) {
      // Un-complete
      await db.delete('habit_completions',
          where: 'habit_id = ? AND date = ?', whereArgs: [habitId, d]);
      _completions[habitId]?.remove(d);
    } else {
      // Complete
      final cid = _uuid.v4();
      await db.insert('habit_completions', {
        'id': cid,
        'habit_id': habitId,
        'date': d,
        'completed': 1,
      });
      _completions.putIfAbsent(habitId, () => {}).add(d);

      // Log to history
      try {
        final habit = _habits.firstWhere((h) => h.id == habitId);
        HistoryService.instance.logEvent(
          'habit_completion',
          'Habit completed: ${habit.title}',
          '${habit.emoji} ${habit.title} on $d',
          xp: 5,
          gold: 2,
        );
      } catch (_) {}
    }

    await _recalcStreak(habitId);
    notifyListeners();
  }

  // ── Streaks ──
  Future<void> _recalcStreak(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final dates = (_completions[habitId] ?? {}).toList()..sort();
    if (dates.isEmpty) {
      await _updateStreaks(habitId, 0, habit.bestStreak);
      return;
    }

    int streak = 0;
    DateTime check = DateTime.now();
    // Check today first
    final todayStr = _dateStr(check);
    if (!dates.contains(todayStr)) {
      // Also check yesterday in case user hasn't done today yet
      final yesterdayStr = _dateStr(check.subtract(const Duration(days: 1)));
      if (!dates.contains(yesterdayStr)) {
        await _updateStreaks(habitId, 0, habit.bestStreak);
        return;
      }
      check = check.subtract(const Duration(days: 1));
    }

    // Count backwards
    while (true) {
      final ds = _dateStr(check);
      if (dates.contains(ds)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final best = streak > habit.bestStreak ? streak : habit.bestStreak;
    await _updateStreaks(habitId, streak, best);
  }

  Future<void> _updateStreaks(String habitId, int current, int best) async {
    final db = await _db.database;
    await db.update(
      'habits_v2',
      {'current_streak': current, 'best_streak': best},
      where: 'id = ?',
      whereArgs: [habitId],
    );
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx >= 0) {
      _habits[idx] =
          _habits[idx].copyWith(currentStreak: current, bestStreak: best);
    }
    notifyListeners();
  }

  void _recalcStreaks() {
    for (final h in _habits) {
      _recalcStreak(h.id);
    }
  }

  // ── Helpers ──
  String _todayStr() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
