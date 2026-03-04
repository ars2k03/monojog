import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/task_model.dart';
import 'package:monojog/providers/task_provider.dart';

/// Adaptive color palette — works for both light and dark mode.
class _TC {
  // ── Fixed brand / accent colors (vivid enough for both modes) ──
  static const purple = Color(0xFF7C4DFF);
  static const purpleLight = Color(0xFF9C6AFF);
  static const purpleDark = Color(0xFF5C35CC);
  static const low = Color(0xFF00BFA5);
  static const medium = Color(0xFFF9A825);
  static const high = Color(0xFFE53935);
  static const done = Color(0xFF00BFA5);

  // ── Semantic tokens resolved at runtime ──────────────────────────────────
  static Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF0E0B1F)
          : const Color(0xFFF0F4F8);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1A1730)
          : const Color(0xFFFFFFFF);

  static Color cardAlt(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF221F38)
          : const Color(0xFFE8EEF5);

  static Color purpleBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF2D1B69)
          : const Color(0xFFEDE7FF);

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0D1117);

  static Color textSec(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF8A87A0)
          : const Color(0xFF5A6070);

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.08);

  static Color divider(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.06);

  static Color inputFill(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1A1730)
          : const Color(0xFFF0F4F8);

  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static List<BoxShadow> cardShadow(BuildContext ctx) =>
      isDark(ctx)
          ? [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4))
      ]
          : [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3))
      ];
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  int _viewMode = 0; // 0 = list, 1 = calendar, 2 = analytics

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (ctx, prov, _) {
        return Scaffold(
          backgroundColor: _TC.bg(context),
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

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _TC.textSec(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _TC.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (prov.overdueCount > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _TC.high.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _TC.high.withValues(alpha: 0.35)),
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

  // ─────────────────────────────────────────────────────────────────────────
  // PROGRESS CARD  ← FIX: percentage text was overflowing the circle
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProgressCard(TaskProvider prov) {
    final rate = prov.todayCompletionRate;
    final isDark = _TC.isDark(context);
    final pctText = rate >= 1.0 ? '✓' : '${(rate * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              _TC.purpleBg(context).withValues(alpha: 0.7),
              _TC.card(context),
            ]
                : [
              _TC.purple.withValues(alpha: 0.08),
              _TC.card(context),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _TC.purple.withValues(alpha: isDark ? 0.15 : 0.2)),
          boxShadow: _TC.cardShadow(context),
        ),
        child: Row(
          children: [
            // FIX: use fixed size + FittedBox so the text never overflows
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 5,
                      backgroundColor: _TC.purple.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(_TC.done),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // FittedBox prevents text from spilling outside the circle
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        pctText,
                        style: TextStyle(
                          color: _TC.textPrimary(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
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
                    style: TextStyle(
                      color: _TC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time spent: ${prov.todayTotalTimeFormatted}',
                    style: TextStyle(
                      color: _TC.textSec(context),
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

  // ─────────────────────────────────────────────────────────────────────────
  // VIEW SWITCHER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _TC.card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _TC.isDark(context)
              ? null
              : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
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
            color: sel ? _TC.purpleBg(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: sel ? _TC.purpleLight : _TC.textSec(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: sel ? _TC.purpleLight : _TC.textSec(context),
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

  // ─────────────────────────────────────────────────────────────────────────
  // LIST VIEW
  // ─────────────────────────────────────────────────────────────────────────
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
                color: isSel ? _TC.purple : _TC.card(context),
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSel
                    ? Border.all(
                    color: _TC.purple.withValues(alpha: 0.5), width: 1.5)
                    : Border.all(color: _TC.border(context)),
                boxShadow: isSel
                    ? [
                  BoxShadow(
                      color: _TC.purple.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
                    : _TC.isDark(context)
                    ? null
                    : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
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
                          : _TC.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSel ? Colors.white : _TC.textPrimary(context),
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
            Text(
              'No tasks for this day',
              style: TextStyle(
                  color: _TC.textSec(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a new task',
              style: TextStyle(color: _TC.textSec(context), fontSize: 13),
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
      style: TextStyle(
        color: _TC.textSec(context),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TASK CARD
  // ─────────────────────────────────────────────────────────────────────────
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
          color: _TC.high.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: _TC.high, size: 28),
      ),
      onDismissed: (_) => prov.deleteTask(task.id),
      child: GestureDetector(
        onTap: () => _showTaskDetail(task, prov),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _TC.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: isDone ? _TC.done : priorityColor,
                width: 3,
              ),
              top: BorderSide(color: _TC.border(context)),
              right: BorderSide(color: _TC.border(context)),
              bottom: BorderSide(color: _TC.border(context)),
            ),
            boxShadow: _TC.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _TC.purple.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
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
                        Icon(Icons.access_time_rounded,
                            color: _TC.textSec(context), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          task.formattedDueTime,
                          style: TextStyle(
                              color: _TC.textSec(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDone
                      ? _TC.textSec(context)
                      : _TC.textPrimary(context),
                  decoration:
                  isDone ? TextDecoration.lineThrough : null,
                  decorationColor: _TC.textSec(context),
                ),
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: _TC.textSec(context),
                      height: 1.4),
                ),
              ],
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
                          backgroundColor:
                          _TC.purple.withValues(alpha: 0.12),
                          valueColor:
                          const AlwaysStoppedAnimation(_TC.done),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.subtasksDone.where((b) => b).length}/${task.subtasks.length}',
                      style: TextStyle(
                          color: _TC.textSec(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (task.elapsedSeconds > 0 || isTimerOn) ...[
                    Icon(Icons.timer_rounded,
                        size: 14,
                        color:
                        isTimerOn ? _TC.done : _TC.textSec(context)),
                    const SizedBox(width: 4),
                    Text(
                      task.formattedElapsed,
                      style: TextStyle(
                        color:
                        isTimerOn ? _TC.done : _TC.textSec(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
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
                              ? _TC.high.withValues(alpha: 0.12)
                              : _TC.done.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isTimerOn
                                ? _TC.high.withValues(alpha: 0.35)
                                : _TC.done.withValues(alpha: 0.3),
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

  // ─────────────────────────────────────────────────────────────────────────
  // CALENDAR VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCalendarView(TaskProvider prov) {
    final now = prov.selectedDate;
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => prov
                    .setSelectedDate(DateTime(now.year, now.month - 1, 1)),
                icon: Icon(Icons.chevron_left_rounded,
                    color: _TC.textPrimary(context)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: TextStyle(
                    color: _TC.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              IconButton(
                onPressed: () => prov
                    .setSelectedDate(DateTime(now.year, now.month + 1, 1)),
                icon: Icon(Icons.chevron_right_rounded,
                    color: _TC.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                      color: _TC.textSec(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),
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
              final todayStr =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isToday = dateStr == todayStr;
              final isSel = dateStr ==
                  DateFormat('yyyy-MM-dd').format(prov.selectedDate);
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
                          color: isSel
                              ? Colors.white
                              : _TC.textPrimary(context),
                          fontWeight:
                          isSel ? FontWeight.w900 : FontWeight.w600,
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
          if (prov.tasksForSelectedDate.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'No tasks for ${DateFormat('MMM dd').format(prov.selectedDate)}',
                style:
                TextStyle(color: _TC.textSec(context), fontSize: 14),
              ),
            )
          else
            ...prov.tasksForSelectedDate
                .map((t) => _buildTaskCard(t, prov)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANALYTICS VIEW  ← FIX: chart days now align Mon–Sun correctly
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsView(TaskProvider prov) {
    final weekCompletion = prov.weeklyCompletionData;
    final weekTime = prov.weeklyTimeData;
    final maxCompletion =
    weekCompletion.fold<int>(0, (a, b) => a > b ? a : b);
    final maxTime = weekTime.fold<int>(0, (a, b) => a > b ? a : b);

    // FIX: days aligned to weeklyCompletionData which is last-7-days from Mon
    // provider generates data as [6-days-ago … today], so label accordingly
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d).substring(0, 2);
    });
    final todayChartIndex = 6; // last item is always today

    final catMap = prov.categoryTimeMap;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _analyticsCard(
                      'Total Done',
                      '${prov.totalCompletedAllTime}',
                      _TC.done)),
              const SizedBox(width: 12),
              Expanded(
                  child: _analyticsCard(
                      'Overdue', '${prov.overdueCount}', _TC.high)),
              const SizedBox(width: 12),
              Expanded(
                  child: _analyticsCard(
                      'Today Time',
                      prov.todayTotalTimeFormatted,
                      _TC.purple)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Weekly Completions',
              style: TextStyle(
                  color: _TC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = maxCompletion > 0
                    ? (weekCompletion[i] / maxCompletion) * 110
                    : 0.0;
                final isToday = i == todayChartIndex;
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
                              color: isToday
                                  ? _TC.done
                                  : _TC.textSec(context),
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
                                  ? [
                                _TC.done,
                                _TC.done.withValues(alpha: 0.6)
                              ]
                                  : _TC.isDark(context)
                                  ? [
                                _TC.purpleBg(context),
                                _TC.purple
                                    .withValues(alpha: 0.4)
                              ]
                                  : [
                                _TC.purple
                                    .withValues(alpha: 0.2),
                                _TC.purple
                                    .withValues(alpha: 0.08)
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: TextStyle(
                            color: isToday
                                ? _TC.done
                                : _TC.textSec(context),
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
          Text('Weekly Time Spent',
              style: TextStyle(
                  color: _TC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h =
                maxTime > 0 ? (weekTime[i] / maxTime) * 110 : 0.0;
                final mins = weekTime[i] ~/ 60;
                final isToday = i == todayChartIndex;
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
                              color: isToday
                                  ? _TC.purple
                                  : _TC.textSec(context),
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
                            color: isToday
                                ? _TC.purple
                                : _TC.isDark(context)
                                ? _TC.cardAlt(context)
                                : const Color(0xFFD0DAE8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: TextStyle(
                            color: isToday
                                ? _TC.purple
                                : _TC.textSec(context),
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
          if (catMap.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Time by Category',
                style: TextStyle(
                    color: _TC.textPrimary(context),
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
                        style: TextStyle(
                            color: _TC.textPrimary(context),
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
        color: _TC.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(
                alpha: _TC.isDark(context) ? 0.15 : 0.25)),
        boxShadow: _TC.cardShadow(context),
      ),
      child: Column(
        children: [
          // FIX: FittedBox so long values (e.g. "1h 20m") don't overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _TC.textSec(context),
                fontWeight: FontWeight.w600,
                fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TASK DETAIL SHEET
  // ─────────────────────────────────────────────────────────────────────────
  void _showTaskDetail(TaskModel task, TaskProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setS) {
          final currentTask = prov.tasks
              .firstWhere((t) => t.id == task.id, orElse: () => task);
          final isDone = currentTask.status == TaskStatus.done;
          final isTimerOn = prov.isTimerRunningFor(currentTask.id);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: BoxDecoration(
              color: _TC.bg(context),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _TC.textSec(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentTask.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDone
                                      ? _TC.textSec(context)
                                      : _TC.textPrimary(context),
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
                                      ? _TC.done.withValues(alpha: 0.12)
                                      : _TC.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDone ? 'Undo' : 'Complete',
                                  style: TextStyle(
                                    color:
                                    isDone ? _TC.done : _TC.purple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _detailChip(
                                '${currentTask.categoryEmoji} ${currentTask.categoryLabel}',
                                _TC.purpleLight),
                            _detailChip(currentTask.priorityLabel,
                                _getPriorityColor(currentTask.priority)),
                            _detailChip(currentTask.formattedDueDate,
                                _TC.textSec(context)),
                            if (currentTask.formattedDueTime.isNotEmpty)
                              _detailChip(currentTask.formattedDueTime,
                                  _TC.textSec(context)),
                          ],
                        ),
                        if (currentTask.description != null &&
                            currentTask.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            currentTask.description!,
                            style: TextStyle(
                                color: _TC.textSec(context),
                                fontSize: 14,
                                height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _TC.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border:
                            Border.all(color: _TC.border(context)),
                            boxShadow: _TC.cardShadow(context),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Time Tracked',
                                      style: TextStyle(
                                          color: _TC.textSec(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTask.formattedElapsed,
                                    style: TextStyle(
                                      color: isTimerOn
                                          ? _TC.done
                                          : _TC.textPrimary(context),
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
                                      prov.stopTaskTimer(
                                          currentTask.id);
                                    } else {
                                      prov.startTaskTimer(
                                          currentTask.id);
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
                                          _TC.high.withValues(
                                              alpha: 0.7)
                                        ]
                                            : [
                                          _TC.done,
                                          _TC.done.withValues(
                                              alpha: 0.7)
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
                        if (currentTask.subtasks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Subtasks (${currentTask.subtasksDone.where((b) => b).length}/${currentTask.subtasks.length})',
                            style: TextStyle(
                                color: _TC.textPrimary(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(currentTask.subtasks.length,
                                  (i) {
                                final subDone =
                                    i < currentTask.subtasksDone.length &&
                                        currentTask.subtasksDone[i];
                                return GestureDetector(
                                  onTap: () {
                                    prov.toggleSubtask(
                                        currentTask.id, i);
                                    setS(() {});
                                  },
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: subDone
                                                ? _TC.done
                                                .withValues(alpha: 0.2)
                                                : Colors.transparent,
                                            border: Border.all(
                                                color: subDone
                                                    ? _TC.done
                                                    : _TC.textSec(context),
                                                width: 1.5),
                                          ),
                                          child: subDone
                                              ? const Icon(
                                              Icons.check_rounded,
                                              color: _TC.done,
                                              size: 14)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            currentTask.subtasks[i],
                                            style: TextStyle(
                                              color: subDone
                                                  ? _TC.textSec(context)
                                                  : _TC.textPrimary(
                                                  context),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              decoration: subDone
                                                  ? TextDecoration
                                                  .lineThrough
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
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              prov.deleteTask(currentTask.id);
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: _TC.high,
                                size: 18),
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
        border: Border.all(
            color: color.withValues(
                alpha: _TC.isDark(context) ? 0.15 : 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
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

  // ─────────────────────────────────────────────────────────────────────────
  // FAB
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE TASK SHEET
  // ─────────────────────────────────────────────────────────────────────────
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
              decoration: BoxDecoration(
                color: _TC.bg(context),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color:
                        _TC.textSec(context).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(Icons.close_rounded,
                              color: _TC.textSec(context), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'New Task',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _TC.textPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                          _formLabel('Category'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: TaskCategory.values.map((c) {
                              final isSel = selectedCategory == c;
                              final tmp = TaskModel(
                                  id: '',
                                  name: '',
                                  dueDate: DateTime.now(),
                                  createdAt: DateTime.now(),
                                  category: c);
                              return GestureDetector(
                                onTap: () =>
                                    setS(() => selectedCategory = c),
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? _TC.purple
                                        .withValues(alpha: 0.15)
                                        : _TC.card(context),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel
                                          ? _TC.purple
                                          : _TC.border(context),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${tmp.categoryEmoji} ${tmp.categoryLabel}',
                                    style: TextStyle(
                                      color: isSel
                                          ? _TC.purpleLight
                                          : _TC.textSec(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _formLabel('Due date'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked =
                                        await showDatePicker(
                                          context: ctx2,
                                          initialDate: selectedDate,
                                          firstDate:
                                          DateTime.now().subtract(
                                              const Duration(
                                                  days: 365)),
                                          lastDate: DateTime.now()
                                              .add(const Duration(
                                              days: 365)),
                                          builder: (c, child) => Theme(
                                            data: _TC.isDark(context)
                                                ? ThemeData.dark()
                                                .copyWith(
                                                colorScheme:
                                                const ColorScheme
                                                    .dark(
                                                  primary: _TC.purple,
                                                  surface: Color(
                                                      0xFF1A1730),
                                                ))
                                                : ThemeData.light()
                                                .copyWith(
                                                colorScheme:
                                                const ColorScheme
                                                    .light(
                                                  primary: _TC.purple,
                                                  surface:
                                                  Colors.white,
                                                )),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setS(() =>
                                          selectedDate = picked);
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _formLabel('Time'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked =
                                        await showTimePicker(
                                          context: ctx2,
                                          initialTime: TimeOfDay.now(),
                                          builder: (c, child) => Theme(
                                            data: _TC.isDark(context)
                                                ? ThemeData.dark()
                                                .copyWith(
                                                colorScheme:
                                                const ColorScheme
                                                    .dark(
                                                  primary: _TC.purple,
                                                  surface: Color(
                                                      0xFF1A1730),
                                                ))
                                                : ThemeData.light()
                                                .copyWith(
                                                colorScheme:
                                                const ColorScheme
                                                    .light(
                                                  primary: _TC.purple,
                                                  surface:
                                                  Colors.white,
                                                )),
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
                                  onTap: () =>
                                      setS(() => selectedPriority = p),
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? color.withValues(alpha: 0.12)
                                          : _TC.card(context),
                                      borderRadius:
                                      BorderRadius.circular(14),
                                      border: Border.all(
                                          color: isSel
                                              ? color
                                              : _TC.border(context),
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
                                            color: isSel
                                                ? color
                                                : _TC.textSec(context),
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
                          _formLabel(
                              'Estimated time: ${estimatedMinutes}m'),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _TC.purple,
                              inactiveTrackColor: _TC.isDark(context)
                                  ? _TC.card(context)
                                  : const Color(0xFFD0DAE8),
                              thumbColor: _TC.purpleLight,
                              overlayColor:
                              _TC.purple.withValues(alpha: 0.2),
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
                          const SizedBox(height: 12),
                          _formLabel('Subtasks'),
                          const SizedBox(height: 8),
                          ...subtasks.asMap().entries.map((e) {
                            return Padding(
                              padding:
                              const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                      Icons
                                          .subdirectory_arrow_right_rounded,
                                      color: _TC.textSec(context),
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e.value,
                                        style: TextStyle(
                                            color:
                                            _TC.textPrimary(context),
                                            fontSize: 14)),
                                  ),
                                  GestureDetector(
                                    onTap: () => setS(
                                            () => subtasks.removeAt(e.key)),
                                    child: Icon(Icons.close_rounded,
                                        color: _TC.textSec(context),
                                        size: 18),
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
                                  style: TextStyle(
                                      color: _TC.textPrimary(context),
                                      fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Add subtask...',
                                    hintStyle: TextStyle(
                                        color: _TC.textSec(context)
                                            .withValues(alpha: 0.6)),
                                    filled: true,
                                    fillColor: _TC.inputFill(context),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
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
                                      subtasks.add(
                                          subtaskCtrl.text.trim());
                                      subtaskCtrl.clear();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _TC.purple
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _TC.purple
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      color: _TC.purple, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _formLabel('Set reminder'),
                              const Spacer(),
                              Switch(
                                value: hasReminder,
                                onChanged: (v) =>
                                    setS(() => hasReminder = v),
                                activeTrackColor:
                                _TC.purple.withValues(alpha: 0.5),
                                activeThumbColor: _TC.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a task name'),
                                        backgroundColor: _TC.high),
                                  );
                                  return;
                                }
                                final task = TaskModel(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  name: nameCtrl.text.trim(),
                                  description:
                                  descCtrl.text.trim().isNotEmpty
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
                                  subtasksDone: List.filled(
                                      subtasks.length, false),
                                );
                                context
                                    .read<TaskProvider>()
                                    .addTask(task);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _TC.purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18)),
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
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _TC.textSec(context)),
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
      style: TextStyle(
          color: _TC.textPrimary(context), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: _TC.textSec(context).withValues(alpha: 0.6)),
        filled: true,
        fillColor: _TC.inputFill(context),
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
        color: _TC.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _TC.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: _TC.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          Icon(icon, color: _TC.textSec(context), size: 18),
        ],
      ),
    );
  }
}