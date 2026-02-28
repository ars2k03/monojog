import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/models/tshirt_model.dart';
import 'package:monojog/services/merch_service.dart';

// ── Garden color palette (dark neumorphic) ──
class _GC {
  static const bg = AppTheme.darkBg;
  static const card = AppTheme.darkCard;
  static const green = AppTheme.primaryColor;
  static const greenDark = AppTheme.secondaryColor;
  static const greenLight = AppTheme.darkSurface;
  static const greenPale = AppTheme.darkSurface;
  static const lime = AppTheme.primaryColor;
  static const gold = AppTheme.goldColor;
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textSec = Color(0xFF8B8FA3);
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: _GC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _StatisticsTab(),
                  _FlowerGardenTab(),
                  _MerchTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'My Garden',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _GC.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: '  🌿',
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
          ),
          const Spacer(),
          Consumer<GameProvider>(
            builder: (ctx, game, _) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _GC.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _GC.gold.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${game.profile.level}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF8F00)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: _GC.textSec,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_GC.green, _GC.lime],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _GC.green.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 18),
                SizedBox(width: 6),
                Text('Stats'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌸', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('Garden'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_rounded, size: 18),
                SizedBox(width: 6),
                Text('TShirt'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  STATISTICS TAB
// ════════════════════════════════════════════════
class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, FocusProvider>(
      builder: (ctx, game, focus, _) {
        final profile = game.profile;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards row 1
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_rounded,
                      value: '${profile.totalFocusMinutes}',
                      unit: 'min',
                      label: 'Total Focus',
                      color: _GC.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      value: '${profile.sessionsCompleted}',
                      unit: '',
                      label: 'Sessions Done',
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '${profile.currentStreak}',
                      unit: 'days',
                      label: 'Current Streak',
                      color: const Color(0xFFFF7043),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      value: '${profile.longestStreak}',
                      unit: 'days',
                      label: 'Best Streak',
                      color: _GC.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly chart header
              const Text(
                'Weekly Focus (minutes)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _GC.textDark,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),

              // Bar Chart
              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                decoration: BoxDecoration(
                  color: _GC.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: max(
                        120,
                        (profile.totalFocusMinutes / 7 * 2)
                            .clamp(120, 360)
                            .toDouble()),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        // tooltipBgColor: _GC.greenDark,
                        // tooltipRoundedRadius: 10,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} min',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                days[value.toInt() % 7],
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _GC.textSec),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: _GC.textSec,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 30,
                      getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildWeeklyBars(profile.totalFocusMinutes),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Concentration trend section
              const Text(
                'Concentration Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _GC.textDark,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              _buildConcentrationCard(
                  focus.pomodoroCount, profile.totalFocusMinutes),
            ],
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildWeeklyBars(int totalMinutes) {
    final rng = Random(totalMinutes);
    final weekData = List.generate(7, (i) {
      final base = (totalMinutes / 7).clamp(0, 120).toInt();
      final variance = rng.nextInt(40) - 15;
      return max(0, base + variance).toDouble();
    });
    weekData[6] = 0; // today always starts at 0

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weekData[i],
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                _GC.green.withValues(alpha: 0.6),
                _GC.lime,
              ],
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 120,
              color: _GC.greenLight.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildConcentrationCard(int pomodoros, int totalMinutes) {
    final score = ((pomodoros * 25 + totalMinutes) / 10).clamp(0, 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: _GC.greenLight.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(_GC.green),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _GC.textDark,
                        ),
                      ),
                      const Text(
                        '%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _GC.textSec),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concentration Index',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _GC.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  _concentrationLabel(score),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _GC.green.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 10),
                _miniChip('$pomodoros 🍅 Pomodoros'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _concentrationLabel(int score) {
    if (score >= 80) return '🌟 Excellent focus!';
    if (score >= 60) return '👍 Good progress!';
    if (score >= 40) return '📚 Keep going!';
    if (score >= 20) return '🌱 Just getting started';
    return '⏰ Start your first session!';
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _GC.greenPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _GC.greenDark)),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _GC.textSec)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  FLOWER GARDEN TAB
// ════════════════════════════════════════════════
class _FlowerGardenTab extends StatefulWidget {
  const _FlowerGardenTab();

  @override
  State<_FlowerGardenTab> createState() => _FlowerGardenTabState();
}

class _FlowerGardenTabState extends State<_FlowerGardenTab>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnim;

  static const _stages = [
    _PlantStage('🌱', 'Seed', 'Your journey begins!', 0),
    _PlantStage('🌿', 'Sprout', 'Growing steadily...', 60),
    _PlantStage('🌷', 'Bud', 'Almost there!', 180),
    _PlantStage('🌸', 'Bloom', 'Beautifully focused!', 360),
    _PlantStage('🌳', 'Full Tree', 'Mastery unlocked! 🎉', 600),
  ];

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  _PlantStage _currentStage(int minutes) {
    _PlantStage stage = _stages[0];
    for (final s in _stages) {
      if (minutes >= s.requiredMinutes) stage = s;
    }
    return stage;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (ctx, game, _) {
        final profile = game.profile;
        final totalMin = profile.totalFocusMinutes;
        final stage = _currentStage(totalMin);
        final nextStageIndex =
            _stages.indexWhere((s) => s.requiredMinutes > totalMin);
        final nextStage = nextStageIndex >= 0 ? _stages[nextStageIndex] : null;
        final progress = nextStage != null
            ? (totalMin - stage.requiredMinutes) /
                max(1, nextStage.requiredMinutes - stage.requiredMinutes)
            : 1.0;
        final fullTrees = totalMin ~/ 600;
        final gardenPlants = _buildGardenPlants(totalMin);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCurrentPlant(stage, progress, nextStage, totalMin),
              const SizedBox(height: 24),
              if (fullTrees > 0) _buildRewardBanner(fullTrees),
              if (fullTrees > 0) const SizedBox(height: 20),
              _buildGardenGrid(gardenPlants),
              const SizedBox(height: 24),
              _buildGrowthRoadmap(totalMin),
              const SizedBox(height: 24),
              _buildBadgesSection(game),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentPlant(
    _PlantStage stage,
    double progress,
    _PlantStage? nextStage,
    int totalMin,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _GC.green.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _GC.green.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _sparkleAnim,
            builder: (_, __) => Transform.scale(
              scale: _sparkleAnim.value,
              child: Text(
                stage.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stage.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _GC.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stage.message,
            style: const TextStyle(
              fontSize: 14,
              color: _GC.textSec,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (nextStage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$totalMin min',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _GC.green)),
                Text('Next: ${nextStage.emoji} ${nextStage.name}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _GC.textSec)),
                Text('${nextStage.requiredMinutes} min',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _GC.textSec)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 10,
                  backgroundColor: _GC.greenLight.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(_GC.green),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_GC.green, _GC.lime],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🏆 Maximum Growth Achieved!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardBanner(int trees) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _GC.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🌳', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've grown $trees full tree${trees > 1 ? 's' : ''}!",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trees * 600} minutes of pure focus. Amazing! 🎉',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildGardenPlants(int totalMin) {
    final plants = <String>[];
    int remaining = totalMin;
    while (remaining >= 600) {
      plants.add('🌳');
      remaining -= 600;
    }
    if (remaining >= 360) {
      plants.add('🌸');
    } else if (remaining >= 180) {
      plants.add('🌷');
    } else if (remaining >= 60) {
      plants.add('🌿');
    } else if (remaining > 0) {
      plants.add('🌱');
    }
    while (plants.length < 6) {
      plants.add('');
    }
    return plants;
  }

  Widget _buildGardenGrid(List<String> plants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Garden',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _GC.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _GC.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: plants.length,
            itemBuilder: (ctx, i) {
              final p = plants[i];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + i * 80),
                curve: Curves.easeOutBack,
                decoration: BoxDecoration(
                  color: p.isNotEmpty
                      ? _GC.greenPale
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p.isNotEmpty
                        ? _GC.green.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: p.isNotEmpty
                      ? Text(p, style: const TextStyle(fontSize: 36))
                      : Icon(Icons.add_rounded,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 28),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthRoadmap(int totalMin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth Milestones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _GC.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ..._stages.map((stage) {
          final isUnlocked = totalMin >= stage.requiredMinutes;
          final isCurrent = _currentStage(totalMin) == stage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _GC.green.withValues(alpha: 0.1)
                  : isUnlocked
                      ? _GC.greenPale
                      : _GC.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? _GC.green
                    : isUnlocked
                        ? _GC.green.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.15),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(stage.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? _GC.textDark : _GC.textSec,
                        ),
                      ),
                      Text(
                        stage.requiredMinutes == 0
                            ? 'Starting point'
                            : '${stage.requiredMinutes} minutes of focus',
                        style:
                            const TextStyle(fontSize: 11, color: _GC.textSec),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _GC.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Current',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  )
                else if (isUnlocked)
                  const Icon(Icons.check_circle_rounded,
                      color: _GC.green, size: 24)
                else
                  const Icon(Icons.lock_rounded, color: _GC.textSec, size: 24),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBadgesSection(GameProvider game) {
    final rewards = game.rewards;
    if (rewards.isEmpty) return const SizedBox.shrink();

    // Show all purchased or affordable rewards as garden trophies
    final unlockedRewards = rewards.take(6).toList();
    if (unlockedRewards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rewards & Badges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _GC.textDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: unlockedRewards.length.clamp(0, 6),
          itemBuilder: (ctx, i) {
            final r = unlockedRewards[i];
            return Container(
              decoration: BoxDecoration(
                color: _GC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _GC.gold.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _GC.gold.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(r.icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(
                    r.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _GC.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlantStage {
  final String emoji;
  final String name;
  final String message;
  final int requiredMinutes;

  const _PlantStage(this.emoji, this.name, this.message, this.requiredMinutes);
}

// ════════════════════════════════════════════════
//  MERCH TAB
// ════════════════════════════════════════════════
class _MerchTab extends StatefulWidget {
  const _MerchTab();

  @override
  State<_MerchTab> createState() => _MerchTabState();
}

class _MerchTabState extends State<_MerchTab> {
  late final Future<void> _seedFuture;

  @override
  void initState() {
    super.initState();
    _seedFuture = MerchService.instance.seedDefaultTShirtsIfEmpty(
      tshirts: TShirt.catalog.take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _seedFuture,
      builder: (context, seedSnap) {
        if (seedSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<TShirt>>(
          stream: MerchService.instance.watchTShirts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load t-shirts right now.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              );
            }

            final tshirts = snapshot.data ?? const <TShirt>[];
            if (tshirts.isEmpty) {
              return const Center(
                child: Text(
                  'No t-shirts available yet.',
                  style: TextStyle(color: _GC.textSec),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tshirts.length,
              itemBuilder: (context, index) {
                final tshirt = tshirts[index];
                return _buildTShirtCard(context, tshirt);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTShirtCard(BuildContext context, TShirt tshirt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showOrderForm(context, tshirt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _GC.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      tshirt.designEmoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tshirt.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _GC.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tshirt.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _GC.textSec,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _GC.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${tshirt.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _GC.green,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: _GC.green,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderForm(BuildContext context, TShirt tshirt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MerchOrderForm(tshirt: tshirt),
    );
  }
}

class _MerchOrderForm extends StatefulWidget {
  final TShirt tshirt;

  const _MerchOrderForm({required this.tshirt});

  @override
  State<_MerchOrderForm> createState() => _MerchOrderFormState();
}

class _MerchOrderFormState extends State<_MerchOrderForm> {
  final _formKey = GlobalKey<FormState>();
  String _selectedSize = 'M';
  String _selectedColor = '';
  String _paymentMethod = 'bKash';
  bool _isSubmitting = false;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _trxIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tshirt.colors.isNotEmpty) {
      _selectedColor = widget.tshirt.colors.first;
    }
    if (widget.tshirt.sizes.isNotEmpty) {
      _selectedSize = widget.tshirt.sizes.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login first to place an order.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderId =
          'order_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 6)}';
      final order = TShirtOrder(
        id: orderId,
        tshirtId: widget.tshirt.id,
        tshirtName: widget.tshirt.name,
        userId: user.uid,
        userEmail: user.email ?? '',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        size: _selectedSize,
        color: _selectedColor,
        price: widget.tshirt.price,
        paymentMethod: _paymentMethod,
        merchantNumber: MerchService.merchantPaymentNumber,
        transactionId: _trxIdController.text.trim(),
        orderedAt: DateTime.now(),
      );

      await MerchService.instance.placeOrder(order);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed for ${widget.tshirt.name}!'),
          backgroundColor: _GC.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to place order. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: _GC.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _GC.textSec.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    widget.tshirt.designEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${widget.tshirt.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _GC.textDark,
                          ),
                        ),
                        Text(
                          '₹${widget.tshirt.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _GC.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _GC.textSec,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.tshirt.sizes.map((size) {
                  final isSelected = _selectedSize == size;
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSize = size);
                    },
                    selectedColor: _GC.green.withValues(alpha: 0.2),
                    backgroundColor: _GC.card,
                    labelStyle: TextStyle(
                      color: isSelected ? _GC.green : _GC.textSec,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? _GC.green : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _GC.textSec,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.tshirt.colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return ChoiceChip(
                    label: Text(color),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedColor = color);
                    },
                    selectedColor: _GC.green.withValues(alpha: 0.2),
                    backgroundColor: _GC.card,
                    labelStyle: TextStyle(
                      color: isSelected ? _GC.green : _GC.textSec,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? _GC.green : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _GC.textSec,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['bKash', 'Nagad'].map((method) {
                  final isSelected = _paymentMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = method);
                    },
                    selectedColor: _GC.green.withValues(alpha: 0.2),
                    backgroundColor: _GC.card,
                    labelStyle: TextStyle(
                      color: isSelected ? _GC.green : _GC.textSec,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? _GC.green : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _GC.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _GC.green.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send payment to',
                      style: TextStyle(
                        color: _GC.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '01797859806',
                      style: TextStyle(
                        color: _GC.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trxIdController,
                style: const TextStyle(color: _GC.textDark),
                decoration: InputDecoration(
                  labelText: 'Transaction ID',
                  labelStyle: const TextStyle(color: _GC.textSec),
                  filled: true,
                  fillColor: _GC.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter transaction ID'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: _GC.textDark),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: _GC.textSec),
                  filled: true,
                  fillColor: _GC.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: _GC.textDark),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: _GC.textSec),
                  filled: true,
                  fillColor: _GC.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: _GC.textDark),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  labelStyle: const TextStyle(color: _GC.textSec),
                  filled: true,
                  fillColor: _GC.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _GC.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSubmitting ? 'Placing Order...' : 'Place Order',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
