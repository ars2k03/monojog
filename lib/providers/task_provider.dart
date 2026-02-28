import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monojog/models/task_model.dart';
import 'package:monojog/services/database_service.dart';
import 'package:monojog/services/history_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  Timer? _activeTimer;
  String? _activeTimerTaskId;

  List<TaskModel> get tasks => _tasks;
  DateTime get selectedDate => _selectedDate;

  // -- Filtered Lists --
  List<TaskModel> get activeTasks =>
      _tasks.where((t) => t.status == TaskStatus.active).toList();

  List<TaskModel> get doneTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();

  List<TaskModel> get tasksForSelectedDate {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _tasks
        .where((t) => DateFormat('yyyy-MM-dd').format(t.dueDate) == dateStr)
        .toList();
  }

  List<TaskModel> get activeTasksForDate =>
      tasksForSelectedDate.where((t) => t.status == TaskStatus.active).toList();

  List<TaskModel> get doneTasksForDate =>
      tasksForSelectedDate.where((t) => t.status == TaskStatus.done).toList();

  List<TaskModel> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  // -- Counts --
  int get todayActiveCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _tasks
        .where((t) =>
            DateFormat('yyyy-MM-dd').format(t.dueDate) == today &&
            t.status == TaskStatus.active)
        .length;
  }

  int get todayDoneCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _tasks
        .where((t) =>
            DateFormat('yyyy-MM-dd').format(t.dueDate) == today &&
            t.status == TaskStatus.done)
        .length;
  }

  double get todayCompletionRate {
    final total = todayActiveCount + todayDoneCount;
    if (total == 0) return 0;
    return todayDoneCount / total;
  }

  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  int get totalCompletedAllTime =>
      _tasks.where((t) => t.status == TaskStatus.done).length;

  // -- Time Analytics --
  int get todayTotalElapsedSeconds {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _tasks
        .where((t) => DateFormat('yyyy-MM-dd').format(t.dueDate) == today)
        .fold<int>(0, (sum, t) => sum + t.elapsedSeconds);
  }

  String get todayTotalTimeFormatted {
    final s = todayTotalElapsedSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Map<TaskCategory, int> get categoryTimeMap {
    final map = <TaskCategory, int>{};
    for (final t in _tasks) {
      map[t.category] = (map[t.category] ?? 0) + t.elapsedSeconds;
    }
    return map;
  }

  // Weekly completion data for charts
  List<int> get weeklyCompletionData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      return _tasks
          .where((t) =>
              DateFormat('yyyy-MM-dd').format(t.dueDate) == dateStr &&
              t.status == TaskStatus.done)
          .length;
    });
  }

  List<int> get weeklyTimeData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      return _tasks
          .where((t) => DateFormat('yyyy-MM-dd').format(t.dueDate) == dateStr)
          .fold<int>(0, (sum, t) => sum + t.elapsedSeconds);
    });
  }

  // -- Active Timer --
  String? get activeTimerTaskId => _activeTimerTaskId;
  bool isTimerRunningFor(String taskId) => _activeTimerTaskId == taskId;

  // -- Constructor --
  TaskProvider() {
    _loadTasks();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          due_date INTEGER NOT NULL,
          due_time INTEGER,
          priority INTEGER DEFAULT 1,
          status INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          completed_at INTEGER,
          has_reminder INTEGER DEFAULT 0,
          attachment_path TEXT,
          category INTEGER DEFAULT 5,
          estimated_minutes INTEGER DEFAULT 0,
          elapsed_seconds INTEGER DEFAULT 0,
          subtasks TEXT,
          subtasks_done TEXT,
          recurring_rule TEXT
        )
      ''');

      // Migrate: add new columns if they don't exist
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN completed_at INTEGER');
      } catch (_) {}
      try {
        await db
            .execute('ALTER TABLE tasks ADD COLUMN category INTEGER DEFAULT 5');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE tasks ADD COLUMN estimated_minutes INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE tasks ADD COLUMN elapsed_seconds INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN subtasks TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN subtasks_done TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN recurring_rule TEXT');
      } catch (_) {}

      final maps = await db.query('tasks', orderBy: 'due_date ASC');
      _tasks = maps.map((m) => TaskModel.fromMap(m)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db.insert('tasks', task.toMap());
    } catch (_) {}
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    final newStatus =
        task.status == TaskStatus.active ? TaskStatus.done : TaskStatus.active;
    _tasks[index] = task.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.done ? DateTime.now() : null,
    );

    // Stop timer if running
    if (_activeTimerTaskId == taskId) {
      stopTaskTimer(taskId);
    }

    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'tasks',
        {
          'status': newStatus.index,
          'completed_at': newStatus == TaskStatus.done
              ? DateTime.now().millisecondsSinceEpoch
              : null,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );

      // Log task completion to history
      if (newStatus == TaskStatus.done) {
        try {
          await HistoryService.instance.logEvent(
            'task_completion',
            'Task completed: ${task.name}',
            '${task.name} marked done',
            xp: 5,
            gold: 2,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId) async {
    if (_activeTimerTaskId == taskId) {
      stopTaskTimer(taskId);
    }
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
    } catch (_) {}
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db
          .update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    } catch (_) {}
  }

  // -- Subtask Management --
  void toggleSubtask(String taskId, int subtaskIndex) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    if (subtaskIndex >= task.subtasksDone.length) return;

    final newDones = List<bool>.from(task.subtasksDone);
    newDones[subtaskIndex] = !newDones[subtaskIndex];
    _tasks[index] = task.copyWith(subtasksDone: newDones);
    notifyListeners();
    updateTask(_tasks[index]);
  }

  // -- Task Timer --
  void startTaskTimer(String taskId) {
    // Stop any existing timer
    if (_activeTimerTaskId != null && _activeTimerTaskId != taskId) {
      stopTaskTimer(_activeTimerTaskId!);
    }

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    _activeTimerTaskId = taskId;
    _tasks[index] = _tasks[index].copyWith(
      isTimerRunning: true,
      timerStartedAt: DateTime.now(),
    );

    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx == -1) {
        _activeTimer?.cancel();
        _activeTimerTaskId = null;
        return;
      }
      _tasks[idx] = _tasks[idx].copyWith(
        elapsedSeconds: _tasks[idx].elapsedSeconds + 1,
      );
      notifyListeners();
    });

    notifyListeners();
  }

  void stopTaskTimer(String taskId) {
    _activeTimer?.cancel();
    _activeTimer = null;
    _activeTimerTaskId = null;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      isTimerRunning: false,
    );
    notifyListeners();

    // Persist elapsed time
    updateTask(_tasks[index]);
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    super.dispose();
  }
}
