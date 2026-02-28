import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:monojog/services/database_service.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class HistoryEntry {
  final String id;
  final String type;
  final String title;
  final String description;
  final int? durationMinutes;
  final int xpEarned;
  final int goldEarned;
  final String? metadata;
  final String date;
  final int createdAt;

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.durationMinutes,
    this.xpEarned = 0,
    this.goldEarned = 0,
    this.metadata,
    required this.date,
    required this.createdAt,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      durationMinutes: map['duration_minutes'] as int?,
      xpEarned: (map['xp_earned'] as int?) ?? 0,
      goldEarned: (map['gold_earned'] as int?) ?? 0,
      metadata: map['metadata'] as String?,
      date: map['date'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'xp_earned': xpEarned,
      'gold_earned': goldEarned,
      'metadata': metadata,
      'date': date,
      'created_at': createdAt,
    };
  }

  HistoryEntry copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    int? durationMinutes,
    bool clearDuration = false,
    int? xpEarned,
    int? goldEarned,
    String? metadata,
    bool clearMetadata = false,
    String? date,
    int? createdAt,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes:
          clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      xpEarned: xpEarned ?? this.xpEarned,
      goldEarned: goldEarned ?? this.goldEarned,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'HistoryEntry(id: $id, type: $type, title: $title)';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class HistoryService {
  static final HistoryService instance = HistoryService._();
  HistoryService._();

  static const _uuid = Uuid();
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  // ---- Table setup --------------------------------------------------------

  Future<void> ensureTable() async {
    final db = await DatabaseService.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_history (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_minutes INTEGER,
        xp_earned INTEGER DEFAULT 0,
        gold_earned INTEGER DEFAULT 0,
        metadata TEXT,
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // ---- Logging ------------------------------------------------------------

  Future<HistoryEntry> logEvent(
    String type,
    String title,
    String description, {
    int? duration,
    int xp = 0,
    int gold = 0,
    Map<String, dynamic>? metadata,
    DateTime? date,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now();
    final entry = HistoryEntry(
      id: _uuid.v4(),
      type: type,
      title: title,
      description: description,
      durationMinutes: duration,
      xpEarned: xp,
      goldEarned: gold,
      metadata: metadata != null ? jsonEncode(metadata) : null,
      date: _dateFmt.format(date ?? now),
      createdAt: now.millisecondsSinceEpoch,
    );
    await db.insert(
      'user_history',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return entry;
  }

  // ---- Queries ------------------------------------------------------------

  Future<List<HistoryEntry>> getHistory({
    int limit = 50,
    String? type,
    String? date,
  }) async {
    final db = await DatabaseService.instance.database;

    final where = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (date != null) {
      where.add('date = ?');
      args.add(date);
    }

    final rows = await db.query(
      'user_history',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<List<HistoryEntry>> getHistoryByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'user_history',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateFmt.format(start), _dateFmt.format(end)],
      orderBy: 'created_at DESC',
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  // ---- Summaries ----------------------------------------------------------

  Future<Map<String, dynamic>> getTodaySummary() async {
    final today = _dateFmt.format(DateTime.now());
    return _buildSummary(dateFilter: 'date = ?', dateArgs: [today]);
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _buildSummary(
      dateFilter: 'date >= ? AND date <= ?',
      dateArgs: [_dateFmt.format(weekAgo), _dateFmt.format(now)],
    );
  }

  Future<Map<String, dynamic>> getAllTimeSummary() async {
    return _buildSummary();
  }

  Future<Map<String, dynamic>> _buildSummary({
    String? dateFilter,
    List<dynamic>? dateArgs,
  }) async {
    final db = await DatabaseService.instance.database;

    String whereClause(String extraType) {
      final parts = <String>[];
      parts.add('type = ?');
      if (dateFilter != null) parts.add(dateFilter);
      return parts.join(' AND ');
    }

    List<dynamic> whereArgs(String typeVal) {
      return [typeVal, ...?dateArgs];
    }

    // Focus minutes
    final focusRows = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total '
      'FROM user_history WHERE ${whereClause('focus_session')}',
      whereArgs('focus_session'),
    );
    final focusMinutes = focusRows.first['total'] as int? ?? 0;

    // Sleep hours (stored as duration_minutes)
    final sleepRows = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total '
      'FROM user_history WHERE ${whereClause('sleep_session')}',
      whereArgs('sleep_session'),
    );
    final sleepMinutes = sleepRows.first['total'] as int? ?? 0;

    // Habit completions count
    final habitRows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt '
      'FROM user_history WHERE ${whereClause('habit_completion')}',
      whereArgs('habit_completion'),
    );
    final habitsDone = habitRows.first['cnt'] as int? ?? 0;

    // Task completions count
    final taskRows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt '
      'FROM user_history WHERE ${whereClause('task_completion')}',
      whereArgs('task_completion'),
    );
    final tasksDone = taskRows.first['cnt'] as int? ?? 0;

    // XP & Gold totals
    final baseWhere = dateFilter != null ? 'WHERE $dateFilter' : '';
    final baseArgs = dateArgs ?? [];
    final totalsRows = await db.rawQuery(
      'SELECT COALESCE(SUM(xp_earned), 0) AS xp, '
      'COALESCE(SUM(gold_earned), 0) AS gold '
      'FROM user_history $baseWhere',
      baseArgs,
    );
    final xpTotal = totalsRows.first['xp'] as int? ?? 0;
    final goldTotal = totalsRows.first['gold'] as int? ?? 0;

    return {
      'focus_minutes': focusMinutes,
      'sleep_hours': (sleepMinutes / 60).toStringAsFixed(1),
      'habits_done': habitsDone,
      'tasks_done': tasksDone,
      'xp_total': xpTotal,
      'gold_total': goldTotal,
    };
  }

  // ---- Export / Sync ------------------------------------------------------

  Future<String> exportToJson() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('user_history', orderBy: 'created_at DESC');
    final entries =
        rows.map(HistoryEntry.fromMap).map((e) => e.toMap()).toList();
    return jsonEncode(entries);
  }

  /// Placeholder for future Firebase integration.
  /// Stores a sync summary in SharedPreferences keyed by the user id.
  Future<void> syncToFirebase(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final summary = await getAllTimeSummary();
    final payload = {
      'last_sync': DateTime.now().toIso8601String(),
      'summary': summary,
    };
    await prefs.setString(
      'firebase_sync_$userId',
      jsonEncode(payload),
    );
  }

  // ---- Maintenance --------------------------------------------------------

  Future<void> clearHistory() async {
    final db = await DatabaseService.instance.database;
    await db.delete('user_history');
  }
}
