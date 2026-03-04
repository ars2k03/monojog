import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/screens/blocked_apps_screen.dart';
import 'package:monojog/widgets/breathing_exercise.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedMinutes = 25;
  final List<int> _presets = [15, 25, 45, 60, 90, 120];

  static const List<String> _quotes = [
    'Your focus is your power.',
    'Every minute takes you forward.',
    'Believe in yourself — you can do it!',
    'Stay focused, success will come.',
    'Deep work creates great outcomes.',
    'Your discipline today builds tomorrow.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focus = context.read<FocusProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      focus.onAppLifecycleChanged(false);
    } else if (state == AppLifecycleState.resumed) {
      focus.onAppLifecycleChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FocusProvider, GameProvider>(
      builder: (ctx, focus, game, _) {
        if (focus.isOnBreak) return _buildBreakScreen(focus);
        if (focus.isFocusActive) return _buildActiveFocus(focus, game);
        return _buildSetupFocus(focus);
      },
    );
  }

  // ===========================================
  //  SETUP SCREEN
  // ===========================================
  Widget _buildSetupFocus(FocusProvider focus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive colors ───────────────────────────────────────────────────
    // BUG FIX: Light mode bg was too similar to card bg — now clearly distinct
    final bgColor = isDark
        ? AppTheme.darkBg
        : const Color(0xFFEEEDF7); // slightly deeper purple-tinted bg

    // BUG FIX: Light mode primary text was not dark enough
    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF0F0F1A); // near-black for max contrast

    // BUG FIX: Light mode secondary text was too light (grey.shade600 = #757575)
    final textSec = isDark
        ? AppTheme.darkTextSec
        : const Color(0xFF4A4A6A); // darker purple-grey for readability

    // BUG FIX: Light mode card bg needs to stand out from page bg
    final cardBg = isDark
        ? AppTheme.darkSurface
        : Colors.white; // pure white cards on tinted bg = clear separation

    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFD8D6EE); // more visible border in light mode

    // BUG FIX: Timer circle bg — light mode was too washed out
    final timerBg1 = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white;
    final timerBg2 = isDark
        ? const Color(0xFF16161F)
        : const Color(0xFFEFEEFB); // subtle purple tint

    // BUG FIX: Preset unselected state — light mode was invisible
    final presetUnselBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF3F2FC); // tinted chip bg
    final presetUnselBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFCECCE8); // clearly visible border

    return Container(
      color: bgColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Mode',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose intensity & start deep work',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            // BUG FIX: Use textSec (not a static color) for proper contrast
                            color: textSec,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (focus.pomodoroCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF9F43)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('${focus.pomodoroCount}',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  // BUG FIX: Black text on gold gradient — stays same (good contrast)
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Timer Display ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [timerBg1, timerBg2],
                    ),
                    border: Border.all(
                      // BUG FIX: Increased border opacity for light mode visibility
                        color: focus.focusLevel.color
                            .withValues(alpha: isDark ? 0.2 : 0.35),
                        width: isDark ? 2 : 2.5),
                    boxShadow: isDark
                        ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10)),
                      BoxShadow(
                          color: focus.focusLevel.color
                              .withValues(alpha: 0.08),
                          blurRadius: 40,
                          spreadRadius: 5),
                    ]
                        : [
                      // BUG FIX: More visible shadow in light mode
                      BoxShadow(
                          color: focus.focusLevel.color
                              .withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 8)),
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_selectedMinutes',
                          style: GoogleFonts.inter(
                              fontSize: 52,
                              fontWeight: FontWeight.w200,
                              // BUG FIX: textPrimary ensures dark text in light mode
                              color: textPrimary)),
                      Text('minutes',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textSec,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Time Presets ──────────────────────────────────────────
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ..._presets.map((mins) {
                      final isSelected = _selectedMinutes == mins;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMinutes = mins),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(colors: [
                              focus.focusLevel.color,
                              focus.focusLevel.color
                                  .withValues(alpha: 0.75)
                            ])
                                : null,
                            color: isSelected ? null : presetUnselBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : presetUnselBorder,
                                // BUG FIX: Slightly thicker border for light unselected
                                width: isSelected ? 0 : (isDark ? 1 : 1.2)),
                          ),
                          child: Text('$mins',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                // BUG FIX: textSec instead of light grey for proper contrast
                                    : textSec,
                              )),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _showCustomDurationDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          // BUG FIX: Light mode custom button bg was nearly invisible
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : AppTheme.gemColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.gemColor
                                  .withValues(alpha: isDark ? 0.25 : 0.40),
                              width: isDark ? 1 : 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded,
                                size: 14,
                                color: AppTheme.gemColor
                                    .withValues(alpha: isDark ? 0.8 : 1.0)),
                            const SizedBox(width: 6),
                            Text('Custom',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.gemColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Focus Level Selector ──────────────────────────────────
              Text('Focus Intensity',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Text('Higher levels = more restrictions',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSec,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),

              ...FocusLevel.values.map((level) => _buildLevelCard(
                  focus, level, isDark, textPrimary, textSec, cardBg, cardBorder)),

              // ── Manage Blocked Apps ───────────────────────────────────
              if (focus.focusLevel == FocusLevel.moderate) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BlockedAppsScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: isDark
                          ? []
                          : [
                        BoxShadow(
                          // BUG FIX: More visible shadow in light mode
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            // BUG FIX: Slightly more opaque icon bg in light mode
                            color: AppTheme.errorColor
                                .withValues(alpha: isDark ? 0.10 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apps_rounded,
                              color: AppTheme.errorColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manage Blocked Apps',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary)),
                              Text(
                                  '${focus.blockedApps.where((a) => a.isBlocked).length} apps + all social media',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textSec)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            // BUG FIX: chevron was using textSec (too light in dark), use explicit
                            color: isDark
                                ? AppTheme.darkTextSec
                                : const Color(0xFF6B6B8A),
                            size: 22),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Strict mode warning ───────────────────────────────────
              if (focus.focusLevel == FocusLevel.strict) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    // BUG FIX: Light mode warning container needs more visible tint
                    color: AppTheme.errorColor
                        .withValues(alpha: isDark ? 0.06 : 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.errorColor
                            .withValues(alpha: isDark ? 0.25 : 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppTheme.errorColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                'You will NOT be able to stop this session until the timer ends.',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // BUG FIX: Phone icon was using textPrimary — use explicit icon color
                          Icon(Icons.phone_rounded,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Allow emergency calls',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary)),
                          ),
                          _toggle(
                            value: focus.allowEmergencyCalls,
                            onTap: () => focus.setAllowEmergencyCalls(
                                !focus.allowEmergencyCalls),
                            activeColor: AppTheme.gemColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Breathing exercise toggle ─────────────────────────────
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: focus.showBreathing
                      ? AppTheme.gemColor
                      .withValues(alpha: isDark ? 0.07 : 0.08)
                      : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focus.showBreathing
                        ? AppTheme.gemColor
                        .withValues(alpha: isDark ? 0.25 : 0.35)
                        : cardBorder,
                    width: focus.showBreathing ? 1.5 : 1,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                        color: focus.showBreathing
                            ? AppTheme.gemColor.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        // BUG FIX: Icon container slightly more visible in light mode
                        color: AppTheme.gemColor
                            .withValues(alpha: isDark ? 0.12 : 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.self_improvement_rounded,
                          color: AppTheme.gemColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Breathing Exercise',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary)),
                          Text('Calm before focusing',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSec)),
                        ],
                      ),
                    ),
                    _toggle(
                      value: focus.showBreathing,
                      onTap: () =>
                          focus.setShowBreathing(!focus.showBreathing),
                      activeColor: AppTheme.gemColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Start Button ──────────────────────────────────────────
              GestureDetector(
                onTap: () => _handleStartFocus(focus),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        focus.focusLevel.color,
                        focus.focusLevel.color.withValues(alpha: 0.75)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: focus.focusLevel.color
                              .withValues(alpha: isDark ? 0.30 : 0.40),
                          blurRadius: isDark ? 16 : 20,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(focus.focusLevel.icon,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Start ${focus.focusLevel.label}',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Focus Level Card ───────────────────────────────────────────────────
  Widget _buildLevelCard(
      FocusProvider focus,
      FocusLevel level,
      bool isDark,
      Color textPrimary,
      Color textSec,
      Color cardBg,
      Color cardBorder,
      ) {
    final isSelected = focus.focusLevel == level;
    return GestureDetector(
      onTap: () => focus.setFocusLevel(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? level.color.withValues(alpha: isDark ? 0.10 : 0.08)
              : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? level.color.withValues(alpha: isDark ? 0.40 : 0.55)
                : cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: isSelected
                // BUG FIX: More prominent selected shadow in light mode
                    ? level.color.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isSelected ? 14 : 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? level.color.withValues(alpha: isDark ? 0.15 : 0.14)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                // BUG FIX: Light mode unselected icon bg was barely visible
                    : const Color(0xFFEFEEF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected
                        ? level.color.withValues(alpha: isDark ? 0.30 : 0.40)
                        : Colors.transparent),
              ),
              child: Icon(level.icon,
                  // BUG FIX: Unselected icon was using textSec (too grey in light mode)
                  color: isSelected
                      ? level.color
                      : isDark
                      ? AppTheme.darkTextSec
                      : const Color(0xFF5A5A7A),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(level.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? level.color : textPrimary,
                          )),
                      if (level == FocusLevel.moderate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            // BUG FIX: Badge bg slightly more opaque in light mode
                            color: AppTheme.gemColor
                                .withValues(alpha: isDark ? 0.15 : 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Recommended',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.gemColor)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(level.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSec)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? level.color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? level.color
                      : isDark
                      ? Colors.white.withValues(alpha: 0.15)
                  // BUG FIX: Radio border in light mode was barely visible
                      : const Color(0xFFBBB9D8),
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable custom toggle ────────────────────────────────────────────
  Widget _toggle({
    required bool value,
    required VoidCallback onTap,
    required Color activeColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: value
              ? activeColor
              : isDark
              ? Colors.white.withValues(alpha: 0.08)
          // BUG FIX: Light mode OFF toggle was nearly invisible (grey.shade300)
              : const Color(0xFFCCCAE0), // more visible purple-grey
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartFocus(FocusProvider focus) async {
    if (focus.isSessionRunning) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A session is already running!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (focus.focusLevel != FocusLevel.light) {
      await focus.checkPermissions();
      if (!mounted) return;
      if (!focus.hasUsagePermission || !focus.hasOverlayPermission) {
        _showPermissionsDialog(focus);
        return;
      }
    }

    if (focus.focusLevel == FocusLevel.strict) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppTheme.errorColor, size: 22),
              const SizedBox(width: 10),
              Text('Strict Mode',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          content: Text(
            'You will NOT be able to stop this $_selectedMinutes-minute session until it ends.\n\nAll apps will be blocked. ${focus.allowEmergencyCalls ? "Only phone calls will work." : "No exceptions."}\n\nAre you sure?',
            style:
            GoogleFonts.inter(color: AppTheme.darkTextSec, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppTheme.darkTextSec)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Lock In',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    focus.setTargetMinutes(_selectedMinutes);

    if (focus.showBreathing) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BreathingExercise(
            onComplete: () {
              Navigator.of(context).pop();
              focus.startFocusSession();
            },
          ),
        ),
      );
    } else {
      focus.startFocusSession();
    }
  }

  void _showPermissionsDialog(FocusProvider focus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Permissions Required',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, color: Colors.white)),
        content: Text(
          'App blocking needs Usage Access and Display Over Other Apps permissions.',
          style: GoogleFonts.inter(color: AppTheme.darkTextSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.darkTextSec)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!focus.hasUsagePermission) {
                await focus.requestUsagePermission();
              }
              if (!focus.hasOverlayPermission) {
                await focus.requestOverlayPermission();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Grant',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDurationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F0F1A);
    final textSecColor =
    isDark ? AppTheme.darkTextSec : const Color(0xFF4A4A6A);

    final controller =
    TextEditingController(text: _selectedMinutes.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Custom Duration',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, color: textColor)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: textColor),
          decoration: InputDecoration(
            labelText: 'Minutes (1–1440)',
            labelStyle: GoogleFonts.inter(color: textSecColor),
            // BUG FIX: Added explicit input border color for light mode
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFCCCAE0)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: textSecColor)),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 1 && parsed <= 1440) {
                setState(() => _selectedMinutes = parsed);
                Navigator.pop(ctx);
              }
            },
            child: Text('Set',
                style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ===========================================
  //  ACTIVE FOCUS SCREEN — dark only (full immersion)
  // ===========================================
  Widget _buildActiveFocus(FocusProvider focus, GameProvider game) {
    final quoteIndex = (focus.remainingSeconds ~/ 30) % _quotes.length;
    final level = focus.focusLevel;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => focus.reportActivity(),
      onPanDown: (_) => focus.reportActivity(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Focus session is running.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF12121A), Color(0xFF0A0A0F)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text('Deep Focus',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const Spacer(),
                      if (focus.isPaused)
                        _statusBadge('PAUSED', AppTheme.warningColor)
                      else
                        _statusBadge(level.label.toUpperCase(), level.color),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _GlowingProgressPainter(
                          progress: focus.progress,
                          color1: level.color,
                          color2: level.color.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1E2E), Color(0xFF12121A)],
                        ),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(focus.formattedRemainingTime,
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              )),
                          const SizedBox(height: 4),
                          Text(level.label.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: level.color,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(_quotes[quoteIndex],
                        key: ValueKey(quoteIndex),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkTextSec,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        )),
                  ),
                ),

                const Spacer(flex: 1),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161F),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.04))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!focus.isStrictMode)
                        _controlButton(
                          icon: focus.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          label: focus.isPaused ? 'Resume' : 'Pause',
                          color: AppTheme.primaryColor,
                          isActive: focus.isPaused,
                          onTap: focus.isPaused
                              ? focus.resumeFocusSession
                              : focus.pauseFocusSession,
                        ),
                      if (!focus.isStrictMode)
                        _controlButton(
                          icon: Icons.stop_rounded,
                          label: 'End',
                          color: AppTheme.errorColor,
                          isActive: false,
                          onTap: () => _showStopDialog(context, focus),
                        ),
                      _controlButton(
                        icon: level.icon,
                        label: level.label.split(' ').first,
                        color: level.color,
                        isActive: true,
                        onTap: () {},
                      ),
                      _controlButton(
                        icon: Icons.do_not_disturb_on_rounded,
                        label: 'DND',
                        color: AppTheme.accentPurple,
                        isActive: focus.enableDND,
                        onTap: () {},
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

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1)),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                  color: isActive
                      ? color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06)),
            ),
            child: Icon(icon,
                color: isActive
                    ? color
                    : Colors.white.withValues(alpha: 0.5),
                size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(
                color: isActive ? color : AppTheme.darkTextSec,
                fontSize: 11,
                fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ===========================================
  //  BREAK SCREEN — dark only
  // ===========================================
  Widget _buildBreakScreen(FocusProvider focus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF12121A), Color(0xFF0A0A0F)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('☕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Break Time',
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.gemColor)),
            const SizedBox(height: 8),
            Text('Rest, stretch, breathe',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkTextSec)),
            const SizedBox(height: 40),
            Text(focus.formattedRemainingTime,
                style: GoogleFonts.inter(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            const SizedBox(height: 32),
            Text('${focus.pomodoroCount} Pomodoros completed',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldColor)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => focus.skipBreak(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text('Skip Break',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopDialog(BuildContext context, FocusProvider focus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session?',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, color: Colors.white)),
        content: Text(
          "Ending early will cost you HP and you won't receive Gold or XP rewards.",
          style:
          GoogleFonts.inter(color: AppTheme.darkTextSec, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Going',
                style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              focus.cancelFocusSession();
              context.read<GameProvider>().takeDamage(10);
            },
            child: Text('End Session',
                style: GoogleFonts.inter(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _GlowingProgressPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  _GlowingProgressPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = const Color(0xFF1A1C22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final currentSweep = sweepAngle * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [color1, color2, color1],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(3 * math.pi / 4),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    if (progress > 0) {
      canvas.drawArc(rect, startAngle, currentSweep, false, glowPaint);
      canvas.drawArc(rect, startAngle, currentSweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2;
  }
}