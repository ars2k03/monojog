import 'package:flutter/material.dart' hide Badge;
import 'package:uuid/uuid.dart';

import 'package:monojog/models/user_profile.dart';
import 'package:monojog/models/habit_models.dart';
import 'package:monojog/models/reward_models.dart';
import 'package:monojog/services/database_service.dart';

class GameProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  static const _uuid = Uuid();

  // ── State ──
  UserProfile _profile = UserProfile();
  List<StudyHabit> _habits = [];
  List<StudyDaily> _dailies = [];
  List<StudyTodo> _todos = [];
  List<Badge> _badges = [];
  List<RewardItem> _rewards = [];
  List<BrainDump> _brainDumps = [];

  // ── Batch flag: suppresses intermediate notifyListeners calls ──
  bool _batching = false;

  // ── Public getters ──
  UserProfile get profile => _profile;
  List<StudyHabit> get habits => _habits;
  List<StudyDaily> get dailies => _dailies;
  List<StudyTodo> get todos => _todos;
  List<Badge> get badges => _badges;
  List<RewardItem> get rewards => _rewards;
  List<BrainDump> get brainDumps => _brainDumps;

  int get unlockedBadgeCount => _badges.where((b) => b.isUnlocked).length;
  int get pendingTodoCount => _todos.where((t) => !t.isDone).length;
  int get pendingDailyCount => _dailies.where((d) => !d.isDoneToday).length;

  GameProvider() {
    _initialize();
  }

  // ═══════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _initialize() async {
    _batching = true;

    await _loadProfile();

    // Load all collections in parallel — they are independent.
    await Future.wait([
      _loadHabits(),
      _loadDailies(),
      _loadTodos(),
      _loadBrainDumps(),
      _initAndLoadBadges(),
      _initAndLoadRewards(),
    ]);

    await _resetDailiesIfNewDay();

    _batching = false;
    notifyListeners();
  }

  /// Wrapper for notifyListeners that respects batching.
  void _notify() {
    if (!_batching) notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadProfile() async {
    final data = await _db.getUserProfile();
    _profile = UserProfile.fromMap(data);
    _notify();
  }

  Future<void> _saveProfile() async {
    await _db.updateUserProfile(_profile.toMap());
    _notify();
  }

  Future<void> updateProfile({
    String? username,
    String? avatarType,
    String? profileImagePath,
  }) async {
    _profile = _profile.copyWith(
      username: username ?? _profile.username,
      avatarType: avatarType ?? _profile.avatarType,
      profileImagePath: profileImagePath ?? _profile.profileImagePath,
    );
    await _saveProfile();
  }

  Future<void> syncProfileFromAuthUser({
    String? displayName,
    String? email,
  }) async {
    final preferredName = _preferredName(displayName, email);
    if (preferredName == null) return;

    final currentName = _profile.username.trim();
    final shouldReplace =
        currentName.isEmpty || currentName.toLowerCase() == 'student';
    if (!shouldReplace || currentName == preferredName) return;

    _profile = _profile.copyWith(username: preferredName);
    await _saveProfile();
  }

  String? _preferredName(String? displayName, String? email) {
    final cleanDisplay = displayName?.trim();
    if (cleanDisplay != null && cleanDisplay.isNotEmpty) {
      return cleanDisplay.split(RegExp(r'\s+')).first;
    }

    final cleanEmail = email?.trim();
    if (cleanEmail == null ||
        cleanEmail.isEmpty ||
        !cleanEmail.contains('@')) {
      return null;
    }

    final base = cleanEmail.split('@').first.trim();
    if (base.isEmpty) return null;

    final normalized = base
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) =>
    '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1).toLowerCase() : ''}')
        .join(' ')
        .trim();

    return normalized.isEmpty ? null : normalized;
  }

  // ── Gold ──

  Future<void> addGold(int amount) async {
    _profile = _profile.copyWith(gold: _profile.gold + amount);
    await _saveProfile();
  }

  Future<void> spendGold(int amount) async {
    if (_profile.gold < amount) return;
    _profile = _profile.copyWith(gold: _profile.gold - amount);
    await _saveProfile();
  }

  // ── Gems ──

  Future<void> addGems(int amount) async {
    _profile = _profile.copyWith(gems: _profile.gems + amount);
    await _saveProfile();
  }

  // ── Experience ──

  Future<void> addExperience(int xp) async {
    int newXp = _profile.experience + xp;
    int newLevel = _profile.level;
    int xpToNext = _profile.experienceToNext;

    while (newXp >= xpToNext) {
      newXp -= xpToNext;
      newLevel++;
      xpToNext = UserProfile.xpForLevel(newLevel);
    }

    _profile = _profile.copyWith(
      experience: newXp,
      experienceToNext: xpToNext,
      level: newLevel,
      totalPoints: _profile.totalPoints + xp,
    );
    await _saveProfile();

    if (newLevel >= 10) await _tryUnlockBadge('level_10');
  }

  // ── Health ──

  Future<void> takeDamage(int amount) async {
    final newHealth = (_profile.health - amount).clamp(0, _profile.maxHealth);
    _profile = _profile.copyWith(health: newHealth);
    await _saveProfile();
  }

  Future<void> heal(int amount) async {
    final newHealth = (_profile.health + amount).clamp(0, _profile.maxHealth);
    _profile = _profile.copyWith(health: newHealth);
    await _saveProfile();
  }

  // ── Streak ──

  Future<void> updateStreak(int streak) async {
    final longest =
    streak > _profile.longestStreak ? streak : _profile.longestStreak;
    _profile =
        _profile.copyWith(currentStreak: streak, longestStreak: longest);
    await _saveProfile();

    // Unlock streak badges — highest first so we skip already-unlocked.
    if (streak >= 30) {
      await _tryUnlockBadge('streak_30');
    } else if (streak >= 14) {
      await _tryUnlockBadge('streak_14');
    } else if (streak >= 7) {
      await _tryUnlockBadge('streak_7');
    } else if (streak >= 3) {
      await _tryUnlockBadge('streak_3');
    }
  }

  // ── Session complete ──

  Future<void> onSessionComplete({
    int minutes = 0,
    bool noUnlocks = false,
  }) async {
    _batching = true;

    int bonus = 0;

    if (noUnlocks) {
      bonus += 10;
      await _tryUnlockBadge('deep_focus');
    }
    if (minutes >= 60) await _tryUnlockBadge('hour_warrior');

    final hour = DateTime.now().hour;
    if (hour < 6) await _tryUnlockBadge('early_bird');
    if (hour >= 0 && hour < 5) await _tryUnlockBadge('night_owl');

    _profile = _profile.copyWith(
      sessionsCompleted: _profile.sessionsCompleted + 1,
      totalStudyMinutes: _profile.totalStudyMinutes + minutes,
    );
    await _db.updateUserProfile(_profile.toMap());

    // Gold + XP in parallel (both only write to profile).
    final goldAmount = (minutes * 2) + bonus;
    final xpAmount = minutes + (bonus ~/ 2);

    _profile = _profile.copyWith(gold: _profile.gold + goldAmount);

    // Inline XP calculation to avoid double-save.
    int newXp = _profile.experience + xpAmount;
    int newLevel = _profile.level;
    int xpToNext = _profile.experienceToNext;
    while (newXp >= xpToNext) {
      newXp -= xpToNext;
      newLevel++;
      xpToNext = UserProfile.xpForLevel(newLevel);
    }
    _profile = _profile.copyWith(
      experience: newXp,
      experienceToNext: xpToNext,
      level: newLevel,
      totalPoints: _profile.totalPoints + xpAmount,
    );
    await _db.updateUserProfile(_profile.toMap());

    // Session count badges.
    if (_profile.sessionsCompleted >= 50) {
      await _tryUnlockBadge('sessions_50');
    } else if (_profile.sessionsCompleted >= 1) {
      await _tryUnlockBadge('first_focus');
    }
    if (newLevel >= 10) await _tryUnlockBadge('level_10');

    _batching = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  HABITS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadHabits() async {
    final data = await _db.getHabits();
    _habits = data.map((m) => StudyHabit.fromMap(m)).toList();
    _notify();
  }

  Future<void> addHabit(
      String title, {
        String? notes,
        bool isPositive = true,
        int difficulty = 2,
      }) async {
    final habit = StudyHabit(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      isPositive: isPositive,
      difficulty: difficulty,
    );
    await _db.insertHabit(habit.toMap());
    _habits.add(habit);
    _notify();
  }

  Future<void> tapHabit(String id, bool positive) async {
    if (positive) {
      await tapHabitPositive(id);
    } else {
      await tapHabitNegative(id);
    }
  }

  Future<void> tapHabitPositive(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    _batching = true;

    final habit = _habits[index];
    final updated = habit.copyWith(
      counterUp: habit.counterUp + 1,
      streak: habit.streak + 1,
    );
    await _db.updateHabit(id, updated.toMap());
    _habits[index] = updated;

    await addGold(habit.pointsPerTap);
    await addExperience(habit.pointsPerTap ~/ 2);
    await heal(1);

    _batching = false;
    notifyListeners();
  }

  Future<void> tapHabitNegative(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    _batching = true;

    final habit = _habits[index];
    final updated = habit.copyWith(
      counterDown: habit.counterDown + 1,
      streak: 0,
    );
    await _db.updateHabit(id, updated.toMap());
    _habits[index] = updated;

    await takeDamage(habit.pointsPerTap);

    _batching = false;
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
    _habits.removeWhere((h) => h.id == id);
    _notify();
  }

  // ═══════════════════════════════════════════════════════════
  //  DAILIES
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadDailies() async {
    final data = await _db.getDailies();
    _dailies = data.map((m) => StudyDaily.fromMap(m)).toList();
    _notify();
  }

  Future<void> _resetDailiesIfNewDay() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final writes = <Future<void>>[];

    for (var i = 0; i < _dailies.length; i++) {
      final d = _dailies[i];
      if (d.lastCompletedDate != today && d.isDoneToday) {
        final reset = d.copyWith(isDoneToday: false);
        writes.add(_db.updateDaily(d.id, reset.toMap()));
        _dailies[i] = reset;
      }
    }

    if (writes.isNotEmpty) {
      await Future.wait(writes);
      _notify();
    }
  }

  Future<void> addDaily(
      String title, {
        String? notes,
        int targetMinutes = 30,
        int difficulty = 2,
      }) async {
    final daily = StudyDaily(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      targetMinutes: targetMinutes,
      difficulty: difficulty,
    );
    await _db.insertDaily(daily.toMap());
    _dailies.add(daily);
    _notify();
  }

  Future<void> toggleDaily(String id) async {
    final index = _dailies.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final daily = _dailies[index];
    if (daily.isDoneToday) {
      await _uncompleteDaily(index, daily);
    } else {
      await _completeDaily(index, daily);
    }
  }

  Future<void> completeDaily(String id) async {
    final index = _dailies.indexWhere((d) => d.id == id);
    if (index == -1) return;
    await _completeDaily(index, _dailies[index]);
  }

  Future<void> uncompleteDaily(String id) async {
    final index = _dailies.indexWhere((d) => d.id == id);
    if (index == -1) return;
    await _uncompleteDaily(index, _dailies[index]);
  }

  Future<void> _completeDaily(int index, StudyDaily daily) async {
    _batching = true;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final updated = daily.copyWith(
      isDoneToday: true,
      streak: daily.streak + 1,
      lastCompletedDate: today,
    );
    await _db.updateDaily(daily.id, updated.toMap());
    _dailies[index] = updated;

    final goldEarned = daily.difficulty * 5;
    await addGold(goldEarned);
    await addExperience(goldEarned ~/ 2);
    await heal(2);

    _batching = false;
    notifyListeners();
  }

  Future<void> _uncompleteDaily(int index, StudyDaily daily) async {
    final updated = daily.copyWith(isDoneToday: false);
    await _db.updateDaily(daily.id, updated.toMap());
    _dailies[index] = updated;
    _notify();
  }

  Future<void> deleteDaily(String id) async {
    await _db.deleteDaily(id);
    _dailies.removeWhere((d) => d.id == id);
    _notify();
  }

  // ═══════════════════════════════════════════════════════════
  //  TODOS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadTodos() async {
    final data = await _db.getTodos();
    _todos = data.map((m) => StudyTodo.fromMap(m)).toList();
    _notify();
  }

  Future<void> addTodo(
      String title, {
        String? notes,
        String? dueDate,
        int difficulty = 2,
      }) async {
    final todo = StudyTodo(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      difficulty: difficulty,
    );
    await _db.insertTodo(todo.toMap());
    _todos.add(todo);
    _notify();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final todo = _todos[index];
    if (todo.isDone) {
      await _uncompleteTodo(index, todo);
    } else {
      await _completeTodo(index, todo);
    }
  }

  Future<void> completeTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    await _completeTodo(index, _todos[index]);
  }

  Future<void> uncompleteTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    await _uncompleteTodo(index, _todos[index]);
  }

  Future<void> _completeTodo(int index, StudyTodo todo) async {
    _batching = true;

    final updated = todo.copyWith(isDone: true);
    await _db.updateTodo(todo.id, updated.toMap());
    _todos[index] = updated;

    final goldEarned = todo.difficulty * 8;
    await addGold(goldEarned);
    await addExperience(goldEarned ~/ 2);

    _batching = false;
    notifyListeners();
  }

  Future<void> _uncompleteTodo(int index, StudyTodo todo) async {
    final updated = todo.copyWith(isDone: false);
    await _db.updateTodo(todo.id, updated.toMap());
    _todos[index] = updated;
    _notify();
  }

  Future<void> deleteTodo(String id) async {
    await _db.deleteTodo(id);
    _todos.removeWhere((t) => t.id == id);
    _notify();
  }

  // ═══════════════════════════════════════════════════════════
  //  BADGES
  // ═══════════════════════════════════════════════════════════

  Future<void> _initAndLoadBadges() async {
    final existing = await _db.getBadges();
    if (existing.isEmpty) {
      for (final badge in Badge.allBadges) {
        await _db.insertBadge(badge.toMap());
      }
    }
    _badges = (existing.isEmpty ? await _db.getBadges() : existing)
        .map((m) => Badge.fromMap(m))
        .toList();
    _notify();
  }

  Future<void> _tryUnlockBadge(String id) async {
    final index = _badges.indexWhere((b) => b.id == id);
    if (index == -1) return;
    if (_badges[index].isUnlocked) return;

    await _db.unlockBadge(id);
    // Reload just this badge's unlocked state in memory.
    _badges[index] = Badge(
      id: _badges[index].id,
      title: _badges[index].title,
      description: _badges[index].description,
      icon: _badges[index].icon,
      isUnlocked: true,
    );
    await addGems(5);
  }

  // ═══════════════════════════════════════════════════════════
  //  REWARDS
  // ═══════════════════════════════════════════════════════════

  Future<void> _initAndLoadRewards() async {
    final existing = await _db.getRewards();
    if (existing.isEmpty) {
      for (final reward in RewardItem.defaultRewards) {
        await _db.insertReward(reward.toMap());
      }
    }
    _rewards = (existing.isEmpty ? await _db.getRewards() : existing)
        .map((m) => RewardItem.fromMap(m))
        .toList();
    _notify();
  }

  Future<bool> purchaseReward(String id) async {
    final index = _rewards.indexWhere((r) => r.id == id);
    if (index == -1) return false;

    final reward = _rewards[index];
    if (_profile.gold < reward.cost) return false;

    await spendGold(reward.cost);
    return true;
  }

  Future<void> addCustomReward(
      String name,
      String description,
      String icon,
      int cost,
      ) async {
    final reward = RewardItem(
      id: _uuid.v4(),
      name: name,
      description: description,
      icon: icon,
      cost: cost,
      type: 'custom',
    );
    await _db.insertReward(reward.toMap());
    _rewards.add(reward);
    _notify();
  }

  Future<void> deleteReward(String id) async {
    await _db.deleteReward(id);
    _rewards.removeWhere((r) => r.id == id);
    _notify();
  }

  // ═══════════════════════════════════════════════════════════
  //  BRAIN DUMPS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadBrainDumps() async {
    final data = await _db.getBrainDumps();
    _brainDumps = data.map((m) => BrainDump.fromMap(m)).toList();
    _notify();
  }

  Future<void> addBrainDump(
      String text, {
        String? sessionId,
        String type = 'general',
      }) async {
    final dump = BrainDump(
      id: _uuid.v4(),
      text: text,
      sessionId: sessionId,
      type: type,
    );
    await _db.insertBrainDump(dump.toMap());
    _brainDumps.insert(0, dump); // newest first
    _notify();
  }

  Future<void> deleteBrainDump(String id) async {
    await _db.deleteBrainDump(id);
    _brainDumps.removeWhere((d) => d.id == id);
    _notify();
  }

  /// Alias so UI code like `removeBrainDump(dump)` works.
  Future<void> removeBrainDump(dynamic dump) async {
    await deleteBrainDump(dump.id as String);
  }

  // ═══════════════════════════════════════════════════════════
  //  PENALTIES
  // ═══════════════════════════════════════════════════════════

  Future<void> applyDailyPenalties() async {
    final missed = _dailies.where((d) => !d.isDoneToday).length;
    if (missed > 0) {
      await takeDamage(missed * 3);
    }
  }

  Future<void> penalizeAppSwitch() async {
    _batching = true;
    await takeDamage(2);
    if (_profile.gold > 0) await spendGold(1);
    _batching = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  RESET
  // ═══════════════════════════════════════════════════════════

  Future<void> resetAll() async {
    await _db.deleteAllData();
    _profile = UserProfile();
    _habits = [];
    _dailies = [];
    _todos = [];
    _badges = [];
    _rewards = [];
    _brainDumps = [];
    notifyListeners();
    await _initialize();
  }

  /// Alias kept for backward compatibility.
  Future<void> resetAllData() => resetAll();
}