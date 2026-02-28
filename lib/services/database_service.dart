import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monojog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _addProfileColumns(db);
    }
  }

  Future<void> _addProfileColumns(Database db) async {
    try {
      await db.execute(
          "ALTER TABLE user_profile ADD COLUMN username TEXT DEFAULT 'Friend'");
    } catch (_) {}
    try {
      await db.execute(
          'ALTER TABLE user_profile ADD COLUMN profile_image_path TEXT');
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_minutes INTEGER DEFAULT 0,
        date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        target_duration_minutes INTEGER NOT NULL,
        actual_duration_minutes INTEGER DEFAULT 0,
        date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        blocked_apps TEXT,
        phone_unlocks INTEGER DEFAULT 0,
        app_switches INTEGER DEFAULT 0,
        points_earned INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        id TEXT PRIMARY KEY,
        date TEXT UNIQUE NOT NULL,
        total_study_minutes INTEGER DEFAULT 0,
        total_focus_minutes INTEGER DEFAULT 0,
        sessions_completed INTEGER DEFAULT 0,
        streak_days INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE blocked_apps (
        id TEXT PRIMARY KEY,
        package_name TEXT UNIQUE NOT NULL,
        app_name TEXT NOT NULL,
        is_blocked INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createV2Tables(db);
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        total_points INTEGER DEFAULT 0,
        health INTEGER DEFAULT 50,
        max_health INTEGER DEFAULT 50,
        experience INTEGER DEFAULT 0,
        experience_to_next INTEGER DEFAULT 25,
        level INTEGER DEFAULT 1,
        gold INTEGER DEFAULT 0,
        gems INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        avatar_type TEXT DEFAULT 'warrior',
        total_study_minutes INTEGER DEFAULT 0,
        total_focus_minutes INTEGER DEFAULT 0,
        sessions_completed INTEGER DEFAULT 0,
        phone_unlocks INTEGER DEFAULT 0,
        username TEXT DEFAULT 'Friend',
        profile_image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        is_positive INTEGER DEFAULT 1,
        difficulty INTEGER DEFAULT 2,
        streak INTEGER DEFAULT 0,
        counter_up INTEGER DEFAULT 0,
        counter_down INTEGER DEFAULT 0,
        color TEXT DEFAULT '#7C3AED',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dailies (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        target_minutes INTEGER DEFAULT 30,
        is_done_today INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        difficulty INTEGER DEFAULT 2,
        color TEXT DEFAULT '#6366F1',
        created_at INTEGER NOT NULL,
        last_completed_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        is_done INTEGER DEFAULT 0,
        difficulty INTEGER DEFAULT 2,
        due_date TEXT,
        color TEXT DEFAULT '#06B6D4',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS badges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_at INTEGER,
        category TEXT DEFAULT 'study'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rewards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        cost INTEGER DEFAULT 0,
        type TEXT DEFAULT 'custom',
        is_purchased INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS brain_dumps (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        session_id TEXT,
        type TEXT DEFAULT 'general',
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert default profile if not exists
    final existing = await db.query('user_profile', where: 'id = 1');
    if (existing.isEmpty) {
      await db.insert('user_profile', {
        'id': 1,
        'total_points': 0,
        'health': 50,
        'max_health': 50,
        'experience': 0,
        'experience_to_next': 25,
        'level': 1,
        'gold': 0,
        'gems': 0,
        'current_streak': 0,
        'longest_streak': 0,
        'avatar_type': 'warrior',
        'total_study_minutes': 0,
        'total_focus_minutes': 0,
        'sessions_completed': 0,
        'phone_unlocks': 0,
      });
    }
  }

  // =============== USER PROFILE ===============
  Future<Map<String, dynamic>> getUserProfile() async {
    final db = await instance.database;
    final results = await db.query('user_profile', where: 'id = 1');
    if (results.isEmpty) {
      return {
        'id': 1,
        'level': 1,
        'health': 50,
        'max_health': 50,
        'gold': 0,
        'gems': 0,
        'experience': 0,
        'experience_to_next': 25
      };
    }
    return results.first;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('user_profile', data, where: 'id = 1');
  }

  // =============== HABITS ===============
  Future<int> insertHabit(Map<String, dynamic> habit) async {
    final db = await instance.database;
    return await db.insert('habits', habit);
  }

  Future<List<Map<String, dynamic>>> getHabits() async {
    final db = await instance.database;
    return await db.query('habits', orderBy: 'created_at DESC');
  }

  Future<int> updateHabit(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('habits', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // =============== DAILIES ===============
  Future<int> insertDaily(Map<String, dynamic> daily) async {
    final db = await instance.database;
    return await db.insert('dailies', daily);
  }

  Future<List<Map<String, dynamic>>> getDailies() async {
    final db = await instance.database;
    return await db.query('dailies', orderBy: 'created_at DESC');
  }

  Future<int> updateDaily(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('dailies', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDaily(String id) async {
    final db = await instance.database;
    return await db.delete('dailies', where: 'id = ?', whereArgs: [id]);
  }

  // =============== TODOS ===============
  Future<int> insertTodo(Map<String, dynamic> todo) async {
    final db = await instance.database;
    return await db.insert('todos', todo);
  }

  Future<List<Map<String, dynamic>>> getTodos() async {
    final db = await instance.database;
    return await db.query('todos', orderBy: 'created_at DESC');
  }

  Future<int> updateTodo(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('todos', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTodo(String id) async {
    final db = await instance.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // =============== BADGES ===============
  Future<void> insertBadge(Map<String, dynamic> badge) async {
    final db = await instance.database;
    await db.insert('badges', badge,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getBadges() async {
    final db = await instance.database;
    return await db.query('badges', orderBy: 'is_unlocked DESC, category');
  }

  Future<void> unlockBadge(String id) async {
    final db = await instance.database;
    await db.update(
        'badges',
        {
          'is_unlocked': 1,
          'unlocked_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  // =============== REWARDS ===============
  Future<void> insertReward(Map<String, dynamic> reward) async {
    final db = await instance.database;
    await db.insert('rewards', reward,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getRewards() async {
    final db = await instance.database;
    return await db.query('rewards', orderBy: 'cost ASC');
  }

  Future<void> updateReward(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('rewards', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReward(String id) async {
    final db = await instance.database;
    return await db.delete('rewards', where: 'id = ?', whereArgs: [id]);
  }

  // =============== BRAIN DUMPS ===============
  Future<int> insertBrainDump(Map<String, dynamic> dump) async {
    final db = await instance.database;
    return await db.insert('brain_dumps', dump);
  }

  Future<List<Map<String, dynamic>>> getBrainDumps() async {
    final db = await instance.database;
    return await db.query('brain_dumps', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getBrainDumpsBySession(
      String sessionId) async {
    final db = await instance.database;
    return await db
        .query('brain_dumps', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<int> deleteBrainDump(String id) async {
    final db = await instance.database;
    return await db.delete('brain_dumps', where: 'id = ?', whereArgs: [id]);
  }

  // =============== STUDY SESSIONS ===============
  Future<int> insertStudySession(Map<String, dynamic> session) async {
    final db = await instance.database;
    return await db.insert('study_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getStudySessionsByDate(String date) async {
    final db = await instance.database;
    return await db.query('study_sessions',
        where: 'date = ?', whereArgs: [date], orderBy: 'start_time DESC');
  }

  Future<List<Map<String, dynamic>>> getAllStudySessions() async {
    final db = await instance.database;
    return await db.query('study_sessions', orderBy: 'start_time DESC');
  }

  Future<int> updateStudySession(
      String id, Map<String, dynamic> session) async {
    final db = await instance.database;
    return await db
        .update('study_sessions', session, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudySession(String id) async {
    final db = await instance.database;
    return await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // =============== FOCUS SESSIONS ===============
  Future<int> insertFocusSession(Map<String, dynamic> session) async {
    final db = await instance.database;
    return await db.insert('focus_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getFocusSessionsByDate(String date) async {
    final db = await instance.database;
    return await db.query('focus_sessions',
        where: 'date = ?', whereArgs: [date], orderBy: 'start_time DESC');
  }

  Future<int> updateFocusSession(
      String id, Map<String, dynamic> session) async {
    final db = await instance.database;
    return await db
        .update('focus_sessions', session, where: 'id = ?', whereArgs: [id]);
  }

  // =============== DAILY STATS ===============
  Future<int> insertOrUpdateDailyStats(Map<String, dynamic> stats) async {
    final db = await instance.database;
    return await db.insert('daily_stats', stats,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDailyStats(String date) async {
    final db = await instance.database;
    final results =
        await db.query('daily_stats', where: 'date = ?', whereArgs: [date]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await instance.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return await db.query('daily_stats',
        where: 'date >= ?',
        whereArgs: [weekAgo.toIso8601String().split('T')[0]],
        orderBy: 'date ASC');
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    final db = await instance.database;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return await db.query('daily_stats',
        where: 'date >= ?',
        whereArgs: [monthAgo.toIso8601String().split('T')[0]],
        orderBy: 'date ASC');
  }

  // =============== BLOCKED APPS ===============
  Future<int> insertBlockedApp(Map<String, dynamic> app) async {
    final db = await instance.database;
    return await db.insert('blocked_apps', app,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBlockedApps() async {
    final db = await instance.database;
    return await db.query('blocked_apps', where: 'is_blocked = 1');
  }

  Future<List<Map<String, dynamic>>> getAllAppsInBlockList() async {
    final db = await instance.database;
    return await db.query('blocked_apps');
  }

  Future<int> updateBlockedApp(String packageName, bool isBlocked) async {
    final db = await instance.database;
    return await db.update('blocked_apps', {'is_blocked': isBlocked ? 1 : 0},
        where: 'package_name = ?', whereArgs: [packageName]);
  }

  Future<int> deleteBlockedApp(String packageName) async {
    final db = await instance.database;
    return await db.delete('blocked_apps',
        where: 'package_name = ?', whereArgs: [packageName]);
  }

  // =============== SETTINGS ===============
  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final results =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  // =============== AGGREGATES ===============
  Future<int> getTotalStudyMinutesToday() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
        'SELECT SUM(duration_minutes) as total FROM study_sessions WHERE date = ?',
        [today]);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalFocusMinutesToday() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
        'SELECT SUM(actual_duration_minutes) as total FROM focus_sessions WHERE date = ?',
        [today]);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final results =
        await db.query('daily_stats', orderBy: 'date DESC', limit: 30);
    if (results.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (var stat in results) {
      final statDate = DateTime.parse(stat['date'] as String);
      final diff = checkDate.difference(statDate).inDays;
      if (diff <= 1 && (stat['total_study_minutes'] as int) > 0) {
        streak++;
        checkDate = statDate;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('study_sessions');
    await db.delete('focus_sessions');
    await db.delete('daily_stats');
    await db.delete('habits');
    await db.delete('dailies');
    await db.delete('todos');
    await db.delete('brain_dumps');
    await db.update(
        'user_profile',
        {
          'total_points': 0,
          'health': 50,
          'experience': 0,
          'experience_to_next': 25,
          'level': 1,
          'gold': 0,
          'gems': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'total_study_minutes': 0,
          'total_focus_minutes': 0,
          'sessions_completed': 0,
          'phone_unlocks': 0,
        },
        where: 'id = 1');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
