import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/task_model.dart';
import 'package:monojog/providers/task_provider.dart';

class _TC {
  static const bg = Color(0xFF0E0B1F);
  static const card = Color(0xFF1A1730);
  static const cardLight = Color(0xFF221F38);
  static const purple = Color(0xFF9C6AFF);
  static const purpleLight = Color(0xFFB388FF);
  static const purpleDark = Color(0xFF6C3AEF);
  static const purpleBg = Color(0xFF2D1B69);
  static const white = Colors.white;
  static const textSec = Color(0xFF8A87A0);
  static const low = Color(0xFF4ECDC4);
  static const medium = Color(0xFFFEE440);
  static const high = Color(0xFFFF6B6B);
  static const done = Color(0xFF66FFCC);
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _viewMode = 0; // 0 = list, 1 = calendar, 2 = analytics

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (ctx, prov, _) {
        return Scaffold(
          backgroundColor: _TC.bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(prov),
                const SizedBox(height: 12),
                _buildProgressCard(prov),
                const SizedBox(height: 16),
                _buildViewSwitcher(),
                const SizedBox(height: 8),
                Expanded(child: _buildContent(prov)),
              ],
            ),
          ),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildHeader(TaskProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM dd').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _TC.textSec,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _TC.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (prov.overdueCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _TC.high.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _TC.high.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_rounded, color: _TC.high, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${prov.overdueCount} overdue',
                    style: const TextStyle(
                      color: _TC.high,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(TaskProvider prov) {
    final rate = prov.todayCompletionRate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _TC.purpleBg.withValues(alpha: 0.7),
              _TC.card,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _TC.purple.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 5,
                    backgroundColor: _TC.purple.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(_TC.done),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(rate * 100).round()}%',
                      style: const TextStyle(
                        color: _TC.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${prov.todayDoneCount}/${prov.todayActiveCount + prov.todayDoneCount} tasks done',
                    style: const TextStyle(
                      color: _TC.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time spent: ${prov.todayTotalTimeFormatted}',
                    style: const TextStyle(
                      color: _TC.textSec,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _TC.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _viewTab('Tasks', Icons.list_rounded, 0),
            _viewTab('Calendar', Icons.calendar_month_rounded, 1),
            _viewTab('Analytics', Icons.bar_chart_rounded, 2),
          ],
        ),
      ),
    );
  }

  Widget _viewTab(String label, IconData icon, int idx) {
    final sel = _viewMode == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: sel ? _TC.purpleBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: sel ? _TC.purpleLight : _TC.textSec),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: sel ? _TC.purpleLight : _TC.textSec,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TaskProvider prov) {
    switch (_viewMode) {
      case 1:
        return _buildCalendarView(prov);
      case 2:
        return _buildAnalyticsView(prov);
      default:
        return _buildListView(prov);
    }
  }

  // --------------------------------------
  // LIST VIEW
  // --------------------------------------
  Widget _buildListView(TaskProvider prov) {
    return Column(
      children: [
        _buildDateStrip(prov),
        const SizedBox(height: 8),
        Expanded(child: _buildTaskListBody(prov)),
      ],
    );
  }

  Widget _buildDateStrip(TaskProvider prov) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (ctx, i) {
          final date = startOfWeek.add(Duration(days: i));
          final isSel = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(prov.selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(now);
          final dayLabel = DateFormat('E').format(date).substring(0, 3);
          final taskCount = prov.tasks
              .where((t) =>
                  DateFormat('yyyy-MM-dd').format(t.dueDate) ==
                  DateFormat('yyyy-MM-dd').format(date))
              .length;

          return GestureDetector(
            onTap: () => prov.setSelectedDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSel ? _TC.purple : _TC.card,
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSel
                    ? Border.all(
                        color: _TC.purple.withValues(alpha: 0.4), width: 1.5)
                    : null,
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: _TC.purple.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.8)
                          : _TC.textSec,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSel ? Colors.white : _TC.white,
                    ),
                  ),
                  if (taskCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : _TC.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskListBody(TaskProvider prov) {
    final active = prov.activeTasksForDate;
    final done = prov.doneTasksForDate;
    if (active.isEmpty && done.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded,
                color: _TC.purple.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 12),
            const Text(
              'No tasks for this day',
              style: TextStyle(
                  color: _TC.textSec,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create a new task',
              style: TextStyle(color: Color(0xFF5A5870), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        if (active.isNotEmpty) ...[
          _sectionLabel('Active (${active.length})'),
          const SizedBox(height: 8),
          ...active.map((t) => _buildTaskCard(t, prov)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Completed (${done.length})'),
          const SizedBox(height: 8),
          ...done.map((t) => _buildTaskCard(t, prov)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _TC.textSec,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, TaskProvider prov) {
    final isDone = task.status == TaskStatus.done;
    final priorityColor = _getPriorityColor(task.priority);
    final isTimerOn = prov.isTimerRunningFor(task.id);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28),
      ),
      onDismissed: (_) => prov.deleteTask(task.id),
      child: GestureDetector(
        onTap: () => _showTaskDetail(task, prov),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _TC.card,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: isDone ? _TC.done : priorityColor,
                width: 3,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _TC.purpleBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${task.categoryEmoji} ${task.categoryLabel}',
                      style: const TextStyle(
                        color: _TC.purpleLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded,
                            color: priorityColor, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          task.priorityLabel,
                          style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (task.formattedDueTime.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: _TC.textSec, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          task.formattedDueTime,
                          style: const TextStyle(
                              color: _TC.textSec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                task.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDone ? _TC.textSec : _TC.white,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: _TC.textSec,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: _TC.textSec, height: 1.4),
                ),
              ],
              // Subtask progress
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.subtaskProgress,
                          minHeight: 4,
                          backgroundColor: _TC.purple.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(_TC.done),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.subtasksDone.where((b) => b).length}/${task.subtasks.length}',
                      style: const TextStyle(
                          color: _TC.textSec,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Bottom row: timer + complete
              Row(
                children: [
                  // Time tracked
                  if (task.elapsedSeconds > 0 || isTimerOn) ...[
                    Icon(Icons.timer_rounded,
                        size: 14, color: isTimerOn ? _TC.done : _TC.textSec),
                    const SizedBox(width: 4),
                    Text(
                      task.formattedElapsed,
                      style: TextStyle(
                        color: isTimerOn ? _TC.done : _TC.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Timer button
                  if (!isDone)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isTimerOn) {
                          prov.stopTaskTimer(task.id);
                        } else {
                          prov.startTaskTimer(task.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isTimerOn
                              ? _TC.high.withValues(alpha: 0.15)
                              : _TC.done.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isTimerOn
                                ? _TC.high.withValues(alpha: 0.3)
                                : _TC.done.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTimerOn
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: 14,
                              color: isTimerOn ? _TC.high : _TC.done,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTimerOn ? 'Stop' : 'Track',
                              style: TextStyle(
                                color: isTimerOn ? _TC.high : _TC.done,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Complete button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      prov.toggleTaskStatus(task.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? _TC.done.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone ? _TC.done : _TC.purple,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              color: _TC.done, size: 18)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------
  // CALENDAR VIEW
  // --------------------------------------
  Widget _buildCalendarView(TaskProvider prov) {
    final now = prov.selectedDate;
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () =>
                    prov.setSelectedDate(DateTime(now.year, now.month - 1, 1)),
                icon: const Icon(Icons.chevron_left_rounded, color: _TC.white),
              ),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(
                    color: _TC.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              IconButton(
                onPressed: () =>
                    prov.setSelectedDate(DateTime(now.year, now.month + 1, 1)),
                icon: const Icon(Icons.chevron_right_rounded, color: _TC.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                              color: _TC.textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + startWeekday - 1,
            itemBuilder: (ctx, index) {
              if (index < startWeekday - 1) return const SizedBox();
              final day = index - startWeekday + 2;
              if (day > daysInMonth) return const SizedBox();

              final date = DateTime(now.year, now.month, day);
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isToday = dateStr == todayStr;
              final isSel =
                  dateStr == DateFormat('yyyy-MM-dd').format(prov.selectedDate);
              final dayTasks = prov.tasks
                  .where((t) =>
                      DateFormat('yyyy-MM-dd').format(t.dueDate) == dateStr)
                  .toList();
              final hasTasks = dayTasks.isNotEmpty;
              final allDone = hasTasks &&
                  dayTasks.every((t) => t.status == TaskStatus.done);

              return GestureDetector(
                onTap: () => prov.setSelectedDate(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSel ? _TC.purple : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSel
                        ? Border.all(
                            color: _TC.purple.withValues(alpha: 0.5),
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSel ? Colors.white : _TC.white,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (hasTasks)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: allDone
                                ? _TC.done
                                : (isSel ? Colors.white : _TC.purple),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Tasks for selected date below calendar
          if (prov.tasksForSelectedDate.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'No tasks for ${DateFormat('MMM dd').format(prov.selectedDate)}',
                style: const TextStyle(color: _TC.textSec, fontSize: 14),
              ),
            )
          else
            ...prov.tasksForSelectedDate.map((t) => _buildTaskCard(t, prov)),
        ],
      ),
    );
  }

  // --------------------------------------
  // ANALYTICS VIEW
  // --------------------------------------
  Widget _buildAnalyticsView(TaskProvider prov) {
    final weekCompletion = prov.weeklyCompletionData;
    final weekTime = prov.weeklyTimeData;
    final maxCompletion = weekCompletion.fold<int>(0, (a, b) => a > b ? a : b);
    final maxTime = weekTime.fold<int>(0, (a, b) => a > b ? a : b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final catMap = prov.categoryTimeMap;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                  child: _analyticsCard(
                      'Total Done', '${prov.totalCompletedAllTime}', _TC.done)),
              const SizedBox(width: 12),
              Expanded(
                  child: _analyticsCard(
                      'Overdue', '${prov.overdueCount}', _TC.high)),
              const SizedBox(width: 12),
              Expanded(
                  child: _analyticsCard(
                      'Today Time', prov.todayTotalTimeFormatted, _TC.purple)),
            ],
          ),
          const SizedBox(height: 24),
          // Weekly completion chart
          const Text('Weekly Completions',
              style: TextStyle(
                  color: _TC.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = maxCompletion > 0
                    ? (weekCompletion[i] / maxCompletion) * 110
                    : 0.0;
                final isToday = i == DateTime.now().weekday - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (weekCompletion[i] > 0)
                          Text(
                            '${weekCompletion[i]}',
                            style: TextStyle(
                              color: isToday ? _TC.done : _TC.textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: h.clamp(4.0, 110.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [_TC.done, _TC.done.withValues(alpha: 0.6)]
                                  : [
                                      _TC.purpleBg,
                                      _TC.purple.withValues(alpha: 0.4)
                                    ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i].substring(0, 2),
                          style: TextStyle(
                            color: isToday ? _TC.done : _TC.textSec,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28),
          // Weekly time chart
          const Text('Weekly Time Spent',
              style: TextStyle(
                  color: _TC.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = maxTime > 0 ? (weekTime[i] / maxTime) * 110 : 0.0;
                final mins = weekTime[i] ~/ 60;
                final isToday = i == DateTime.now().weekday - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (mins > 0)
                          Text(
                            '${mins}m',
                            style: TextStyle(
                              color: isToday ? _TC.purple : _TC.textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: h.clamp(4.0, 110.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isToday ? _TC.purple : _TC.cardLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i].substring(0, 2),
                          style: TextStyle(
                            color: isToday ? _TC.purple : _TC.textSec,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Category breakdown
          if (catMap.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Time by Category',
                style: TextStyle(
                    color: _TC.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 12),
            ...catMap.entries.map((e) {
              final mins = e.value ~/ 60;
              final label = TaskModel(
                      id: '',
                      name: '',
                      dueDate: DateTime.now(),
                      createdAt: DateTime.now(),
                      category: e.key)
                  .categoryLabel;
              final emoji = TaskModel(
                      id: '',
                      name: '',
                      dueDate: DateTime.now(),
                      createdAt: DateTime.now(),
                      category: e.key)
                  .categoryEmoji;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text('$emoji $label',
                        style: const TextStyle(
                            color: _TC.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Spacer(),
                    Text('${mins}m',
                        style: const TextStyle(
                            color: _TC.purple,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _analyticsCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _TC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: _TC.textSec, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --------------------------------------
  // TASK DETAIL SHEET
  // --------------------------------------
  void _showTaskDetail(TaskModel task, TaskProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setS) {
          // Re-fetch task to get latest
          final currentTask =
              prov.tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
          final isDone = currentTask.status == TaskStatus.done;
          final isTimerOn = prov.isTimerRunningFor(currentTask.id);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: _TC.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _TC.textSec.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentTask.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDone ? _TC.textSec : _TC.white,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                prov.toggleTaskStatus(currentTask.id);
                                setS(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? _TC.done.withValues(alpha: 0.15)
                                      : _TC.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDone ? 'Undo' : 'Complete',
                                  style: TextStyle(
                                    color: isDone ? _TC.done : _TC.purple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Info chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _detailChip(
                                '${currentTask.categoryEmoji} ${currentTask.categoryLabel}',
                                _TC.purpleLight),
                            _detailChip(currentTask.priorityLabel,
                                _getPriorityColor(currentTask.priority)),
                            _detailChip(
                                currentTask.formattedDueDate, _TC.textSec),
                            if (currentTask.formattedDueTime.isNotEmpty)
                              _detailChip(
                                  currentTask.formattedDueTime, _TC.textSec),
                          ],
                        ),
                        if (currentTask.description != null &&
                            currentTask.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            currentTask.description!,
                            style: const TextStyle(
                                color: _TC.textSec, fontSize: 14, height: 1.5),
                          ),
                        ],
                        // Timer section
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _TC.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time Tracked',
                                      style: TextStyle(
                                          color: _TC.textSec,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTask.formattedElapsed,
                                    style: TextStyle(
                                      color: isTimerOn ? _TC.done : _TC.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (!isDone)
                                GestureDetector(
                                  onTap: () {
                                    if (isTimerOn) {
                                      prov.stopTaskTimer(currentTask.id);
                                    } else {
                                      prov.startTaskTimer(currentTask.id);
                                    }
                                    setS(() {});
                                  },
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: isTimerOn
                                            ? [
                                                _TC.high,
                                                _TC.high.withValues(alpha: 0.7)
                                              ]
                                            : [
                                                _TC.done,
                                                _TC.done.withValues(alpha: 0.7)
                                              ],
                                      ),
                                    ),
                                    child: Icon(
                                      isTimerOn
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Subtasks
                        if (currentTask.subtasks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Subtasks (${currentTask.subtasksDone.where((b) => b).length}/${currentTask.subtasks.length})',
                            style: const TextStyle(
                                color: _TC.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(currentTask.subtasks.length, (i) {
                            final subDone =
                                i < currentTask.subtasksDone.length &&
                                    currentTask.subtasksDone[i];
                            return GestureDetector(
                              onTap: () {
                                prov.toggleSubtask(currentTask.id, i);
                                setS(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: subDone
                                            ? _TC.done.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        border: Border.all(
                                            color: subDone
                                                ? _TC.done
                                                : _TC.textSec,
                                            width: 1.5),
                                      ),
                                      child: subDone
                                          ? const Icon(Icons.check_rounded,
                                              color: _TC.done, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        currentTask.subtasks[i],
                                        style: TextStyle(
                                          color:
                                              subDone ? _TC.textSec : _TC.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          decoration: subDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                        // Delete button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              prov.deleteTask(currentTask.id);
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: _TC.high, size: 18),
                            label: const Text('Delete Task',
                                style: TextStyle(
                                    color: _TC.high,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _detailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return _TC.low;
      case TaskPriority.medium:
        return _TC.medium;
      case TaskPriority.high:
        return _TC.high;
    }
  }

  // --------------------------------------
  // FAB & CREATE TASK
  // --------------------------------------
  Widget _buildFab() {
    return GestureDetector(
      onTap: () => _showCreateTaskSheet(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_TC.purpleLight, _TC.purpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _TC.purple.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  void _showCreateTaskSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final subtaskCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? selectedTime;
    TaskPriority selectedPriority = TaskPriority.medium;
    TaskCategory selectedCategory = TaskCategory.other;
    int estimatedMinutes = 30;
    List<String> subtasks = [];
    bool hasReminder = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setS) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.9,
              decoration: const BoxDecoration(
                color: _TC.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _TC.textSec.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded,
                              color: _TC.textSec, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'New Task',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _TC.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel('Task name'),
                          const SizedBox(height: 8),
                          _formField(
                              controller: nameCtrl,
                              hint: 'What do you need to do?'),
                          const SizedBox(height: 16),
                          _formLabel('Description'),
                          const SizedBox(height: 8),
                          _formField(
                              controller: descCtrl,
                              hint: 'Add details...',
                              maxLines: 3),
                          const SizedBox(height: 16),
                          // Category
                          _formLabel('Category'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: TaskCategory.values.map((c) {
                              final isSel = selectedCategory == c;
                              final label = TaskModel(
                                      id: '',
                                      name: '',
                                      dueDate: DateTime.now(),
                                      createdAt: DateTime.now(),
                                      category: c)
                                  .categoryLabel;
                              final emoji = TaskModel(
                                      id: '',
                                      name: '',
                                      dueDate: DateTime.now(),
                                      createdAt: DateTime.now(),
                                      category: c)
                                  .categoryEmoji;
                              return GestureDetector(
                                onTap: () => setS(() => selectedCategory = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? _TC.purple.withValues(alpha: 0.2)
                                        : _TC.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? _TC.purple : _TC.card,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '$emoji $label',
                                    style: TextStyle(
                                      color:
                                          isSel ? _TC.purpleLight : _TC.textSec,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Date & Time
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _formLabel('Due date'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: ctx2,
                                          initialDate: selectedDate,
                                          firstDate: DateTime.now().subtract(
                                              const Duration(days: 365)),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                          builder: (c, child) => Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                      primary: _TC.purple,
                                                      surface: _TC.card),
                                            ),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setS(() => selectedDate = picked);
                                        }
                                      },
                                      child: _dateTimeBox(
                                        DateFormat('MMM dd, yyyy')
                                            .format(selectedDate),
                                        Icons.calendar_today_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _formLabel('Time'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: ctx2,
                                          initialTime: TimeOfDay.now(),
                                          builder: (c, child) => Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                      primary: _TC.purple,
                                                      surface: _TC.card),
                                            ),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setS(() {
                                            selectedTime = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              selectedDate.day,
                                              picked.hour,
                                              picked.minute,
                                            );
                                          });
                                        }
                                      },
                                      child: _dateTimeBox(
                                        selectedTime != null
                                            ? DateFormat('hh:mm a')
                                                .format(selectedTime!)
                                            : 'Set time',
                                        Icons.access_time_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Priority
                          _formLabel('Priority'),
                          const SizedBox(height: 8),
                          Row(
                            children: TaskPriority.values.map((p) {
                              final isSel = selectedPriority == p;
                              final color = _getPriorityColor(p);
                              final label = p == TaskPriority.low
                                  ? 'Low'
                                  : p == TaskPriority.medium
                                      ? 'Medium'
                                      : 'High';
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setS(() => selectedPriority = p),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? color.withValues(alpha: 0.15)
                                          : _TC.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: isSel ? color : _TC.card,
                                          width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.flag_rounded,
                                            color: color, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: isSel ? color : _TC.textSec,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Estimated time
                          _formLabel('Estimated time: ${estimatedMinutes}m'),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _TC.purple,
                              inactiveTrackColor: _TC.card,
                              thumbColor: _TC.purpleLight,
                              overlayColor: _TC.purple.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: estimatedMinutes.toDouble(),
                              min: 5,
                              max: 240,
                              divisions: 47,
                              onChanged: (v) =>
                                  setS(() => estimatedMinutes = v.round()),
                            ),
                          ),
                          // Subtasks
                          const SizedBox(height: 12),
                          _formLabel('Subtasks'),
                          const SizedBox(height: 8),
                          ...subtasks.asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.subdirectory_arrow_right_rounded,
                                      color: _TC.textSec,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e.value,
                                        style: const TextStyle(
                                            color: _TC.white, fontSize: 14)),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setS(() => subtasks.removeAt(e.key)),
                                    child: const Icon(Icons.close_rounded,
                                        color: _TC.textSec, size: 18),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: subtaskCtrl,
                                  style: const TextStyle(
                                      color: _TC.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Add subtask...',
                                    hintStyle: TextStyle(
                                        color:
                                            _TC.textSec.withValues(alpha: 0.5)),
                                    filled: true,
                                    fillColor: _TC.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    isDense: true,
                                  ),
                                  onSubmitted: (v) {
                                    if (v.trim().isNotEmpty) {
                                      setS(() {
                                        subtasks.add(v.trim());
                                        subtaskCtrl.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (subtaskCtrl.text.trim().isNotEmpty) {
                                    setS(() {
                                      subtasks.add(subtaskCtrl.text.trim());
                                      subtaskCtrl.clear();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _TC.purple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      color: _TC.purple, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Reminder
                          Row(
                            children: [
                              _formLabel('Set reminder'),
                              const Spacer(),
                              Switch(
                                value: hasReminder,
                                onChanged: (v) => setS(() => hasReminder = v),
                                activeTrackColor:
                                    _TC.purple.withValues(alpha: 0.5),
                                activeThumbColor: _TC.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Create button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter a task name'),
                                        backgroundColor: _TC.high),
                                  );
                                  return;
                                }
                                final task = TaskModel(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim().isNotEmpty
                                      ? descCtrl.text.trim()
                                      : null,
                                  dueDate: selectedDate,
                                  dueTime: selectedTime,
                                  priority: selectedPriority,
                                  createdAt: DateTime.now(),
                                  hasReminder: hasReminder,
                                  category: selectedCategory,
                                  estimatedMinutes: estimatedMinutes,
                                  subtasks: subtasks,
                                  subtasksDone:
                                      List.filled(subtasks.length, false),
                                );
                                context.read<TaskProvider>().addTask(task);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _TC.purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Text(
                                'Create Task',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: _TC.textSec),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _TC.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _TC.textSec.withValues(alpha: 0.5)),
        filled: true,
        fillColor: _TC.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _TC.purple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dateTimeBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _TC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _TC.cardLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: _TC.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Icon(icon, color: _TC.textSec, size: 18),
        ],
      ),
    );
  }
}
