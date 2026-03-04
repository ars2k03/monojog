import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/sleep_provider.dart';
import 'package:monojog/theme/app_theme.dart';

// ── Fixed accent colors (vivid enough for both modes) ──────────────────────
class _SC {
  static const mint = Color(0xFF00BFA5);
  static const mintDark = Color(0xFF009688);
  static const purple = Color(0xFF7C4DFF);
  static const rem = Color(0xFFE53935);
  static const core = Color(0xFF26A69A);
  static const deep = Color(0xFF7C4DFF);
  static const light = Color(0xFFF9A825);

  // ── Semantic tokens ──────────────────────────────────────────────────────
  static Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? AppTheme.darkBg
          : const Color(0xFFF0F4F8);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white;

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0D1117);

  static Color textSec(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.45)
          : const Color(0xFF5A6070);

  static Color textMuted(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.3)
          : const Color(0xFF8A94A6);

  static Color surfaceMuted(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05);

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.07);

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

class SleepInsightsScreen extends StatelessWidget {
  const SleepInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (ctx, sleep, _) {
        return Scaffold(
          backgroundColor: _SC.bg(context),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: sleep.sleepHistory.isEmpty
                      ? _buildEmptyState(context)
                      : _buildContent(context, sleep),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _SC.card(context),
                shape: BoxShape.circle,
                border: Border.all(color: _SC.border(context)),
                boxShadow: _SC.shadow(context),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: _SC.textPrimary(context), size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Sleep Insights',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _SC.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nights_stay_rounded,
              color: _SC.mint.withValues(alpha: 0.35), size: 72),
          const SizedBox(height: 16),
          Text(
            'No sleep data yet',
            style: TextStyle(
              color: _SC.textSec(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking to see insights',
            style: TextStyle(
              color: _SC.textMuted(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context, SleepProvider sleep) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSleepScoreRing(context, sleep),
          const SizedBox(height: 20),
          _buildStageBreakdown(context, sleep),
          const SizedBox(height: 20),
          _buildSuggestions(context, sleep),
          const SizedBox(height: 20),
          _buildHistoryList(context, sleep),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Sleep Score Ring ─────────────────────────────────────────────────────
  Widget _buildSleepScoreRing(BuildContext context, SleepProvider sleep) {
    return _AdaptiveCard(
      context: context,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Overall Sleep Quality',
            style: TextStyle(
              color: _SC.textPrimary(context),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _SleepScoreRingPainter(
                score: sleep.averageQuality / 100.0,
                trackColor: _SC.surfaceMuted(context),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${sleep.averageQuality}',
                      style: TextStyle(
                        color: _SC.textPrimary(context),
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Quality Score',
                      style: TextStyle(
                        color: _SC.textMuted(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat(
                  context,
                  Icons.bedtime_rounded,
                  '${sleep.averageSleepHours.toStringAsFixed(1)}h',
                  'Avg Duration',
                  _SC.mint),
              _miniStat(context, Icons.local_fire_department_rounded,
                  '${sleep.sleepStreak}', 'Streak', _SC.rem),
              _miniStat(context, Icons.format_list_numbered_rounded,
                  '${sleep.sleepHistory.length}', 'Total', _SC.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: _SC.textMuted(context),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Stage Breakdown ──────────────────────────────────────────────────────
  Widget _buildStageBreakdown(BuildContext context, SleepProvider sleep) {
    final sessions = sleep.sleepHistory;
    if (sessions.isEmpty) return const SizedBox.shrink();

    double avgDeep = 0, avgCore = 0, avgRem = 0, avgLight = 0;
    for (final s in sessions) {
      avgDeep += s.deepHours;
      avgCore += s.coreHours;
      avgRem += s.remHours;
      avgLight += s.lightHours;
    }
    final n = sessions.length;
    avgDeep /= n;
    avgCore /= n;
    avgRem /= n;
    avgLight /= n;
    final total = avgDeep + avgCore + avgRem + avgLight;

    return _AdaptiveCard(
      context: context,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Average Sleep Stages',
              style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 160,
            child: CustomPaint(
              painter: _StageDonutPainter(
                deep: avgDeep,
                core: avgCore,
                rem: avgRem,
                light: avgLight,
                trackColor: _SC.surfaceMuted(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _stageRow(context, 'Deep Sleep', avgDeep, total, _SC.deep,
              Icons.waves_rounded),
          const SizedBox(height: 12),
          _stageRow(context, 'Core Sleep', avgCore, total, _SC.core,
              Icons.favorite_rounded),
          const SizedBox(height: 12),
          _stageRow(context, 'REM Sleep', avgRem, total, _SC.rem,
              Icons.remove_red_eye_rounded),
          const SizedBox(height: 12),
          _stageRow(context, 'Light Sleep', avgLight, total, _SC.light,
              Icons.wb_twilight_rounded),
        ],
      ),
    );
  }

  Widget _stageRow(BuildContext context, String label, double hours,
      double total, Color color, IconData icon) {
    final pct = total > 0 ? (hours / total * 100) : 0.0;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: _SC.surfaceMuted(context),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${hours.toStringAsFixed(1)}h',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: _SC.textMuted(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ── Suggestions ──────────────────────────────────────────────────────────
  Widget _buildSuggestions(BuildContext context, SleepProvider sleep) {
    final suggestions = _generateSuggestions(sleep);
    return _AdaptiveCard(
      context: context,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _SC.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: _SC.mint, size: 20),
              ),
              const SizedBox(width: 12),
              Text('AI Suggestions',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: _SC.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s,
                      style: TextStyle(
                          color: _SC.textSec(context),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _generateSuggestions(SleepProvider sleep) {
    final suggestions = <String>[];
    final avg = sleep.averageSleepHours;
    final quality = sleep.averageQuality;

    if (avg < 6.5) {
      suggestions.add(
          'You\'re averaging ${avg.toStringAsFixed(1)}h of sleep. Try increasing to 7-8 hours for optimal recovery.');
    } else if (avg > 9) {
      suggestions.add(
          'You\'re sleeping over 9 hours. Oversleeping can affect energy levels—aim for 7-8 hours.');
    } else {
      suggestions.add(
          'Great job! Your average of ${avg.toStringAsFixed(1)}h is within the recommended range.');
    }

    if (quality < 60) {
      suggestions.add(
          'Consider a cool, dark room (18-20°C). Blue light filters before bed improve deep sleep quality.');
    }

    if (sleep.sleepStreak < 3) {
      suggestions.add(
          'Build a consistent routine. Try sleeping and waking at the same time every day to improve your streak.');
    } else {
      suggestions.add(
          'Your ${sleep.sleepStreak}-day streak shows great consistency! Keep it up for long-term benefits.');
    }

    suggestions.add(
        'Avoid caffeine 6 hours before bedtime and consider a wind-down routine with light stretching.');

    if (sleep.sleepHistory.isNotEmpty) {
      final last = sleep.sleepHistory.last;
      if (last.deepHours < last.totalHours * 0.15) {
        suggestions.add(
            'Your deep sleep is below optimal. Regular exercise and reducing alcohol intake can help increase deep sleep.');
      }
    }

    return suggestions;
  }

  // ── History List ─────────────────────────────────────────────────────────
  Widget _buildHistoryList(BuildContext context, SleepProvider sleep) {
    final sessions = sleep.sleepHistory.reversed.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Recent Sessions',
              style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ),
        ...sessions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AdaptiveCard(
            context: context,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getQualityColor(s.qualityScore)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${s.qualityScore}',
                      style: TextStyle(
                        color: _getQualityColor(s.qualityScore),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.date,
                          style: TextStyle(
                              color: _SC.textPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '${s.formattedBedtime} → ${s.formattedWakeTime}',
                        style: TextStyle(
                            color: _SC.textMuted(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.formattedTotal,
                        style: const TextStyle(
                            color: _SC.mint,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                    Text(s.qualityLabel,
                        style: TextStyle(
                            color: _getQualityColor(s.qualityScore),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Color _getQualityColor(int quality) {
    if (quality >= 85) return _SC.mint;
    if (quality >= 70) return _SC.core;
    if (quality >= 50) return _SC.light;
    return _SC.rem;
  }
}

// ── Adaptive Card helper widget ──────────────────────────────────────────────
class _AdaptiveCard extends StatelessWidget {
  final BuildContext context;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const _AdaptiveCard({
    required this.context,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext _) {
    final br = borderRadius ?? BorderRadius.circular(24);
    final isDark = _SC.isDark(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _SC.card(context),
        borderRadius: br,
        border: Border.all(color: _SC.border(context)),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════
//  Custom Painters
// ═══════════════════════════════════════════

class _SleepScoreRingPainter extends CustomPainter {
  final double score;
  final Color trackColor;

  _SleepScoreRingPainter({required this.score, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 10.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Score arc
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * score,
      colors: const [_SC.mintDark, _SC.mint],
      transform: const GradientRotation(-math.pi / 2),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * score.clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Glow tip
    if (score > 0.01) {
      final tipAngle = -math.pi / 2 + 2 * math.pi * score;
      final tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipCenter,
        6,
        Paint()
          ..color = _SC.mint.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(tipCenter, 4, Paint()..color = _SC.mint);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepScoreRingPainter old) =>
      old.score != score || old.trackColor != trackColor;
}

class _StageDonutPainter extends CustomPainter {
  final double deep, core, rem, light;
  final Color trackColor;

  _StageDonutPainter({
    required this.deep,
    required this.core,
    required this.rem,
    required this.light,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 20.0;
    const gap = 0.03;

    final total = deep + core + rem + light;
    if (total <= 0) {
      // Draw empty ring in light mode so it's still visible
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    final segments = [
      _DonutSegment(deep / total, _SC.deep),
      _DonutSegment(core / total, _SC.core),
      _DonutSegment(rem / total, _SC.rem),
      _DonutSegment(light / total, _SC.light),
    ];

    var startAngle = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (final seg in segments) {
      final sweep = seg.fraction * 2 * math.pi - gap;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          startAngle + gap / 2,
          sweep,
          false,
          Paint()
            ..color = seg.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
      startAngle += seg.fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _StageDonutPainter old) =>
      old.deep != deep ||
          old.core != core ||
          old.rem != rem ||
          old.light != light ||
          old.trackColor != trackColor;
}

class _DonutSegment {
  final double fraction;
  final Color color;
  _DonutSegment(this.fraction, this.color);
}