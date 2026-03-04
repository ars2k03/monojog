import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/habit.dart';
import 'package:monojog/providers/habit_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/widgets/add_habit_sheet.dart';

// ── Adaptive palette (light + dark) ─────────────────────────────────────────
class _D {
  static Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF0F4F8);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF14141C)
          : const Color(0xFFFFFFFF);

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0D1117);

  static Color textSec(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF8B8FA3)
          : const Color(0xFF5A6070);

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.07);

  static Color surface(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.05);

  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static List<BoxShadow> shadow(BuildContext ctx) => isDark(ctx)
      ? []
      : [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3))
  ];
}

Color _hex(String hex) {
  final c = hex.replaceAll('#', '');
  return Color(int.parse(c.length == 6 ? 'FF$c' : c, radix: 16));
}

class HabitDetailScreen extends StatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});
  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, GameProvider>(
      builder: (ctx, habits, game, _) {
        final habit =
            habits.habits.where((h) => h.id == widget.habitId).firstOrNull ??
                habits.archivedHabits
                    .where((h) => h.id == widget.habitId)
                    .firstOrNull;

        if (habit == null) {
          return Scaffold(
            backgroundColor: _D.bg(context),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: _D.textPrimary(context)),
            ),
            body: Center(
                child: Text('Habit not found',
                    style: GoogleFonts.inter(
                        color: _D.textPrimary(context)))),
          );
        }

        final color = _hex(habit.color);
        final recent = habits.getRecentDays(habit.id, 30);
        final completedDays = recent.where((e) => e.value).length;
        final rate = recent.isEmpty ? 0.0 : completedDays / recent.length;
        final todayDone = habits.isCompletedToday(habit.id);

        return Scaffold(
          backgroundColor: _D.bg(context),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _D.card(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                  Border.all(color: _D.border(context)),
                                  boxShadow: _D.shadow(context),
                                ),
                                child: Icon(Icons.arrow_back_rounded,
                                    color: _D.textPrimary(context),
                                    size: 20),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    AddHabitSheet(editHabit: habit),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                      color.withValues(alpha: 0.2)),
                                  boxShadow: _D.shadow(context),
                                ),
                                child: Icon(Icons.edit_rounded,
                                    color: color, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Habit info
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                  child: Text(habit.emoji,
                                      style:
                                      const TextStyle(fontSize: 28))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(habit.title,
                                      style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color:
                                          _D.textPrimary(context))),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        child: Text(habit.category.label,
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight:
                                                FontWeight.w700,
                                                color: color)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(habit.repeatLabel,
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color:
                                              _D.textSec(context))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Complete today button
                        GestureDetector(
                          onTap: () {
                            habits.toggleCompletion(habit.id);
                            if (!todayDone) {
                              game.addExperience(5);
                              game.addGold(2);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: todayDone
                                  ? null
                                  : LinearGradient(colors: [
                                color,
                                color.withValues(alpha: 0.7)
                              ]),
                              color: todayDone
                                  ? color.withValues(alpha: 0.08)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              border: todayDone
                                  ? Border.all(
                                  color: color.withValues(alpha: 0.3))
                                  : null,
                              boxShadow: todayDone
                                  ? null
                                  : [
                                BoxShadow(
                                    color:
                                    color.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  todayDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color:
                                  todayDone ? color : Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                    todayDone
                                        ? 'Completed Today ✓'
                                        : 'Mark as Done',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: todayDone
                                          ? color
                                          : Colors.white,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats Cards ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        _statCard(context, 'Current\nStreak',
                            '${habit.currentStreak}', '🔥', color),
                        const SizedBox(width: 10),
                        _statCard(context, 'Best\nStreak',
                            '${habit.bestStreak}', '🏆',
                            const Color(0xFFFFD700)),
                        const SizedBox(width: 10),
                        _statCard(context, '30-day\nRate',
                            '${(rate * 100).round()}%', '📊',
                            const Color(0xFF00E5A0)),
                        const SizedBox(width: 10),
                        _statCard(context, 'Total\nDays',
                            '$completedDays', '📅',
                            const Color(0xFF00B4D8)),
                      ],
                    ),
                  ),
                ),

                // ── Calendar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildCalendar(habits, habit, color),
                  ),
                ),

                // ── Heat Map ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildHeatMap(habits, habit, color),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _D.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _D.border(context)),
          boxShadow: _D.shadow(context),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _D.textSec(context),
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ── Calendar View ──────────────────────────────────────────────────────────
  Widget _buildCalendar(HabitProvider habits, Habit habit, Color color) {
    final completions = habits.getMonthCompletions(
        habit.id, _viewMonth.year, _viewMonth.month);
    final completionDays = completions.map((d) => d.day).toSet();

    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.border(context)),
        boxShadow: _D.shadow(context),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month - 1);
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _D.surface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: _D.textPrimary(context), size: 20),
                ),
              ),
              Text(
                '${_monthName(_viewMonth.month)} ${_viewMonth.year}',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _D.textPrimary(context)),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month + 1);
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _D.surface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: _D.textPrimary(context), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Day headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
              child: Text(d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _D.textSec(context))),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Day grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (dayIdx) {
                final cellIndex = week * 7 + dayIdx;
                final dayNum = cellIndex - (startWeekday - 1) + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 36));
                }

                final isCompleted = completionDays.contains(dayNum);
                final isToday = today.year == _viewMonth.year &&
                    today.month == _viewMonth.month &&
                    today.day == dayNum;
                final isFuture =
                DateTime(_viewMonth.year, _viewMonth.month, dayNum)
                    .isAfter(today);

                return Expanded(
                  child: GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                      final date = _dateStr(DateTime(
                          _viewMonth.year,
                          _viewMonth.month,
                          dayNum));
                      habits.toggleCompletion(habit.id, date: date);
                    },
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? color.withValues(alpha: 0.8)
                            : (isToday
                            ? color.withValues(alpha: 0.08)
                            : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isCompleted
                            ? Border.all(
                            color: color.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Center(
                        child: Text('$dayNum',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isCompleted || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCompleted
                                  ? Colors.white
                                  : (isFuture
                                  ? _D.textSec(context)
                                  .withValues(alpha: 0.3)
                                  : _D.textSec(context)),
                            )),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  // ── 90-day heat map ──────────────────────────────────────────────────────
  Widget _buildHeatMap(HabitProvider habits, Habit habit, Color color) {
    final recent = habits.getRecentDays(habit.id, 90);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.border(context)),
        boxShadow: _D.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity (90 days)',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _D.textPrimary(context))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: recent.map((entry) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.value
                      ? color.withValues(alpha: 0.85)
                      : _D.surface(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Less',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: _D.textSec(context))),
              const SizedBox(width: 4),
              ...List.generate(
                  4,
                      (i) => Container(
                    width: 10,
                    height: 10,
                    margin:
                    const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color:
                      color.withValues(alpha: 0.2 + i * 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              const SizedBox(width: 4),
              Text('More',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: _D.textSec(context))),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month];
  }
}