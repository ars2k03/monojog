import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:monojog/providers/study_room_provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/models/study_room.dart';
import 'package:monojog/screens/community_screen.dart';

// Ultra-modern room palette — light/dark adaptive
class _R {
  // Dark mode colors
  static const _bgDark = Color(0xFF0A0E1A);
  static const _cardDark = Color(0xFF141828);
  static const _cardLightDark = Color(0xFF1C2137);
  static const _surfaceDark = Color(0xFF1A1F33);

  // Light mode colors
  static const _bgLight = Color(0xFFF5F7FF);
  static const _cardLight = Color(0xFFFFFFFF);
  static const _cardLightLight = Color(0xFFEEF0FA);
  static const _surfaceLight = Color(0xFFE8EAF6);

  // Accent colors (same for both modes)
  static const cyan = Color(0xFF00ACC1);
  static const cyanDark = Color(0xFF00838F);
  static const purple = Color(0xFF7C4DFF);
  static const gold = Color(0xFFFFB300);
  static const green = Color(0xFF00BFA5);
  static const red = Color(0xFFEF5350);
  static const white = Colors.white;

  // Dynamic getters
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _bgDark : _bgLight;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _cardDark : _cardLight;
  static Color cardLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _cardLightDark
          : _cardLightLight;
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _surfaceDark
          : _surfaceLight;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1F33);
  static Color textSec(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6B7294)
          : const Color(0xFF757B9A);
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C2137)
          : const Color(0xFFDDE0F0);
}

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<StudyRoomProvider>(
      builder: (ctx, room, _) {
        if (room.isInRoom) {
          return _ActiveRoomView(room: room);
        }
        return const _RoomLobby();
      },
    );
  }
}

// LOBBY
class _RoomLobby extends StatefulWidget {
  const _RoomLobby();

  @override
  State<_RoomLobby> createState() => _RoomLobbyState();
}

