import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:monojog/models/sleep_models.dart';
import 'package:monojog/models/sleep_recording.dart';
import 'package:monojog/providers/sleep_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/widgets/neu_container.dart';
import 'package:monojog/screens/sleep_insights_screen.dart';

/// Adaptive color palette — works for both light and dark mode.
class _SC {
  // Brand / accent colors (same in both modes, vivid enough for both)
  static const mint = Color(0xFF00BFA5);
  static const mintDark = Color(0xFF00897B);
  static const purple = Color(0xFF7C4DFF);
  static const moonYellow = Color(0xFFF9A825);
  static const rem = Color(0xFFE53935);
  static const core = Color(0xFF00897B);
  static const deep = Color(0xFF512DA8);
  static const light = Color(0xFFF9A825);

  // ── Semantic tokens resolved at runtime ──────────────────────────────────
  static Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF0D0F1E)
          : const Color(0xFFF0F4F8);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1A1C3A)
          : const Color(0xFFFFFFFF);

  static Color cardAlt(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF252848)
          : const Color(0xFFE8EEF5);

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
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08);

  static Color surface(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04);

  static Color inputFill(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF0D0F1E)
          : const Color(0xFFF0F4F8);

  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
}

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});
  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _viewMode = 0; // 0=main, 1=analysis, 2=dreams
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingRecordingId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (ctx, sleep, _) {
        return Scaffold(
          backgroundColor: _SC.bg(context),
          body: SafeArea(
            child: sleep.isSleeping
                ? _buildSleepingView(sleep)
                : _buildIdleView(sleep),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IDLE VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIdleView(SleepProvider sleep) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(sleep),
          const SizedBox(height: 16),
          _buildViewToggle(),
          const SizedBox(height: 16),
          if (_viewMode == 0) ...[
            _buildSleepDebtCard(sleep),
            const SizedBox(height: 16),
            _buildMoonCard(sleep),
            const SizedBox(height: 16),
            _buildWindDownCard(sleep),
            const SizedBox(height: 16),
            _buildAmbientSoundsCard(sleep),
            const SizedBox(height: 16),
            _buildScheduleCard(sleep),
            const SizedBox(height: 16),
            _buildRecordingToggleCard(sleep),
            if (sleep.isCountdownActive) ...[
              const SizedBox(height: 16),
              _buildCountdownCard(sleep),
            ],
            const SizedBox(height: 16),
            _buildAiSuggestions(sleep),
            if (sleep.lastSession != null) ...[
              const SizedBox(height: 16),
              _buildLastSessionCard(sleep),
            ],
            const SizedBox(height: 16),
            _buildTargetSelector(sleep),
          ] else if (_viewMode == 1) ...[
            _buildAnalysisView(sleep),
          ] else ...[
            _buildDreamJournalView(sleep),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(SleepProvider sleep) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _SC.textSec(context),
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Sleep Tracker',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _SC.textPrimary(context),
                  letterSpacing: -0.5),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SleepInsightsScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _SC.card(context),
              boxShadow: _SC.isDark(context)
                  ? null
                  : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child:
            const Icon(Icons.insights_rounded, color: _SC.mint, size: 22),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Good Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIEW TOGGLE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViewToggle() {
    return Container(
      height: 44,
      decoration: null,
      child: Row(
        children: [
          _viewTab('Sleep', Icons.nightlight_round, 0),
          _viewTab('Analysis', Icons.analytics_rounded, 1),
          _viewTab('Dreams', Icons.auto_stories_rounded, 2),
        ],
      ),
    );
  }

  Widget _viewTab(String label, IconData icon, int idx) {
    final sel = _viewMode == idx;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _viewMode = idx),
        icon: Icon(icon,
            size: 16, color: sel ? _SC.mint : _SC.textSec(context)),
        label: Text(
          label,
          style: TextStyle(
            color: sel ? _SC.mint : _SC.textSec(context),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: sel ? _SC.mint : _SC.border(context), width: 1.5),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        )
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCHEDULE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScheduleCard(SleepProvider sleep) {
    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Schedule',
            style: TextStyle(
                color: _SC.textPrimary(context),
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your bedtime and wake-up alarm',
            style: TextStyle(
                color: _SC.textSec(context),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _timeSettingTile(
                  label: 'Bedtime',
                  icon: Icons.nightlight_round,
                  color: _SC.purple,
                  time: sleep.bedtimeGoal,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: sleep.bedtimeGoal ??
                          const TimeOfDay(hour: 23, minute: 0),
                      builder: (c, child) => Theme(
                        data: _timePickerTheme(c),
                        child: child!,
                      ),
                    );
                    if (picked != null) sleep.setBedtimeGoal(picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeSettingTile(
                  label: 'Wake Up',
                  icon: Icons.wb_sunny_rounded,
                  color: _SC.moonYellow,
                  time: sleep.wakeUpTime,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: sleep.wakeUpTime ??
                          const TimeOfDay(hour: 7, minute: 0),
                      builder: (c, child) => Theme(
                        data: _timePickerTheme(c),
                        child: child!,
                      ),
                    );
                    if (picked != null) sleep.setWakeUpTime(picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _switchRow(
            icon: Icons.alarm_rounded,
            label: 'Wake-up alarm',
            value: sleep.alarmEnabled,
            activeColor: _SC.mint,
            onChanged: (v) => sleep.setAlarmEnabled(v),
          ),
          const SizedBox(height: 10),
          _switchRow(
            icon: Icons.block_rounded,
            label: 'Block apps during sleep',
            value: sleep.sleepBlockEnabled,
            activeColor: _SC.rem,
            onChanged: (v) => sleep.setSleepBlockEnabled(v),
          ),
          if (sleep.sleepBlockEnabled) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: _switchRow(
                icon: Icons.shield_rounded,
                label: 'Block ALL apps (strict)',
                value: sleep.sleepBlockAll,
                activeColor: _SC.rem,
                onChanged: (v) => sleep.setSleepBlockAll(v),
                iconSize: 18,
                labelSize: 13,
              ),
            ),
            if (!sleep.sleepBlockAll)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 4),
                child: Text(
                  sleep.sleepBlockedPackages.isEmpty
                      ? 'No custom apps selected. Use Focus screen to manage blocked apps.'
                      : '${sleep.sleepBlockedPackages.length} app(s) will be blocked',
                  style:
                  TextStyle(color: _SC.textSec(context), fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }

  ThemeData _timePickerTheme(BuildContext c) {
    return _SC.isDark(c)
        ? ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
            primary: _SC.mint, surface: Color(0xFF1A1C3A)))
        : ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
            primary: _SC.mint, surface: Colors.white));
  }

  Widget _switchRow({
    required IconData icon,
    required String label,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    double iconSize = 20,
    double labelSize = 14,
  }) {
    return Row(
      children: [
        Icon(icon,
            color: value ? activeColor : _SC.textSec(context), size: iconSize),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: value ? _SC.textPrimary(context) : _SC.textSec(context),
            fontWeight: FontWeight.w700,
            fontSize: labelSize,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeColor.withValues(alpha: 0.4),
          activeThumbColor: activeColor,
        ),
      ],
    );
  }

  Widget _timeSettingTile({
    required String label,
    required IconData icon,
    required Color color,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: _SC.isDark(context) ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(
                  alpha: _SC.isDark(context) ? 0.2 : 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              time != null ? time.format(context) : 'Set',
              style: TextStyle(
                color: time != null ? _SC.textPrimary(context) : _SC.textSec(context),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COUNTDOWN CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCountdownCard(SleepProvider sleep) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SC.isDark(context)
            ? _SC.purple.withValues(alpha: 0.2)
            : _SC.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _SC.purple.withValues(
                alpha: _SC.isDark(context) ? 0.2 : 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded,
              color: _SC.purple, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time until bedtime',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                sleep.formattedCountdown,
                style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOON CARD (Start Sleep)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMoonCard(SleepProvider sleep) {
    return GestureDetector(
      onTap: () {
        final conflict = sleep.startSleep();
        if (conflict != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(conflict), backgroundColor: _SC.rem),
          );
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (ctx, child) {
          final scale = 1.0 + (_pulseController.value * 0.015);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: _SC.isDark(context)
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1C3A), Color(0xFF0D0F1E)],
            )
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _SC.mint.withValues(alpha: 0.12),
                _SC.mint.withValues(alpha: 0.04),
              ],
            ),
            border: _SC.isDark(context)
                ? null
                : Border.all(
                color: _SC.mint.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _SC.mint.withValues(
                      alpha: _SC.isDark(context) ? 0.1 : 0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_SC.mint, _SC.mintDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _SC.mint.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.nightlight_round,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Sleep',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _SC.textPrimary(context))),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${sleep.targetHours}h • Tap to begin',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _SC.textSec(context)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _SC.mint, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAiSuggestions(SleepProvider sleep) {
    final suggestions = sleep.aiSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: _SC.mint, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sleep Insights',
              style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionCard(s)),
      ],
    );
  }

  Widget _buildSuggestionCard(SleepSuggestion suggestion) {
    Color accentColor;
    switch (suggestion.type) {
      case SuggestionType.warning:
        accentColor = _SC.rem;
        break;
      case SuggestionType.bedtime:
        accentColor = _SC.purple;
        break;
      case SuggestionType.wakeup:
        accentColor = _SC.moonYellow;
        break;
      case SuggestionType.quality:
        accentColor = _SC.core;
        break;
      case SuggestionType.habit:
        accentColor = _SC.mint;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(
            alpha: _SC.isDark(context) ? 0.06 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: accentColor.withValues(
                alpha: _SC.isDark(context) ? 0.15 : 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: TextStyle(
                      color: _SC.textSec(context), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAST SESSION CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLastSessionCard(SleepProvider sleep) {
    final session = sleep.lastSession!;
    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _SC.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bedtime_rounded,
                    color: _SC.mint, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Sleep',
                      style: TextStyle(
                          color: _SC.textPrimary(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(session.date,
                      style: TextStyle(
                          color: _SC.textSec(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              _buildQualityBadge(session.qualityScore),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSleepStat('Total', session.formattedTotal, _SC.mint),
              _buildSleepStat('Bedtime', session.formattedBedtime, _SC.purple),
              _buildSleepStat(
                  'Wake', session.formattedWakeTime, _SC.moonYellow),
            ],
          ),
          const SizedBox(height: 16),
          _buildSleepStagesBar(session),
          const SizedBox(height: 12),
          _buildSleepStagesLegend(session),
        ],
      ),
    );
  }

  Widget _buildQualityBadge(int quality) {
    Color badgeColor;
    if (quality >= 85) {
      badgeColor = _SC.mint;
    } else if (quality >= 70) {
      badgeColor = _SC.core;
    } else if (quality >= 50) {
      badgeColor = _SC.moonYellow;
    } else {
      badgeColor = _SC.rem;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: badgeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text('$quality%',
          style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              fontSize: 16)),
    );
  }

  Widget _buildSleepStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSleepStagesBar(SleepSession session) {
    final total = session.totalHours;
    if (total <= 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            _stageSegment(session.deepHours / total, _SC.deep),
            _stageSegment(session.coreHours / total, _SC.core),
            _stageSegment(session.remHours / total, _SC.rem),
            _stageSegment(session.lightHours / total, _SC.moonYellow),
          ],
        ),
      ),
    );
  }

  Widget _stageSegment(double fraction, Color color) {
    return Expanded(
        flex: (fraction * 100).round().clamp(1, 100),
        child: Container(color: color));
  }

  Widget _buildSleepStagesLegend(SleepSession session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(
            'Deep', '${session.deepHours.toStringAsFixed(1)}h', _SC.deep),
        _legendItem(
            'Core', '${session.coreHours.toStringAsFixed(1)}h', _SC.core),
        _legendItem('REM', '${session.remHours.toStringAsFixed(1)}h', _SC.rem),
        _legendItem('Light', '${session.lightHours.toStringAsFixed(1)}h',
            _SC.moonYellow),
      ],
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: _SC.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            Text(label,
                style: TextStyle(
                    color: _SC.textSec(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TARGET SELECTOR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTargetSelector(SleepProvider sleep) {
    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep Target',
              style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text('Set your ideal sleep duration',
              style:
              TextStyle(color: _SC.textSec(context), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(9, (i) {
              final hours = i + 4;
              final isSelected = sleep.targetHours == hours;
              return Expanded(
                child: GestureDetector(
                  onTap: () => sleep.setTargetHours(hours),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _SC.mint.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _SC.mint
                            : _SC.border(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$hours',
                        style: TextStyle(
                          color: isSelected
                              ? _SC.mint
                              : _SC.textSec(context),
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECORDING TOGGLE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRecordingToggleCard(SleepProvider sleep) {
    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _SC.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mic_rounded,
                    color: _SC.purple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Recorder',
                      style: TextStyle(
                          color: _SC.textPrimary(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    Text(
                      'Record sounds while you sleep',
                      style: TextStyle(
                          color: _SC.textSec(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Switch(
                value: sleep.recordingEnabled,
                onChanged: (v) => sleep.setRecordingEnabled(v),
                activeTrackColor: _SC.purple.withValues(alpha: 0.4),
                activeThumbColor: _SC.purple,
              ),
            ],
          ),
          if (sleep.recordingEnabled) ...[
            const SizedBox(height: 16),
            Text(
              'Sensitivity',
              style: TextStyle(
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('🤫', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: sleep.silenceThreshold,
                    min: 20,
                    max: 60,
                    divisions: 8,
                    activeColor: _SC.purple,
                    inactiveColor:
                    _SC.isDark(context) ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1),
                    onChanged: (v) => sleep.setSilenceThreshold(v),
                  ),
                ),
                const Text('🔊', style: TextStyle(fontSize: 16)),
              ],
            ),
            Center(
              child: Text(
                '${sleep.silenceThreshold.round()} dB threshold',
                style: TextStyle(
                    color: _SC.textSec(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _SC.purple.withValues(
                    alpha: _SC.isDark(context) ? 0.06 : 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _SC.purple.withValues(
                        alpha: _SC.isDark(context) ? 0.1 : 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _SC.purple, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detects snoring, talking, and noise during sleep. Recordings stored locally on device.',
                      style: TextStyle(
                        color: _SC.textSec(context),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SLEEP DEBT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSleepDebtCard(SleepProvider sleep) {
    final debt = sleep.sleepDebt;
    final consistency = sleep.consistencyScore;
    final debtColor =
    debt <= 2.0 ? _SC.mint : (debt <= 5.0 ? _SC.moonYellow : _SC.rem);
    final consistColor =
    consistency >= 80 ? _SC.mint : (consistency >= 50 ? _SC.core : _SC.rem);

    return Row(
      children: [
        Expanded(
          child: _adaptiveCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Icon(Icons.balance_rounded, color: debtColor, size: 24),
                const SizedBox(height: 8),
                Text(
                  '${debt}h',
                  style: TextStyle(
                      color: debtColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sleep Debt',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  debt <= 2
                      ? 'Well rested!'
                      : (debt <= 5 ? 'Catch up soon' : 'Needs attention'),
                  style: TextStyle(
                      color: debtColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _adaptiveCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Icon(Icons.timeline_rounded, color: consistColor, size: 24),
                const SizedBox(height: 8),
                Text(
                  '$consistency%',
                  style: TextStyle(
                      color: consistColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistency',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  consistency >= 80
                      ? 'Very steady!'
                      : (consistency >= 50 ? 'Room to improve' : 'Irregular'),
                  style: TextStyle(
                      color: consistColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIND-DOWN CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWindDownCard(SleepProvider sleep) {
    if (sleep.windDownActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _SC.isDark(context)
              ? _SC.purple.withValues(alpha: 0.18)
              : _SC.purple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: _SC.purple.withValues(
                  alpha: _SC.isDark(context) ? 0.4 : 0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.self_improvement_rounded,
                    color: _SC.purple, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wind-Down Active',
                          style: TextStyle(
                              color: _SC.textPrimary(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Relax... sleep starts when timer ends',
                          style: TextStyle(
                              color: _SC.textSec(context), fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => sleep.stopWindDown(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _SC.rem.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Stop',
                        style: TextStyle(
                            color: _SC.rem,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sleep.windDownFormatted,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                color: _SC.purple,
                letterSpacing: 4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 1 -
                    (sleep.windDownSecondsLeft / (sleep.windDownMinutes * 60))
                        .clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor:
                _SC.isDark(context) ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(_SC.purple),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WindDownTip('📵', 'Put phone away', context),
                _WindDownTip('🧘', 'Stretch or meditate', context),
                _WindDownTip('📖', 'Read a book', context),
                _WindDownTip('🫖', 'Herbal tea', context),
              ],
            ),
          ],
        ),
      );
    }

    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _SC.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.self_improvement_rounded,
                    color: _SC.purple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wind-Down Routine',
                        style: TextStyle(
                            color: _SC.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('Prepare your mind for sleep',
                        style: TextStyle(
                            color: _SC.textSec(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Duration: ',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              ...([15, 30, 45, 60].map((m) {
                final sel = sleep.windDownMinutes == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => sleep.setWindDownMinutes(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? _SC.purple.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel
                                ? _SC.purple
                                : _SC.border(context)),
                      ),
                      child: Text(
                        '${m}m',
                        style: TextStyle(
                            color: sel ? _SC.purple : _SC.textSec(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ),
                );
              })),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => sleep.startWindDown(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_SC.purple, Color(0xFF5C35CC)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('Start Wind-Down',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AMBIENT SOUNDS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAmbientSoundsCard(SleepProvider sleep) {
    final sounds = SleepProvider.ambientSounds;

    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _SC.core.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: _SC.core, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sleep Sounds',
                        style: TextStyle(
                            color: _SC.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('Ambient noise for better sleep',
                        style: TextStyle(
                            color: _SC.textSec(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (sleep.isAmbientPlaying)
                GestureDetector(
                  onTap: () => sleep.stopAmbientSound(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _SC.rem.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Stop',
                        style: TextStyle(
                            color: _SC.rem,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: sounds.length,
            itemBuilder: (ctx, i) {
              final s = sounds[i];
              final isActive = sleep.activeAmbientSound == s.id;
              return GestureDetector(
                onTap: () => sleep.setAmbientSound(isActive ? null : s.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? s.color.withValues(alpha: 0.15)
                        : _SC.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? s.color : _SC.border(context),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        s.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? s.color : _SC.textSec(context),
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (sleep.isAmbientPlaying) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.volume_down_rounded,
                    color: _SC.textSec(context), size: 18),
                Expanded(
                  child: Slider(
                    value: sleep.ambientVolume,
                    onChanged: (v) => sleep.setAmbientVolume(v),
                    activeColor: _SC.core,
                    inactiveColor: _SC.isDark(context)
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                Icon(Icons.volume_up_rounded,
                    color: _SC.textSec(context), size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Auto-stop: ',
                    style: TextStyle(
                        color: _SC.textSec(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                ...([0, 15, 30, 60].map((m) {
                  final sel = sleep.ambientTimerMinutes == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => sleep.setAmbientTimer(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? _SC.core.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                              sel ? _SC.core : _SC.border(context)),
                        ),
                        child: Text(
                          m == 0 ? 'Off' : '${m}m',
                          style: TextStyle(
                              color: sel ? _SC.core : _SC.textSec(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        ),
                      ),
                    ),
                  );
                })),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DREAM JOURNAL VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDreamJournalView(SleepProvider sleep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dream Journal',
                style: TextStyle(
                    color: _SC.textPrimary(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 20),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddDreamDialog(sleep),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_SC.purple, Color(0xFF5C35CC)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text('Log Dream',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Record your dreams to improve recall and discover patterns.',
          style: TextStyle(
              color: _SC.textSec(context), fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (sleep.dreamJournal.isNotEmpty)
          Row(
            children: [
              _dreamStat('Total', '${sleep.dreamJournal.length}', _SC.purple),
              const SizedBox(width: 10),
              _dreamStat(
                  'Lucid',
                  '${sleep.dreamJournal.where((d) => d.lucid).length}',
                  _SC.mint),
              const SizedBox(width: 10),
              _dreamStat(
                  'This Week',
                  '${sleep.dreamJournal.where((d) {
                    final days =
                        DateTime.now().difference(d.createdAt).inDays;
                    return days < 7;
                  }).length}',
                  _SC.core),
            ],
          ),
        if (sleep.dreamJournal.isNotEmpty) const SizedBox(height: 16),
        if (sleep.dreamJournal.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text('💭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('No dreams logged yet',
                    style: TextStyle(
                        color: _SC.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    'Tap "Log Dream" right after waking up\nfor the best recall.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _SC.textSec(context),
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ] else
          ...sleep.dreamJournal.map((dream) => _buildDreamCard(dream, sleep)),
      ],
    );
  }

  Widget _dreamStat(String label, String value, Color color) {
    return Expanded(
      child: _adaptiveCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: _SC.textSec(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDreamCard(DreamEntry dream, SleepProvider sleep) {
    return Dismissible(
      key: Key(dream.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _SC.rem.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: _SC.rem, size: 22),
      ),
      onDismissed: (_) => sleep.deleteDream(dream.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _SC.card(context),
          borderRadius: BorderRadius.circular(18),
          border: dream.lucid
              ? Border.all(color: _SC.mint.withValues(alpha: 0.4))
              : Border.all(color: _SC.border(context)),
          boxShadow: _SC.isDark(context)
              ? null
              : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(dream.mood, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dream.title,
                        style: TextStyle(
                            color: _SC.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      Text(
                        dream.date,
                        style: TextStyle(
                            color: _SC.textSec(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (dream.lucid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _SC.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Lucid',
                        style: TextStyle(
                            color: _SC.mint,
                            fontWeight: FontWeight.w800,
                            fontSize: 10)),
                  ),
              ],
            ),
            if (dream.description != null &&
                dream.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dream.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _SC.textSec(context), fontSize: 13, height: 1.4),
              ),
            ],
            if (dream.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dream.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _SC.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('#$tag',
                        style: const TextStyle(
                            color: _SC.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddDreamDialog(SleepProvider sleep) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    String selectedMood = '😴';
    bool isLucid = false;

    final moods = ['😴', '😊', '😨', '🤔', '😢', '🥳', '😰', '🌈'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _SC.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _SC.textSec(context).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Log Your Dream',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              const SizedBox(height: 16),
              Text('How did it feel?',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: moods.map((m) {
                  final sel = selectedMood == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedMood = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _SC.purple.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: sel
                              ? Border.all(color: _SC.purple)
                              : null,
                        ),
                        child: Center(
                            child: Text(m,
                                style: TextStyle(
                                    fontSize: sel ? 24 : 20))),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _inputField(titleCtrl, 'Dream title...'),
              const SizedBox(height: 10),
              _inputField(descCtrl, 'Describe your dream...', maxLines: 3),
              const SizedBox(height: 10),
              _inputField(tagsCtrl, 'Tags (comma-separated)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: isLucid ? _SC.mint : _SC.textSec(context),
                      size: 20),
                  const SizedBox(width: 10),
                  Text('Lucid Dream',
                      style: TextStyle(
                          color: isLucid
                              ? _SC.textPrimary(context)
                              : _SC.textSec(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: isLucid,
                    onChanged: (v) => setSheetState(() => isLucid = v),
                    activeTrackColor: _SC.mint.withValues(alpha: 0.4),
                    activeThumbColor: _SC.mint,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final tags = tagsCtrl.text.trim().isEmpty
                      ? <String>[]
                      : tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  sleep.addDream(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    mood: selectedMood,
                    tags: tags,
                    lucid: isLucid,
                  );
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_SC.purple, Color(0xFF5C35CC)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Save Dream',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: _SC.textPrimary(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _SC.textSec(context)),
        filled: true,
        fillColor: _SC.inputFill(context),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANALYSIS VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnalysisView(SleepProvider sleep) {
    final weekData = sleep.weeklyData;
    final maxH =
    weekData.fold<double>(0, (a, b) => a > b.hours ? a : b.hours);
    final chartMax = maxH < 1 ? 10.0 : maxH + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _analyticsTile(
                    Icons.nights_stay_rounded,
                    'Avg Sleep',
                    '${sleep.averageSleepHours.toStringAsFixed(1)}h',
                    _SC.mint)),
            const SizedBox(width: 10),
            Expanded(
                child: _analyticsTile(Icons.speed_rounded, 'Avg Quality',
                    '${sleep.averageQuality}%', _SC.core)),
            const SizedBox(width: 10),
            Expanded(
                child: _analyticsTile(Icons.local_fire_department_rounded,
                    'Streak', '${sleep.sleepStreak}', _SC.rem)),
          ],
        ),
        const SizedBox(height: 20),
        _adaptiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('This Week',
                      style: TextStyle(
                          color: _SC.textPrimary(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _SC.mint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        'Avg ${sleep.averageSleepHours.toStringAsFixed(1)}h',
                        style: const TextStyle(
                            color: _SC.mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weekData.map((d) {
                    final barH = chartMax > 0
                        ? (d.hours / chartMax) * 130
                        : 0.0;
                    final isToday = d == weekData.last;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (d.hours > 0)
                              Text(d.hours.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: isToday
                                          ? _SC.mint
                                          : _SC.textSec(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              height: barH.clamp(4.0, 130.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isToday
                                      ? [_SC.mint, _SC.mintDark]
                                      : _SC.isDark(context)
                                      ? [
                                    const Color(0xFF2A2D40),
                                    const Color(0xFF3A3D50)
                                  ]
                                      : [
                                    const Color(0xFFD0DAE8),
                                    const Color(0xFFBCC8D8)
                                  ],
                                ),
                                boxShadow: isToday
                                    ? [
                                  BoxShadow(
                                      color: _SC.mint
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1)
                                ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(d.dayLabel,
                                style: TextStyle(
                                    color: isToday
                                        ? _SC.mint
                                        : _SC.textSec(context),
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _adaptiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quality Trend',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weekData.map((d) {
                    final barH =
                    d.quality > 0 ? (d.quality / 100.0) * 70.0 : 4.0;
                    Color barColor;
                    if (d.quality >= 80) {
                      barColor = _SC.mint;
                    } else if (d.quality >= 60) {
                      barColor = _SC.core;
                    } else if (d.quality > 0) {
                      barColor = _SC.rem;
                    } else {
                      barColor = _SC.isDark(context)
                          ? const Color(0xFF2A2D40)
                          : const Color(0xFFD0DAE8);
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (d.quality > 0)
                              Text('${d.quality}',
                                  style: TextStyle(
                                      color: barColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10)),
                            const SizedBox(height: 4),
                            Container(
                              height: barH,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _adaptiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep Pattern',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _patternStat('Avg Bedtime',
                      _formatHour(sleep.averageBedtimeHour), _SC.purple),
                  _patternStat('Avg Wake',
                      _formatHour(sleep.averageWakeHour), _SC.moonYellow),
                  _patternStat('Sessions',
                      '${sleep.sleepHistory.length}', _SC.mint),
                ],
              ),
            ],
          ),
        ),
        if (sleep.sleepHistory.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (sleep.noiseTimeline.isNotEmpty) ...[
            _buildNightNoiseCard(sleep),
            const SizedBox(height: 20),
          ],
          if (sleep.recordings.isNotEmpty) ...[
            _buildNightSoundsSection(sleep),
            const SizedBox(height: 20),
          ],
          Text('Recent History',
              style: TextStyle(
                  color: _SC.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 12),
          ...sleep.sleepHistory.take(5).map((s) => _historyTile(s, sleep)),
        ],
      ],
    );
  }

  Widget _analyticsTile(
      IconData icon, String label, String value, Color color) {
    return _adaptiveCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _patternStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }

  String _formatHour(double h) {
    final hour = h.floor() % 24;
    final min = ((h - h.floor()) * 60).round();
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$display:${min.toString().padLeft(2, '0')} $period';
  }

  Widget _buildNightNoiseCard(SleepProvider sleep) {
    final summary = sleep.noiseSummary;
    if (summary == null) return const SizedBox.shrink();
    final timeline = sleep.noiseTimeline;
    final maxDb =
    timeline.fold<double>(0, (m, v) => v > m ? v : m).clamp(30.0, 100.0);

    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, color: _SC.mint, size: 20),
              const SizedBox(width: 8),
              Text('Night Noise Level',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _SC.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${summary.totalRecordings} events',
                    style: const TextStyle(
                        color: _SC.mint,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _noiseStat('Avg. Noise',
                  '${summary.avgDecibels.toStringAsFixed(0)} dB', _SC.mint),
              _noiseStat(
                  'Max. Noise',
                  '${summary.maxDecibels.toStringAsFixed(0)} dB',
                  Colors.redAccent),
              _noiseStat('Events', '${summary.totalRecordings}', _SC.core),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                timeline.length > 60 ? 60 : timeline.length,
                    (i) {
                  final idx = timeline.length > 60
                      ? (i * timeline.length ~/ 60)
                      : i;
                  final db = timeline[idx];
                  final h = (db / maxDb * 70).clamp(3.0, 70.0);
                  Color barColor;
                  if (db > 60) {
                    barColor = Colors.redAccent;
                  } else if (db > 40) {
                    barColor = Colors.orangeAccent;
                  } else {
                    barColor = _SC.mint;
                  }
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      height: h,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (summary.healthNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _SC.mint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _SC.mint, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.healthNote,
                      style: TextStyle(
                          color: _SC.textSec(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noiseStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNightSoundsSection(SleepProvider sleep) {
    return _adaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: _SC.purple, size: 20),
              const SizedBox(width: 8),
              Text('Night Sounds',
                  style: TextStyle(
                      color: _SC.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const Spacer(),
              Text('${sleep.recordings.length} recordings',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          ...sleep.recordings
              .map((rec) => _buildRecordingCard(rec, sleep)),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(SleepRecording rec, SleepProvider sleep) {
    final isPlaying = _playingRecordingId == rec.id;
    final time = TimeOfDay.fromDateTime(rec.timestamp);
    final timeStr = time.format(context);
    const waveCount = 30;
    final seed = rec.id.hashCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SC.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPlaying
                ? _SC.mint.withValues(alpha: 0.4)
                : _SC.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _labelColor(rec.label).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(rec.emoji ?? '🔊',
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.label,
                        style: TextStyle(
                            color: _labelColor(rec.label),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '$timeStr • ${rec.durationSeconds}s • ${rec.peakDecibels.toStringAsFixed(0)} dB',
                      style: TextStyle(
                          color: _SC.textSec(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _togglePlayRecording(rec),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying
                        ? _SC.mint
                        : _SC.isDark(context)
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: isPlaying
                        ? Colors.white
                        : _SC.textPrimary(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(waveCount, (i) {
                final h = 6.0 +
                    ((seed * (i + 1) * 7) % 22).toDouble() *
                        (rec.peakDecibels / 80.0);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: h.clamp(4.0, 28.0),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? _SC.mint.withValues(
                          alpha: 0.6 + (i % 3) * 0.1)
                          : _SC.isDark(context)
                          ? Colors.white.withValues(
                          alpha: 0.12 + (i % 3) * 0.04)
                          : Colors.black.withValues(
                          alpha: 0.1 + (i % 3) * 0.04),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _labelColor(String label) {
    switch (label) {
      case 'You Snored':
        return Colors.orangeAccent;
      case 'You Talked':
        return _SC.purple;
      case 'You Farted':
        return _SC.rem;
      case 'Noise Detected':
        return _SC.core;
      default:
        return _SC.mint;
    }
  }

  Future<void> _togglePlayRecording(SleepRecording rec) async {
    if (_playingRecordingId == rec.id) {
      await _audioPlayer.stop();
      setState(() => _playingRecordingId = null);
    } else {
      try {
        final file = File(rec.filePath);
        if (await file.exists()) {
          await _audioPlayer.stop();
          await _audioPlayer.play(DeviceFileSource(rec.filePath));
          setState(() => _playingRecordingId = rec.id);
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) setState(() => _playingRecordingId = null);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _playingRecordingId = null);
      }
    }
  }

  Widget _historyTile(SleepSession s, SleepProvider sleep) {
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _SC.rem.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: _SC.rem, size: 22),
      ),
      onDismissed: (_) => sleep.deleteSession(s.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _SC.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SC.border(context)),
          boxShadow: _SC.isDark(context)
              ? null
              : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.date,
                    style: TextStyle(
                        color: _SC.textPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text('${s.formattedBedtime} - ${s.formattedWakeTime}',
                    style: TextStyle(
                        color: _SC.textSec(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            Text(s.formattedTotal,
                style: const TextStyle(
                    color: _SC.mint,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(width: 12),
            _buildQualityBadge(s.qualityScore),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SLEEPING VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSleepingView(SleepProvider sleep) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _SC.isDark(context)
              ? [
            const Color(0xFF0D0F1E),
            const Color(0xFF1A1C3A),
            const Color(0xFF0D0F1E)
          ]
              : [
            const Color(0xFFEDF2F7),
            const Color(0xFFF7FAFC),
            const Color(0xFFEDF2F7)
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildSleepingMoon(),
            const SizedBox(height: 32),
            Text(
              sleep.formattedElapsed,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w200,
                color: _SC.textPrimary(context),
                letterSpacing: 4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sleeping since ${sleep.bedtime != null ? _formatTime(sleep.bedtime!) : ''}',
              style: TextStyle(
                  fontSize: 14,
                  color: _SC.textSec(context),
                  fontWeight: FontWeight.w500),
            ),
            if (sleep.wakeUpTime != null && sleep.alarmEnabled) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_rounded,
                      color: _SC.moonYellow, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Alarm at ${sleep.wakeUpTime!.format(context)}',
                    style: const TextStyle(
                        color: _SC.moonYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            if (sleep.recordingEnabled) _buildRecordingIndicator(sleep),
            if (sleep.noiseTimeline.isNotEmpty) _buildLiveNoiseChart(sleep),
            const SizedBox(height: 24),
            _buildSleepingStages(sleep),
            const SizedBox(height: 40),
            _buildWakeUpButton(sleep),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(SleepProvider sleep) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final pulse = _pulseController.value;
        final color =
        sleep.isRecording ? Colors.redAccent : _SC.mint;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1 + pulse * 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.mic_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sleep.isRecording
                      ? 'Recording sound…'
                      : 'Listening for sounds…',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _SC.surface(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sleep.recordings.length} sounds',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveNoiseChart(SleepProvider sleep) {
    final timeline = sleep.noiseTimeline;
    final visible = timeline.length > 30
        ? timeline.sublist(timeline.length - 30)
        : timeline;
    final maxDb = visible
        .fold<double>(0, (m, v) => v > m ? v : m)
        .clamp(30.0, 100.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _SC.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SC.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  color: _SC.mint, size: 16),
              const SizedBox(width: 8),
              Text(
                'Night Noise Level',
                style: TextStyle(
                    color: _SC.textSec(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${sleep.noiseSummary?.avgDecibels.toStringAsFixed(0) ?? '0'} dB avg',
                style: const TextStyle(
                    color: _SC.mint,
                    fontWeight: FontWeight.w600,
                    fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(visible.length, (i) {
                final db = visible[i];
                final h = (db / maxDb * 50).clamp(3.0, 50.0);
                Color barColor;
                if (db > 60) {
                  barColor = Colors.redAccent;
                } else if (db > 40) {
                  barColor = Colors.orangeAccent;
                } else {
                  barColor = _SC.mint;
                }
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: h,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepingMoon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _SC.mint.withValues(
                    alpha: 0.15 + _pulseController.value * 0.1),
                _SC.mint.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _SC.mint.withValues(alpha: 0.2),
                  _SC.mint.withValues(alpha: 0.05)
                ]),
                boxShadow: [
                  BoxShadow(
                    color: _SC.mint.withValues(
                        alpha: 0.2 + _pulseController.value * 0.15),
                    blurRadius: 30 + _pulseController.value * 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.nightlight_round,
                  color: _SC.mint, size: 48),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepingStages(SleepProvider sleep) {
    final hours = sleep.elapsedHours;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sleep Progress',
                  style: TextStyle(
                      color: _SC.textSec(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(
                  '${hours.toStringAsFixed(1)}h / ${sleep.targetHours}h',
                  style: const TextStyle(
                      color: _SC.mint,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (hours / sleep.targetHours).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _SC.isDark(context)
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor:
              const AlwaysStoppedAnimation<Color>(_SC.mint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWakeUpButton(SleepProvider sleep) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _SC.card(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Text('Wake Up?',
                style: TextStyle(
                    color: _SC.textPrimary(context),
                    fontWeight: FontWeight.w800)),
            content: Text('End your sleep session and save the data.',
                style: TextStyle(color: _SC.textSec(context))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Sleeping',
                    style: TextStyle(color: _SC.mint)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SC.mint,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Wake Up',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (confirm == true) await sleep.stopSleep();
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              colors: [_SC.mint, _SC.mintDark]),
          boxShadow: [
            BoxShadow(
                color: _SC.mint.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Wake Up',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Adaptive card (white with shadow in light, dark card in dark)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _adaptiveCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(24);
    final isDark = _SC.isDark(context);
    return Container(
      width: double.infinity,
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
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wind Down Tip Widget (adaptive)
// ─────────────────────────────────────────────────────────────────────────────
class _WindDownTip extends StatelessWidget {
  final String emoji;
  final String label;
  final BuildContext parentCtx;
  const _WindDownTip(this.emoji, this.label, this.parentCtx);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(parentCtx).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8B8FA3)
                      : const Color(0xFF5A6070),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}