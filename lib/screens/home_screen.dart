import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monojog/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'my_day_screen.dart';
import 'sleep_screen.dart';
import 'habits_screen.dart';
import 'brain_dump_screen.dart';
import 'blocked_apps_screen.dart';
import 'subjects_screen.dart';
import 'session_history_screen.dart';
import 'task_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  static const _level            = 1;
  static const _levelTitle       = 'Beginner';
  static const _experience       = 0;
  static const _experienceToNext = 100;
  static const _health           = 100;
  static const _totalFocusMin    = 0;
  static const _sessionsDone     = 0;
  static const _gold             = 0;
  static const _gems             = 0;
  static const _currentStreak    = 0;
  static const _habitsScheduled  = 0;
  static const _habitsDone       = 0;
  static const _todayTasks       = 0;
  static const _todayDone        = 0;
  static const _isFocusActive    = false;
  static const _focusRemaining   = '25:00';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ── watch AuthProvider তাই name/avatar চেঞ্জ হলে rebuild হবে ──
    final auth = context.watch<AuthProvider>();
    final username = auth.user?.displayName ??
        (auth.isOfflineMode ? 'Offline User' : 'Student');
    final avatarType = auth.avatarType;

    final textPrimary   = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? AppTheme.darkTextSec : Colors.grey.shade600;
    final cardBg        = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final cardBorder    = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;
    final iconBg        = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;

    return CustomScrollView(
      slivers: [
        // ── App Bar ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                // Avatar — auth থেকে avatarType নেওয়া হচ্ছে
                GestureDetector(
                  onTap: () => _showProfileEditSheet(
                      context, username, avatarType, isDark),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _avatarEmoji(avatarType),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingText(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Streak badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${HomeScreen._currentStreak}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Settings
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Level & XP Card ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LevelCard(
              level: HomeScreen._level,
              levelTitle: HomeScreen._levelTitle,
              experience: HomeScreen._experience,
              experienceToNext: HomeScreen._experienceToNext,
              health: HomeScreen._health,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Quick Stats ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.timer_rounded,
                  value: '${HomeScreen._totalFocusMin}',
                  unit: 'min',
                  color: AppTheme.primaryColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.check_circle_rounded,
                  value: '${HomeScreen._sessionsDone}',
                  unit: 'done',
                  color: AppTheme.successColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.monetization_on_rounded,
                  value: '${HomeScreen._gold}',
                  unit: 'gold',
                  color: AppTheme.goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.diamond_rounded,
                  value: '${HomeScreen._gems}',
                  unit: 'gems',
                  color: const Color(0xFFE040FB),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Today's Habits ────────────────────────────────────────────────
        if (HomeScreen._habitsScheduled > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HabitsScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? null : Colors.white,
                    gradient: isDark
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                        const Color(0xFF00E5A0).withValues(alpha: 0.04),
                      ],
                    )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder),
                    boxShadow: isDark
                        ? []
                        : [
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
                        width: 44,
                        height: 44,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: HomeScreen._habitsScheduled > 0
                                  ? HomeScreen._habitsDone / HomeScreen._habitsScheduled
                                  : 0,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                HomeScreen._habitsDone >= HomeScreen._habitsScheduled
                                    ? AppTheme.goldColor
                                    : const Color(0xFF00E5A0),
                              ),
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                HomeScreen._habitsScheduled > 0 &&
                                    HomeScreen._habitsDone >= HomeScreen._habitsScheduled
                                    ? '🎉'
                                    : '${HomeScreen._habitsScheduled > 0 ? ((HomeScreen._habitsDone / HomeScreen._habitsScheduled) * 100).round() : 0}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
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
                            Text(
                              "Today's Habits",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${HomeScreen._habitsDone} of ${HomeScreen._habitsScheduled} done',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Quick Actions ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Start Focus CTA ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StartFocusCTA(
              isFocusActive: HomeScreen._isFocusActive,
              focusRemaining: HomeScreen._focusRemaining,
              onSwitchTab: widget.onSwitchTab,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // ── My Day Quick Card ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MyDayQuickCard(
              todayTasks: HomeScreen._todayTasks,
              todayDone: HomeScreen._todayDone,
              habitsScheduled: HomeScreen._habitsScheduled,
              habitsDone: HomeScreen._habitsDone,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Tools & Features ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tools & Features',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Feature Grid ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: _buildFeatureGrid(context, isDark),
        ),
      ],
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  String _avatarEmoji(String type) {
    switch (type) {
      case 'mage':   return '🧙';
      case 'healer': return '🧑‍⚕️';
      case 'rogue':  return '🥷';
      default:       return '⚔️';
    }
  }

  // ── Profile Edit Sheet ────────────────────────────────────────────────────
  void _showProfileEditSheet(
      BuildContext context, String currentName, String currentAvatar, bool isDark) {
    final nameController = TextEditingController(text: currentName);
    // local state শুধু bottom sheet এর মধ্যে
    String selectedAvatar = currentAvatar;
    final avatars = ['warrior', 'mage', 'healer', 'rogue'];

    final sheetBg       = isDark ? AppTheme.darkCard : Colors.white;
    final inputFill     = isDark ? AppTheme.darkBg : Colors.grey.shade100;
    final textPrimary   = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? AppTheme.darkTextSec : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Profile',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.premiumGradient,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _avatarEmoji(selectedAvatar),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Choose Avatar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: avatars.map((type) {
                  final isSelected = selectedAvatar == type;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedAvatar = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : inputFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _avatarEmoji(type),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                'Your Name',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.inter(color: textSecondary),
                  prefixIcon:
                  Icon(Icons.person_outline, color: textSecondary),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                    // ── নাম update — AuthProvider এর method দিয়ে ──
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty && newName != currentName) {
                      await authProvider.updateDisplayName(newName);
                    }

                    // ── Avatar update — AuthProvider এ save ও notify ──
                    if (selectedAvatar != currentAvatar) {
                      await authProvider.updateAvatar(selectedAvatar);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isDark) {
    final features = [
      _Feature(Icons.today_rounded, 'My Day', 'Tasks + Habits',
          const [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyDayScreen()))),
      _Feature(Icons.checklist_rounded, 'Tasks', 'Manage to-dos',
          const [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TaskScreen()))),
      _Feature(Icons.repeat_rounded, 'Habits', 'Build consistency',
          const [Color(0xFF7C4DFF), Color(0xFFE040FB)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HabitsScreen()))),
      _Feature(Icons.psychology_rounded, 'Brain Dump', 'Clear your mind',
          const [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BrainDumpScreen()))),
      _Feature(Icons.block_rounded, 'App Blocker', 'Stay distraction-free',
          const [Color(0xFF00F5D4), Color(0xFF00BBD4)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BlockedAppsScreen()))),
      _Feature(Icons.school_rounded, 'Subjects', 'Track your courses',
          const [Color(0xFFFEE440), Color(0xFFF77F00)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SubjectsScreen()))),
      _Feature(Icons.history_rounded, 'History', 'Past sessions',
          const [Color(0xFF2979FF), Color(0xFF7C4DFF)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SessionHistoryScreen()))),
      _Feature(Icons.nights_stay_rounded, 'Sleep', 'Sleep management',
          const [Color(0xFF00E5FF), Color(0xFF2979FF)],
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SleepScreen()))),
    ];

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: features.length,
      itemBuilder: (ctx, i) =>
          _FeatureCard(feature: features[i], isDark: isDark),
    );
  }
}

