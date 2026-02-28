import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/habit.dart';
import 'package:monojog/providers/habit_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/screens/habit_detail_screen.dart';
import 'package:monojog/widgets/add_habit_sheet.dart';

// ── Color constants ──
class _HC {
  static const bg = Color(0xFF0A0A0F);
  static const card = Color(0xFF14141C);
  static const textSec = Color(0xFF8B8FA3);
  static const mint = Color(0xFF00E5A0);
  static const purple = Color(0xFF7C4DFF);
  static const gold = Color(0xFFFFD700);
  static const red = Color(0xFFFF4D6D);
}

Color _hex(String hex) {
  final c = hex.replaceAll('#', '');
  return Color(int.parse(c.length == 6 ? 'FF$c' : c, radix: 16));
}

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, GameProvider>(
      builder: (ctx, habits, game, _) => Scaffold(
        backgroundColor: _HC.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(habits),
              _buildTodayProgress(habits),
              _buildWeekDayRow(),
              const SizedBox(height: 4),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _HC.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: _HC.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: _HC.purple.withValues(alpha: 0.3)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  labelColor: _HC.purple,
                  unselectedLabelColor: _HC.textSec,
                  tabs: [
                    Tab(text: 'Today (${habits.scheduledTodayCount()})'),
                    const Tab(text: 'All Habits'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildTodayTab(habits, game),
                    _buildAllTab(habits),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSheet(context),
          backgroundColor: _HC.purple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(HabitProvider habits) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _HC.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Habits',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                Text('${habits.activeCount} habits tracked',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _HC.textSec)),
              ],
            ),
          ),
          // Template packs button
          GestureDetector(
            onTap: () => _showTemplatePacks(context, habits),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _HC.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _HC.gold.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: _HC.gold, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today Progress Ring ──
  Widget _buildTodayProgress(HabitProvider habits) {
    final done = habits.completedTodayCount();
    final total = habits.scheduledTodayCount();
    final pct = total > 0 ? done / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _HC.purple.withValues(alpha: 0.08),
              _HC.mint.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                        pct >= 1.0 ? _HC.gold : _HC.mint),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      pct >= 1.0 ? '🎉' : '${(pct * 100).round()}%',
                      style: GoogleFonts.inter(
                        fontSize: pct >= 1.0 ? 22 : 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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
                      pct >= 1.0
                          ? 'All Done! Amazing! 🔥'
                          : 'Today\'s Progress',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('$done of $total habits completed',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _HC.textSec)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Week Day Headers ──
  Widget _buildWeekDayRow() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayIdx = now.weekday - 1; // 0=Mon

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const SizedBox(width: 44), // avatar space
          ...List.generate(7, (i) {
            final date = _weekStart.add(Duration(days: i));
            final isToday = i == todayIdx;
            return Expanded(
              child: Column(
                children: [
                  Text(
                    days[i],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isToday ? _HC.purple : _HC.textSec,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? _HC.purple
                          : _HC.textSec.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 14), // streak space
        ],
      ),
    );
  }

  // ── TODAY TAB ──
  Widget _buildTodayTab(HabitProvider habits, GameProvider game) {
    final today = DateTime.now().weekday;
    final scheduled =
        habits.habits.where((h) => h.isScheduledFor(today)).toList();

    if (scheduled.isEmpty) {
      return _emptyState(
        emoji: '📋',
        title: 'No habits for today',
        subtitle: 'Tap + to create your first habit',
      );
    }

    // Sort: incomplete first, then completed
    scheduled.sort((a, b) {
      final aDone = habits.isCompletedToday(a.id);
      final bDone = habits.isCompletedToday(b.id);
      if (aDone != bDone) return aDone ? 1 : -1;
      return a.title.compareTo(b.title);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: scheduled.length,
      itemBuilder: (ctx, i) => _habitRow(habits, game, scheduled[i]),
    );
  }

  // ── Habit Row with weekly dots ──
  Widget _habitRow(HabitProvider habits, GameProvider game, Habit habit) {
    final color = _hex(habit.color);
    final todayDone = habits.isCompletedToday(habit.id);
    final weekData = habits.getWeekCompletions(habit.id, _weekStart);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habitId: habit.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: todayDone ? color.withValues(alpha: 0.06) : _HC.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: todayDone
                ? color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            // Tap to complete
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: todayDone ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: todayDone ? color : color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: todayDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : Text(habit.emoji,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 10),
            // Weekly dots
            ...List.generate(7, (i) {
              final done = weekData[i];
              final isToday = i == (DateTime.now().weekday - 1);
              return Expanded(
                child: Center(
                  child: Container(
                    width: isToday ? 22 : 18,
                    height: isToday ? 22 : 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? color.withValues(alpha: 0.9)
                          : (isToday
                              ? color.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.04)),
                      border: isToday && !done
                          ? Border.all(
                              color: color.withValues(alpha: 0.4), width: 1.5)
                          : null,
                      boxShadow: done
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 10, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }),
            const SizedBox(width: 6),
            // Streak
            if (habit.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _HC.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${habit.currentStreak}🔥',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _HC.gold)),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── ALL TAB ──
  Widget _buildAllTab(HabitProvider habits) {
    if (habits.habits.isEmpty) {
      return _emptyState(
        emoji: '🌱',
        title: 'Start building habits',
        subtitle: 'Tap + or ✨ templates to begin',
      );
    }

    // Group by category
    final byCategory = <HabitCategory, List<Habit>>{};
    for (final h in habits.habits) {
      byCategory.putIfAbsent(h.category, () => []).add(h);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: byCategory.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(entry.key.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(entry.key.label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(width: 8),
                  Text('${entry.value.length}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _HC.textSec)),
                ],
              ),
            ),
            ...entry.value.map((h) => _allHabitTile(habits, h)),
          ],
        );
      }).toList(),
    );
  }

  Widget _allHabitTile(HabitProvider habits, Habit habit) {
    final color = _hex(habit.color);
    final recent = habits.getRecentDays(habit.id, 30);
    final completedDays = recent.where((e) => e.value).length;
    final rate = recent.isEmpty ? 0.0 : completedDays / recent.length;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habitId: habit.id))),
      onLongPress: () => _showHabitActions(habit, habits),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _HC.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child:
                      Text(habit.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(habit.repeatLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _HC.textSec)),
                      Text('  ·  ',
                          style: GoogleFonts.inter(color: _HC.textSec)),
                      Text('${(rate * 100).round()}% rate',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ],
                  ),
                ],
              ),
            ),
            // Mini heat strip (last 14 days)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: recent
                  .skip(recent.length > 14 ? recent.length - 14 : 0)
                  .map((e) {
                return Container(
                  width: 4,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: e.value
                        ? color.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 8),
            if (habit.currentStreak > 0)
              Text('${habit.currentStreak}🔥',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _HC.gold)),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──
  Widget _emptyState(
      {required String emoji,
      required String title,
      required String subtitle}) {
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
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _HC.textSec)),
        ],
      ),
    );
  }

  // ── Bottom Sheets ──
  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHabitSheet(),
    );
  }

  void _showTemplatePacks(BuildContext context, HabitProvider habits) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollController) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('✨ Template Packs',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Quick-start with curated habits',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _HC.textSec)),
                      const SizedBox(height: 16),
                      Expanded(
                          child: ListView(
                        controller: scrollController,
                        children: HabitTemplatePack.all
                            .map((pack) => GestureDetector(
                                  onTap: () {
                                    habits.createFromPack(pack);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Added ${pack.templates.length} habits from "${pack.name}"',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600)),
                                        backgroundColor: _HC.mint,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _HC.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(pack.emoji,
                                            style:
                                                const TextStyle(fontSize: 24)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(pack.name,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white)),
                                              Text(
                                                  '${pack.subtitle} · ${pack.templates.length} habits',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: _HC.textSec)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.add_circle_outline_rounded,
                                            color: _HC.purple
                                                .withValues(alpha: 0.6),
                                            size: 22),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      )),
                    ],
                  ),
                ));
      },
    );
  }

  void _showHabitActions(Habit habit, HabitProvider habits) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: _HC.purple),
                title: Text('Edit',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddHabitSheet(editHabit: habit),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_rounded, color: _HC.gold),
                title: Text('Archive',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  habits.archiveHabit(habit.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: _HC.red),
                title: Text('Delete',
                    style: GoogleFonts.inter(
                        color: _HC.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  habits.deleteHabit(habit.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
