import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/widgets/neu_container.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (ctx, game, _) {
        final profile = game.profile;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Progress',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'Total Focus',
                          value: '${profile.totalFocusMinutes} min',
                          icon: Icons.timer_rounded,
                          color: AppTheme.primaryColor,
                          bgColor: cardColor)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _StatCard(
                          title: 'Sessions Done',
                          value: '${profile.sessionsCompleted}',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.successColor,
                          bgColor: cardColor)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'Current Streak',
                          value: '${profile.currentStreak} days',
                          icon: Icons.local_fire_department_rounded,
                          color: AppTheme.goldColor,
                          bgColor: cardColor)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _StatCard(
                          title: 'Longest Streak',
                          value: '${profile.longestStreak} days',
                          icon: Icons.emoji_events_rounded,
                          color: AppTheme.gemColor,
                          bgColor: cardColor)),
                ],
              ),

              const SizedBox(height: 40),
              const Text('Weekly Focus (minutes)',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const SizedBox(height: 20),

              // Chart
              NeuContainer(
                height: 280,
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    width: 1.5),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 120, // Mock max
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Sat',
                              'Sun',
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri'
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(days[value.toInt() % 7],
                                  style: const TextStyle(fontSize: 12)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10)),
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
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeGroup(0, 45, AppTheme.primaryColor),
                      _makeGroup(1, 60, AppTheme.primaryColor),
                      _makeGroup(2, 30, AppTheme.primaryColor),
                      _makeGroup(3, 90, AppTheme.primaryColor),
                      _makeGroup(4, 120, AppTheme.primaryColor),
                      _makeGroup(5, 45, AppTheme.primaryColor),
                      _makeGroup(6, 0, AppTheme.primaryColor), // Today
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 120,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