// ── Level Card ────────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int level, experience, experienceToNext, health;
  final String levelTitle;
  final bool isDark;
  final Color cardBg, cardBorder, textPrimary, textSecondary;

  const _LevelCard({
    required this.level,
    required this.levelTitle,
    required this.experience,
    required this.experienceToNext,
    required this.health,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = experienceToNext > 0
        ? (experience / experienceToNext).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.premiumGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$level',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('LVL',
                        style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(levelTitle,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('$experience / $experienceToNext XP',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary)),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('$health',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.healthRed)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('HP',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: xpProgress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: AppTheme.premiumGradient,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, unit;
  final Color color, textPrimary, textSecondary;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textPrimary)),
            Text(unit,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Start Focus CTA ───────────────────────────────────────────────────────────
class _StartFocusCTA extends StatelessWidget {
  final bool isFocusActive, isDark;
  final String focusRemaining;
  final void Function(int)? onSwitchTab;
  final Color textPrimary, textSecondary;

  const _StartFocusCTA({
    required this.isFocusActive,
    required this.focusRemaining,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    if (isFocusActive) {
      return GestureDetector(
        onTap: () => onSwitchTab?.call(2),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: isDark
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1040), Color(0xFF16161F)],
            )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                        blurRadius: 12)
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session In Progress',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('$focusRemaining remaining',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C4DFF))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    color: textSecondary, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onSwitchTab?.call(2),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2940), Color(0xFF0F1520)],
          )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryColor
                  .withValues(alpha: isDark ? 0.15 : 0.2)),
          boxShadow: isDark
              ? [
            BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ]
              : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12)
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Focus Session',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Tap to begin deep focus mode',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('GO',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Day Quick Card ─────────────────────────────────────────────────────────
class _MyDayQuickCard extends StatelessWidget {
  final int todayTasks, todayDone, habitsScheduled, habitsDone;
  final bool isDark;
  final Color textPrimary, textSecondary, cardBg, cardBorder;

  const _MyDayQuickCard({
    required this.todayTasks,
    required this.todayDone,
    required this.habitsScheduled,
    required this.habitsDone,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final totalActive = todayTasks + habitsScheduled;
    final totalDone   = todayDone + habitsDone;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MyDayScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? null : cardBg,
          gradient: isDark
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00E5FF).withValues(alpha: 0.08),
              const Color(0xFF7C4DFF).withValues(alpha: 0.04),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.today_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Day',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    totalActive == 0
                        ? 'No items for today'
                        : '$totalDone/$totalActive done · ${todayTasks}T ${habitsScheduled}H',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary),
                  ),
                ],
              ),
            ),
            if (totalActive > 0) ...[
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: totalDone / totalActive,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    totalDone >= totalActive
                        ? AppTheme.goldColor
                        : const Color(0xFF00E5FF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Feature Model ─────────────────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _Feature(this.icon, this.title, this.subtitle, this.gradient, this.onTap);
}

// ── Feature Card ──────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final _Feature feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final f      = widget.feature;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        f.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? f.gradient[0].withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? f.gradient[0].withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      f.gradient[0].withValues(alpha: isDark ? 0.2 : 0.15),
                      f.gradient[1].withValues(alpha: isDark ? 0.08 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(f.icon, color: f.gradient[0], size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                f.title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                f.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextSec : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}