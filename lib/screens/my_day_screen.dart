import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:monojog/models/task_model.dart';
import 'package:monojog/providers/task_provider.dart';
import 'package:monojog/providers/habit_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/screens/task_screen.dart';
import 'package:monojog/screens/habits_screen.dart';

// ── Unified item that can be a task OR a habit ──
enum _ItemType { task, habit }

class _UnifiedItem {
  final String id;
  final String title;
  final String emoji;
  final Color color;
  final _ItemType type;
  final bool isDone;
  final TaskPriority? priority;
  final String? subtitle;
  final int? streak;

  const _UnifiedItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.type,
    required this.isDone,
    this.priority,
    this.subtitle,
    this.streak,
  });
}

// ── Adaptive color palette ──
class _MC {
  // Dark
  static const _bgDark = Color(0xFF0A0A0F);
  static const _cardDark = Color(0xFF14141C);
  static const _cardLightDark = Color(0xFF1C1C28);

  // Light
  static const _bgLight = Color(0xFFF4F6FF);
  static const _cardLight = Color(0xFFFFFFFF);
  static const _cardLightLight = Color(0xFFECEEFA);

  // Accent — same both modes
  static const purple = Color(0xFF7C4DFF);
  static const cyan = Color(0xFF00ACC1);
  static const mint = Color(0xFF00BFA5);
  static const gold = Color(0xFFFFB300);
  static const red = Color(0xFFEF5350);
  static const orange = Color(0xFFFF9F43);

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _bgDark : _bgLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _cardDark
          : _cardLight;

  static Color cardLight_(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _cardLightDark
          : _cardLightLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C28)
          : const Color(0xFFE8EAF6);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1F33);

  static Color textSec(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B8FA3)
          : const Color(0xFF757B9A);

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C28)
          : const Color(0xFFDDE0F0);
}