class _RoomLobbyState extends State<_RoomLobby>
    with SingleTickerProviderStateMixin {
  int _selectedPlant = 0;
  int _selectedMinutes = 60;
  late AnimationController _glowController;

  static const _plants = [
    _PlantInfo('🌵', 'Cactus', 'Love hidden in the bottom of my heart.'),
    _PlantInfo('🌻', 'Sunflower', 'Always facing the bright side of life.'),
    _PlantInfo('🌿', 'Fern', 'Patience is the companion of wisdom.'),
    _PlantInfo('🌷', 'Tulip', 'Perfect love blooms in silence.'),
    _PlantInfo('🌳', 'Oak', 'Great oaks from little acorns grow.'),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _R.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildPlayerStatsBar(),
              const SizedBox(height: 16),
              _buildCommunityButton(),
              const SizedBox(height: 20),
              _buildModeSelector(),
              const SizedBox(height: 20),
              _buildPlantSelector(),
              const SizedBox(height: 20),
              _buildTimerSelector(),
              const SizedBox(height: 20),
              _buildMilestones(),
              const SizedBox(height: 20),
              _buildQuickStats(),
              const SizedBox(height: 20),
              _buildStartButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Room',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _R.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Focus together, grow together',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _R.textSec(context),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showMenuSheet,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _R.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _R.cyan.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child:
            const Icon(Icons.grid_view_rounded, color: _R.cyan, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerStatsBar() {
    final game = context.watch<GameProvider>();
    final p = game.profile;
    final xpPct =
    p.experienceToNext > 0 ? p.experience / p.experienceToNext : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _R.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _R.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _R.purple.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${p.level}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level ',
                      style: TextStyle(
                        color: _R.textSec(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${p.level}',
                      style: const TextStyle(
                        color: _R.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p.experience}/${p.experienceToNext} XP',
                      style: TextStyle(
                        color: _R.textSec(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _R.surface(context),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: xpPct.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF00ACC1)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _R.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: _R.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${p.gold}',
                  style: const TextStyle(
                    color: _R.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _R.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: _R.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${p.health}',
                  style: const TextStyle(
                    color: _R.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _modeCard(
            icon: Icons.person_rounded,
            title: 'Solo Focus',
            subtitle: 'Deep work mode',
            color: _R.cyan,
            onTap: () => _showSoloStartDialog(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _modeCard(
            icon: Icons.group_rounded,
            title: 'Team Room',
            subtitle: 'Study together',
            color: _R.purple,
            onTap: () => _showRoomOptions(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityButton() {
    final roomProvider = context.watch<StudyRoomProvider>();
    final community = roomProvider.joinedCommunity;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _R.purple.withValues(alpha: 0.12),
              _R.cyan.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _R.purple.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _R.purple.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: -3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _R.purple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _R.purple.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: _R.purple, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community != null ? community.name : 'Communities',
                    style: TextStyle(
                      color: _R.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    community != null
                        ? '${community.members.length} members • Tap to chat'
                        : 'Join a group to study together',
                    style: TextStyle(
                      color: _R.textSec(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _R.purple, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _R.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _R.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _R.textSec(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Choose your plant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _R.textPrimary(context),
              ),
            ),
            const Spacer(),
            Text(
              _plants[_selectedPlant].name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _R.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _plants.length,
            itemBuilder: (ctx, i) {
              final p = _plants[i];
              final isSelected = _selectedPlant == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlant = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _R.cyan.withValues(alpha: 0.1)
                        : _R.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? _R.cyan : _R.border(context),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? _R.cyan : _R.textSec(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _R.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _R.border(context)),
          ),
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  color: _R.textSec(context), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _plants[_selectedPlant].quote,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _R.textSec(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSelector() {
    const durations = [15, 25, 30, 45, 60, 90, 120];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Focus Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _R.textPrimary(context),
              ),
            ),
            const Spacer(),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _R.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_selectedMinutes min',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _R.cyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: durations.map((m) {
            final isSelected = _selectedMinutes == m;
            return GestureDetector(
              onTap: () => setState(() => _selectedMinutes = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _R.cyan.withValues(alpha: 0.12)
                      : _R.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _R.cyan : _R.border(context),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$m min',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? _R.cyan : _R.textSec(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMilestones() {
    final focus = context.watch<FocusProvider>();
    final game = context.watch<GameProvider>();
    final totalMin = focus.pomodoroCount * 25;
    final sessionsCount = focus.pomodoroCount;
    final badgeCount = game.unlockedBadgeCount;

    final milestones = [
      _MilestoneData(
        icon: Icons.timer_rounded,
        label: 'Focus Time',
        value: '${totalMin}m',
        target: '120m',
        progress: (totalMin / 120).clamp(0.0, 1.0),
        color: _R.cyan,
        reward: '+10 XP',
      ),
      _MilestoneData(
        icon: Icons.local_fire_department_rounded,
        label: 'Sessions',
        value: '$sessionsCount',
        target: '5',
        progress: (sessionsCount / 5).clamp(0.0, 1.0),
        color: _R.red,
        reward: '+15 XP',
      ),
      _MilestoneData(
        icon: Icons.emoji_events_rounded,
        label: 'Badges',
        value: '$badgeCount',
        target: '10',
        progress: (badgeCount / 10).clamp(0.0, 1.0),
        color: _R.gold,
        reward: '+5 Gold',
      ),
      _MilestoneData(
        icon: Icons.eco_rounded,
        label: 'Plants Grown',
        value: '${focus.pomodoroCount}',
        target: '10',
        progress: (focus.pomodoroCount / 10).clamp(0.0, 1.0),
        color: _R.green,
        reward: '+20 XP',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.military_tech_rounded, color: _R.gold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Daily Milestones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _R.textPrimary(context),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _R.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${milestones.where((m) => m.progress >= 1.0).length}/${milestones.length}',
                style: const TextStyle(
                  color: _R.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...milestones.map((m) {
          final done = m.progress >= 1.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: done
                  ? m.color.withValues(alpha: 0.06)
                  : _R.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: done
                    ? m.color.withValues(alpha: 0.2)
                    : _R.border(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    done ? Icons.check_circle_rounded : m.icon,
                    color: m.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            m.label,
                            style: TextStyle(
                              color: _R.textPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${m.value} / ${m.target}',
                            style: TextStyle(
                              color: done ? m.color : _R.textSec(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _R.surface(context),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: m.progress,
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: m.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: done
                        ? m.color.withValues(alpha: 0.15)
                        : _R.surface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    done ? '✓' : m.reward,
                    style: TextStyle(
                      color: done ? m.color : _R.textSec(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickStats() {
    final focus = context.watch<FocusProvider>();
    final todayMin = focus.pomodoroCount * 25;
    final targetMin = max(1, focus.targetMinutes);
    final pct = (todayMin / targetMin * 100).clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _R.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _R.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 5,
                    backgroundColor: _R.surface(context),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(_R.cyan),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Center(
                  child: Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _R.cyan,
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
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _R.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${todayMin}min of ${targetMin}min target',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _R.textSec(context),
                  ),
                ),
              ],
            ),
          ),
          _miniStat(Icons.local_fire_department_rounded,
              '${focus.pomodoroCount}', _R.red),
          const SizedBox(width: 12),
          _miniStat(
              Icons.bolt_rounded, '${focus.pomodoroCount * 10}', _R.gold),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () => _showFocusStartDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [_R.cyan, _R.cyanDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _R.cyan.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Start Focus Session',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper for bottom sheet backdrop ──
  BoxDecoration _sheetDecor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF141828) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );
  }

  // DIALOGS
  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: _sheetDecor(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _R.textSec(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _menuItem(Icons.groups_rounded, 'Create Community', _R.purple,
                        () {
                      Navigator.pop(ctx);
                      _showCreateCommunityDialog();
                    }),
                _menuItem(Icons.group_add_rounded, 'Join Community', _R.green,
                        () {
                      Navigator.pop(ctx);
                      _showJoinCommunityDialog();
                    }),
                _menuItem(
                    Icons.leaderboard_rounded, 'Leaderboard', _R.gold, () {
                  Navigator.pop(ctx);
                  _showLeaderboard();
                }),
                _menuItem(
                    Icons.settings_rounded, 'Settings', _R.textSec(context),
                        () {
                      Navigator.pop(ctx);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _R.textPrimary(context),
              fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: _R.textSec(context)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _showRoomOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: _sheetDecor(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _R.textSec(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Team Room',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _R.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a room or join one with a code',
                  style: TextStyle(fontSize: 13, color: _R.textSec(context)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _optionCard(
                        Icons.add_circle_rounded,
                        'Create',
                        'Room',
                        _R.cyan,
                            () {
                          Navigator.pop(ctx);
                          _showCreateRoomDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _optionCard(
                        Icons.login_rounded,
                        'Join',
                        'Room',
                        _R.purple,
                            () {
                          Navigator.pop(ctx);
                          _showJoinRoomDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionCard(IconData icon, String title, String sub, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    color: _R.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 2),
            Text(sub,
                style:
                TextStyle(color: _R.textSec(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _R.textSec(context).withValues(alpha: 0.7)),
      filled: true,
      fillColor: _R.surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  TextStyle get _inputTextStyle =>
      TextStyle(color: _R.textPrimary(context));

  AlertDialog _styledDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: _R.card(context),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w900, color: _R.textPrimary(context)),
      ),
      content: content,
      actions: actions,
    );
  }

  void _showFocusStartDialog() {
    final plant = _plants[_selectedPlant];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(plant.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              'Start Focus',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _R.textPrimary(context)),
            ),
          ],
        ),
        content: Text(
          "Plant your ${plant.name} and focus for $_selectedMinutes minutes.\nDon't leave or your plant will wither!",
          style: TextStyle(color: _R.textSec(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final focus = context.read<FocusProvider>();
              if (focus.isFocusActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A focus session is already running!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              focus.setTargetMinutes(_selectedMinutes);
              focus.startFocusSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Plant it!',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showSoloStartDialog() {
    final plant = _plants[_selectedPlant];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(plant.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Solo Focus Room',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _R.textPrimary(context),
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your solo study room with ${plant.name}.\n$_selectedMinutes minute session — just you and your focus.',
              style:
              TextStyle(color: _R.textSec(context), height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _R.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _R.cyan.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: _R.cyan, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A private room with timer, app blocking, and full focus tracking.',
                      style: TextStyle(
                          color: _R.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (FocusProvider.isAnySessionActive) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'A ${FocusProvider.globalActiveSession} session is active. End it first.'),
                      backgroundColor: _R.red,
                    ),
                  );
                }
                return;
              }
              await context.read<StudyRoomProvider>().createSoloRoom(
                subject: plant.name,
                targetMinutes: _selectedMinutes,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Enter Solo Room',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showCreateRoomDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Create Study Room',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _R.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: _inputTextStyle,
              decoration: _inputDecor('Room name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectCtrl,
              style: _inputTextStyle,
              decoration: _inputDecor('Subject (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final roomName = nameCtrl.text.trim().isEmpty
                  ? 'Study Room'
                  : nameCtrl.text.trim();
              final subject = subjectCtrl.text.trim().isEmpty
                  ? null
                  : subjectCtrl.text.trim();
              final room =
              await context.read<StudyRoomProvider>().createRoom(
                name: roomName,
                subject: subject,
                targetMinutes: _selectedMinutes,
              );
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Room created! Code: ${room.roomCode}'),
                  backgroundColor: _R.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Join Study Room',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _R.textPrimary(context)),
        ),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 7,
          style: const TextStyle(
            color: _R.cyan,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'CODE',
            hintStyle: TextStyle(
                color: _R.textSec(context).withValues(alpha: 0.45)),
            filled: true,
            fillColor: _R.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await context
                  .read<StudyRoomProvider>()
                  .joinRoom(codeCtrl.text.trim().toUpperCase());
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content:
                  Text(ok ? 'Joined room!' : 'Room code not found.'),
                  backgroundColor: ok ? _R.green : _R.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Join',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showCreateCommunityDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Create Community',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _R.textPrimary(context)),
        ),
        content: TextField(
          controller: nameCtrl,
          style: _inputTextStyle,
          decoration: _inputDecor('e.g. CSE Batch 2026'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final name = nameCtrl.text.trim().isEmpty
                  ? 'My Community'
                  : nameCtrl.text.trim();
              final community = await context
                  .read<StudyRoomProvider>()
                  .createCommunity(name: name);
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Community created. Code: ${community.code}'),
                  backgroundColor: _R.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinCommunityDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Join Community',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _R.textPrimary(context)),
        ),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 7,
          style: const TextStyle(
            color: _R.cyan,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'FRIEND1',
            hintStyle: TextStyle(
                color: _R.textSec(context).withValues(alpha: 0.45)),
            filled: true,
            fillColor: _R.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await context
                  .read<StudyRoomProvider>()
                  .joinCommunity(codeCtrl.text.trim().toUpperCase());
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Community joined successfully.'
                      : 'Community code not found.'),
                  backgroundColor: ok ? _R.green : _R.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    final community =
        context.read<StudyRoomProvider>().joinedCommunity;
    final members = community?.members ?? [];
    final leaders = members
        .asMap()
        .entries
        .map((e) =>
        _LeaderEntry(e.value.name, e.value.studyMinutes, e.key + 1))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: _sheetDecor(),
        height: MediaQuery.of(ctx).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _R.textSec(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: _R.gold, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _R.textPrimary(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _R.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This Week',
                    style: TextStyle(
                      color: _R.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: leaders.length,
                itemBuilder: (ctx2, i) {
                  final l = leaders[i];
                  final isYou = l.name == 'You';
                  final rankColor = i == 0
                      ? _R.gold
                      : i == 1
                      ? const Color(0xFFC0C0C0)
                      : i == 2
                      ? const Color(0xFFCD7F32)
                      : _R.textSec(context);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isYou
                          ? _R.cyan.withValues(alpha: 0.08)
                          : _R.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: isYou
                          ? Border.all(
                          color: _R.cyan.withValues(alpha: 0.3),
                          width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: i < 3
                                ? Icon(Icons.emoji_events_rounded,
                                color: rankColor, size: 20)
                                : Text(
                              '#${i + 1}',
                              style: TextStyle(
                                color: _R.textSec(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l.name,
                            style: TextStyle(
                              color: isYou
                                  ? _R.cyan
                                  : _R.textPrimary(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '${l.minutes} min',
                          style: TextStyle(
                            color: isYou ? _R.cyan : _R.textSec(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// ACTIVE ROOM VIEW
// ══════════════════════════════════════════
class _ActiveRoomView extends StatefulWidget {
  final StudyRoomProvider room;
  const _ActiveRoomView({required this.room});

  @override
  State<_ActiveRoomView> createState() => _ActiveRoomViewState();
}

class _ActiveRoomViewState extends State<_ActiveRoomView> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = widget.room.currentRoom!;
    _scrollToBottom();

    return Scaffold(
      backgroundColor: _R.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildRoomHeader(currentRoom),
            _buildMemberCards(currentRoom),
            Consumer<FocusProvider>(
              builder: (ctx, focus, _) => _buildTimerSection(focus),
            ),
            Expanded(child: _buildChat()),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader(StudyRoom room) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showLeaveDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _R.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _R.border(context)),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: _R.textPrimary(context), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: _R.textPrimary(context),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _R.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${room.members.length} members',
                      style: TextStyle(
                          fontSize: 12, color: _R.textSec(context)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      room.roomCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _R.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.room.joinedCommunity != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '• ${widget.room.joinedCommunity!.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: _R.textSec(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: room.roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code copied!'),
                  backgroundColor: _R.cyan,
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _R.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _R.border(context)),
              ),
              child: const Icon(Icons.copy_rounded,
                  color: _R.cyan, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final inviteText =
                  'Join my Monojog study room!\n\nRoom Code: ${room.roomCode}\n\nOpen the app > Room > Join Room';
              SharePlus.instance.share(ShareParams(text: inviteText));
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _R.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _R.border(context)),
              ),
              child: const Icon(Icons.share_rounded,
                  color: _R.purple, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCards(StudyRoom room) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: room.members.length,
        itemBuilder: (ctx, i) {
          final member = room.members[i];
          final isMe = member.id == widget.room.myUserId;
          final statusColor =
          member.isStudying ? _R.green : _R.textSec(context);

          return Stack(
            children: [
              Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? _R.cyan.withValues(alpha: 0.06)
                      : _R.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isMe
                        ? _R.cyan.withValues(alpha: 0.25)
                        : _R.border(context),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: member.isStudying
                                ? _R.green.withValues(alpha: 0.12)
                                : _R.surface(context),
                            border: Border.all(
                              color: statusColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name
                                  .substring(0, 1)
                                  .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: member.isOnline
                                  ? _R.green
                                  : _R.textSec(context),
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: _R.bg(context), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMe ? 'You' : member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isMe ? _R.cyan : _R.textPrimary(context),
                      ),
                    ),
                    if (member.isStudying)
                      Text(
                        '${member.studyMinutes}m',
                        style: TextStyle(
                          fontSize: 9,
                          color: _R.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isMe)
                Positioned(
                  right: 12,
                  top: 4,
                  child: GestureDetector(
                    onTap: () => widget.room.pokeMember(member.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _R.purple.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 12,
                        color: _R.purple,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimerSection(FocusProvider focus) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _R.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.room.isStudying
              ? _R.cyan.withValues(alpha: 0.35)
              : _R.border(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.room.isStudying
                          ? _R.green
                          : _R.textSec(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.room.isStudying ? 'Studying...' : 'Ready',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.room.isStudying
                          ? _R.green
                          : _R.textSec(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.room.formattedTimer,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: widget.room.isStudying
                      ? _R.cyan
                      : _R.textPrimary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              if (widget.room.isStudying) {
                widget.room.stopStudyTimer();
                try {
                  await FocusProvider.platform
                      .invokeMethod('stopFocusMode');
                } catch (e) {
                  debugPrint('Failed to stop focus mode: $e');
                }
              } else {
                if (focus.blockAllApps ||
                    focus.blockedApps.isNotEmpty) {
                  await focus.checkPermissions();
                  if (!mounted) return;
                  if (!focus.hasUsagePermission ||
                      !focus.hasOverlayPermission) {
                    _showPermissionDialog(focus);
                    return;
                  }
                }
                if (FocusProvider.isAnySessionActive) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'A ${FocusProvider.globalActiveSession} session is active. End it first.'),
                        backgroundColor: _R.red,
                      ),
                    );
                  }
                  return;
                }
                widget.room.startStudyTimer();
                List<String> activeBlockedApps;
                if (focus.blockAllApps) {
                  activeBlockedApps = focus.installedApps
                      .map((app) => app.packageName)
                      .toList();
                } else {
                  activeBlockedApps = focus.blockedApps
                      .where((app) => app.isBlocked)
                      .map((app) => app.packageName)
                      .toList();
                }
                try {
                  await FocusProvider.platform
                      .invokeMethod('startFocusMode', {
                    'blockedApps': activeBlockedApps,
                    'durationMinutes': 1440,
                  });
                } catch (e) {
                  debugPrint('Failed to start focus mode: $e');
                }
              }
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.room.isStudying
                      ? [_R.red, _R.red.withValues(alpha: 0.8)]
                      : [_R.cyan, _R.cyanDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    (widget.room.isStudying ? _R.red : _R.cyan)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.room.isStudying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(FocusProvider focus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Text('Permissions Required',
            style: TextStyle(
                color: _R.textPrimary(context),
                fontWeight: FontWeight.w900)),
        content: Text(
          'To block apps while studying, Monojog needs Usage Access and Display Over Other Apps permissions.',
          style: TextStyle(color: _R.textSec(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: _R.textSec(context))),
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
              backgroundColor: _R.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    final messages = widget.room.messages;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                color: _R.cyan.withValues(alpha: 0.25), size: 48),
            const SizedBox(height: 12),
            Text(
              'Chat with your study buddies!',
              style: TextStyle(
                color: _R.textSec(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Motivate each other to stay focused',
              style: TextStyle(
                color: _R.textSec(context).withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        if (msg.type == MessageType.system ||
            msg.type == MessageType.studyStart ||
            msg.type == MessageType.studyEnd) {
          return _buildSystemMessage(msg);
        }
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildSystemMessage(RoomMessage msg) {
    Color bgColor = _R.surface(context);
    Color textColor = _R.textSec(context);

    if (msg.type == MessageType.studyStart) {
      bgColor = _R.green.withValues(alpha: 0.1);
      textColor = _R.green;
    } else if (msg.type == MessageType.studyEnd) {
      bgColor = _R.cyan.withValues(alpha: 0.1);
      textColor = _R.cyan;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(RoomMessage msg) {
    final isMe = msg.senderId == widget.room.myUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _R.cyan,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _R.cyan : _R.card(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: _R.border(context), width: 1),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isMe
                      ? Colors.white
                      : _R.textPrimary(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 2, left: 12, right: 12),
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10, color: _R.textSec(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: _R.card(context),
        border: Border(
          top: BorderSide(color: _R.border(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: _R.textPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: _R.textSec(context)),
                filled: true,
                fillColor: _R.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = _chatController.text;
              if (text.trim().isEmpty) return;
              widget.room.sendMessage(text);
              _chatController.clear();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_R.cyan, _R.cyanDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _R.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _R.card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Text('Leave Room?',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _R.textPrimary(context))),
        content: Text(
          'Are you sure you want to leave this study room?',
          style: TextStyle(color: _R.textSec(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay',
                style: TextStyle(
                    color: _R.cyan, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.room.leaveRoom();
            },
            child: const Text('Leave',
                style: TextStyle(color: _R.red)),
          ),
        ],
      ),
    );
  }
}

// Data classes
class _PlantInfo {
  final String emoji;
  final String name;
  final String quote;
  const _PlantInfo(this.emoji, this.name, this.quote);
}

class _LeaderEntry {
  final String name;
  final int minutes;
  final int rank;
  _LeaderEntry(this.name, this.minutes, this.rank);
}

class _MilestoneData {
  final IconData icon;
  final String label;
  final String value;
  final String target;
  final double progress;
  final Color color;
  final String reward;
  const _MilestoneData({
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
    required this.reward,
  });
}