Color _hex(String hex) {
  final c = hex.replaceAll('#', '');
  return Color(int.parse(c.length == 6 ? 'FF$c' : c, radix: 16));
}

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key});
  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _addCtrl = TextEditingController();
  bool _showAddField = false;
  int _filterMode = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  List<_UnifiedItem> _buildUnifiedList(
      TaskProvider tasks, HabitProvider habits) {
    final items = <_UnifiedItem>[];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_filterMode != 2) {
      for (final t in tasks.tasks) {
        final taskDate = DateFormat('yyyy-MM-dd').format(t.dueDate);
        if (taskDate == today) {
          items.add(_UnifiedItem(
            id: 'task_${t.id}',
            title: t.name,
            emoji: t.categoryEmoji,
            color: t.priority == TaskPriority.high
                ? _MC.red
                : t.priority == TaskPriority.medium
                ? _MC.orange
                : _MC.cyan,
            type: _ItemType.task,
            isDone: t.status == TaskStatus.done,
            priority: t.priority,
            subtitle: t.description,
          ));
        }
      }
    }

    if (_filterMode != 1) {
      final weekday = DateTime.now().weekday;
      for (final h in habits.habits) {
        if (!h.isScheduledFor(weekday)) continue;
        final done = habits.isCompletedToday(h.id);
        items.add(_UnifiedItem(
          id: 'habit_${h.id}',
          title: h.title,
          emoji: h.emoji,
          color: _hex(h.color),
          type: _ItemType.habit,
          isDone: done,
          streak: h.currentStreak,
          subtitle: h.currentStreak > 0
              ? '${h.currentStreak} day streak 🔥'
              : null,
        ));
      }
    }

    items.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      if (a.type != b.type) return a.type == _ItemType.habit ? -1 : 1;
      return a.title.compareTo(b.title);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TaskProvider, HabitProvider, GameProvider>(
      builder: (ctx, tasks, habits, game, _) {
        final unified = _buildUnifiedList(tasks, habits);
        final doneCount = unified.where((i) => i.isDone).length;
        final totalCount = unified.length;
        final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

        return Scaffold(
          backgroundColor: _MC.bg(context),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, progress, doneCount, totalCount),
                const SizedBox(height: 12),
                _buildProgressCard(progress, doneCount, totalCount),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 8),
                _buildTabBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildTodayTab(unified, tasks, habits, game),
                      _buildUpcomingTab(tasks),
                      _buildCompletedTab(unified, tasks, habits),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFab(tasks),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext ctx, double progress, int done, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _MC.textSec(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'My Day',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _MC.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _miniNavButton(ctx, Icons.checklist_rounded, _MC.purple, () {
            Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const TaskScreen()));
          }),
          const SizedBox(width: 8),
          _miniNavButton(ctx, Icons.repeat_rounded, _MC.mint, () {
            Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const HabitsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _miniNavButton(
      BuildContext ctx, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildProgressCard(double progress, int done, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _MC.purple.withValues(alpha: 0.1),
              _MC.cyan.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _MC.purple.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _MC.surface(context),
                        valueColor: AlwaysStoppedAnimation(
                          progress >= 1.0 ? _MC.gold : _MC.cyan,
                        ),
                      ),
                      Center(
                        child: Text(
                          progress >= 1.0
                              ? '🎉'
                              : '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: progress >= 1.0 ? 22 : 14,
                            fontWeight: FontWeight.w900,
                            color: _MC.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress >= 1.0
                            ? 'All Done! 🎊'
                            : '$done of $total completed',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _MC.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress >= 1.0
                            ? 'You crushed it today!'
                            : '${total - done} items remaining',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _MC.textSec(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: _MC.surface(context),
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0 ? _MC.gold : _MC.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      ('All', Icons.dashboard_rounded),
      ('Tasks', Icons.checklist_rounded),
      ('Habits', Icons.repeat_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(filters.length, (i) {
          final sel = _filterMode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filterMode = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? _MC.purple.withValues(alpha: 0.12)
                      : _MC.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? _MC.purple.withValues(alpha: 0.35)
                        : _MC.border(context),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(filters[i].$2,
                        size: 16,
                        color: sel ? _MC.purple : _MC.textSec(context)),
                    const SizedBox(width: 6),
                    Text(
                      filters[i].$1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? _MC.purple : _MC.textSec(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: _MC.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MC.border(context)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: _MC.cyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _MC.cyan.withValues(alpha: 0.3)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle:
        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        labelColor: _MC.cyan,
        unselectedLabelColor: _MC.textSec(context),
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Done'),
        ],
      ),
    );
  }

  // ── Today Tab ──
  Widget _buildTodayTab(List<_UnifiedItem> items, TaskProvider tasks,
      HabitProvider habits, GameProvider game) {
    if (items.isEmpty) {
      return _buildEmptyState(
        '🌟',
        'Your day is clear!',
        'Add tasks or habits to get started',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length + (_showAddField ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_showAddField && i == 0) {
          return _buildQuickAddField(tasks);
        }
        final idx = _showAddField ? i - 1 : i;
        final item = items[idx];
        return _buildUnifiedTile(item, tasks, habits, game);
      },
    );
  }

  Widget _buildQuickAddField(TaskProvider tasks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _MC.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MC.cyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.add_rounded, color: _MC.cyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _addCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                  color: _MC.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Quick add task...',
                hintStyle: GoogleFonts.inter(
                    color: _MC.textSec(context), fontSize: 14),
                border: InputBorder.none,
              ),
              onSubmitted: (val) => _quickAdd(tasks, val),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_addCtrl.text.trim().isNotEmpty) {
                _quickAdd(tasks, _addCtrl.text);
              } else {
                setState(() => _showAddField = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _MC.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _addCtrl.text.trim().isNotEmpty
                    ? Icons.check_rounded
                    : Icons.close_rounded,
                color: _MC.cyan,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickAdd(TaskProvider tasks, String title) {
    if (title.trim().isEmpty) return;
    final task = TaskModel(
      id: const Uuid().v4(),
      name: title.trim(),
      dueDate: DateTime.now(),
      createdAt: DateTime.now(),
      category: TaskCategory.personal,
    );
    tasks.addTask(task);
    _addCtrl.clear();
    setState(() => _showAddField = false);
  }

  Widget _buildUnifiedTile(_UnifiedItem item, TaskProvider tasks,
      HabitProvider habits, GameProvider game) {
    final isHabit = item.type == _ItemType.habit;

    return Dismissible(
      key: Key(item.id),
      direction: isHabit
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _MC.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: _MC.red, size: 22),
      ),
      onDismissed: (_) {
        final taskId = item.id.replaceFirst('task_', '');
        tasks.deleteTask(taskId);
      },
      child: GestureDetector(
        onTap: () => _toggleItem(item, tasks, habits, game),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 8),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: item.isDone
                ? _MC.card(context).withValues(alpha: 0.7)
                : _MC.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isDone
                  ? _MC.border(context)
                  : item.color.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleItem(item, tasks, habits, game),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isDone
                        ? item.color.withValues(alpha: 0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isDone
                          ? item.color
                          : item.color.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: item.isDone
                      ? Icon(Icons.check_rounded,
                      color: item.color, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Text(item.emoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isDone
                            ? _MC.textSec(context)
                            : _MC.textPrimary(context),
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: _MC.textSec(context),
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _MC.textSec(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHabit
                      ? _MC.mint.withValues(alpha: 0.1)
                      : _MC.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHabit ? 'Habit' : 'Task',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isHabit ? _MC.mint : _MC.purple,
                  ),
                ),
              ),
              if (item.priority == TaskPriority.high) ...[
                const SizedBox(width: 6),
                const Icon(Icons.priority_high_rounded,
                    color: _MC.red, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(_UnifiedItem item, TaskProvider tasks,
      HabitProvider habits, GameProvider game) {
    if (item.type == _ItemType.task) {
      final taskId = item.id.replaceFirst('task_', '');
      tasks.toggleTaskStatus(taskId);
      if (!item.isDone) {
        game.addExperience(5);
        game.addGold(2);
      }
    } else {
      final habitId = item.id.replaceFirst('habit_', '');
      habits.toggleCompletion(habitId);
      if (!item.isDone) {
        game.addExperience(5);
        game.addGold(2);
      }
    }
  }

  // ── Upcoming Tab ──
  Widget _buildUpcomingTab(TaskProvider tasks) {
    final now = DateTime.now();
    final upcoming = tasks.tasks
        .where((t) =>
    t.status == TaskStatus.active &&
        t.dueDate.isAfter(
            DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcoming.isEmpty) {
      return _buildEmptyState(
          '📅', 'No upcoming tasks', 'Add tasks with future due dates');
    }

    final groups = <String, List<TaskModel>>{};
    for (final t in upcoming) {
      final key = DateFormat('MMM dd, yyyy').format(t.dueDate);
      groups.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: groups.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              entry.key,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _MC.cyan,
              ),
            ),
          ),
          ...entry.value.map((t) => _buildTaskTile(t)),
        ];
      }).toList(),
    );
  }

  Widget _buildTaskTile(TaskModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _MC.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MC.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Text(t.categoryEmoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _MC.textPrimary(context))),
                if (t.description != null && t.description!.isNotEmpty)
                  Text(t.description!,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _MC.textSec(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            t.priorityLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.priority == TaskPriority.high
                  ? _MC.red
                  : t.priority == TaskPriority.medium
                  ? _MC.orange
                  : _MC.textSec(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Completed Tab ──
  Widget _buildCompletedTab(List<_UnifiedItem> items, TaskProvider tasks,
      HabitProvider habits) {
    final done = items.where((i) => i.isDone).toList();
    if (done.isEmpty) {
      return _buildEmptyState(
          '✨', 'Nothing completed yet', 'Start checking off items!');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: done.length,
      itemBuilder: (ctx, i) {
        final item = done[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _MC.card(context).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _MC.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withValues(alpha: 0.2),
                ),
                child: Icon(Icons.check_rounded,
                    color: item.color, size: 14),
              ),
              const SizedBox(width: 12),
              Text(item.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _MC.textSec(context),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _MC.textSec(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.type == _ItemType.habit
                      ? _MC.mint.withValues(alpha: 0.1)
                      : _MC.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.type == _ItemType.habit ? 'Habit' : 'Task',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: item.type == _ItemType.habit
                        ? _MC.mint
                        : _MC.purple,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      String emoji, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _MC.textPrimary(context))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _MC.textSec(context))),
        ],
      ),
    );
  }

  Widget _buildFab(TaskProvider tasks) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'quick_add',
          backgroundColor: _MC.cardLight_(context),
          onPressed: () =>
              setState(() => _showAddField = !_showAddField),
          child: Icon(
            _showAddField ? Icons.close_rounded : Icons.flash_on_rounded,
            color: _MC.cyan,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'add_task',
          backgroundColor: _MC.purple,
          onPressed: () => _showAddTaskSheet(context, tasks),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ],
    );
  }

  void _showAddTaskSheet(BuildContext ctx, TaskProvider tasks) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var priority = TaskPriority.medium;
    var category = TaskCategory.personal;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setSS) => Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24,
              MediaQuery.of(c).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF16161F)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _MC.textSec(context)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('New Task',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _MC.textPrimary(context))),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.inter(
                    color: _MC.textPrimary(context),
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Task name',
                  hintStyle: GoogleFonts.inter(
                      color: _MC.textSec(context)),
                  filled: true,
                  fillColor: _MC.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.edit_rounded,
                      color: _MC.cyan, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: GoogleFonts.inter(
                    color: _MC.textPrimary(context),
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: GoogleFonts.inter(
                      color: _MC.textSec(context)),
                  filled: true,
                  fillColor: _MC.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: _MC.textSec(context), size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Text('Priority',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _MC.textSec(context))),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final sel = priority == p;
                  final color = p == TaskPriority.high
                      ? _MC.red
                      : p == TaskPriority.medium
                      ? _MC.orange
                      : _MC.cyan;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSS(() => priority = p),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: p != TaskPriority.high ? 8 : 0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.12)
                              : _MC.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? color.withValues(alpha: 0.5)
                                  : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            p.name[0].toUpperCase() +
                                p.name.substring(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? color
                                  : _MC.textSec(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final task = TaskModel(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      description:
                      descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                      dueDate: DateTime.now(),
                      createdAt: DateTime.now(),
                      priority: priority,
                      category: category,
                    );
                    tasks.addTask(task);
                    Navigator.pop(c);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _MC.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Add Task',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}