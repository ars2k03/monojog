import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (ctx, game, _) {
        final p = game.profile;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar box
              Container(
                width: 72,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_avatarEmoji(p.avatarType),
                        style: const TextStyle(fontSize: 32)),
                    Text(
                      'Lv. ${p.level}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Stats bars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health bar
                    _StatBar(
                      icon: '❤️',
                      value: p.health,
                      max: p.maxHealth,
                      color: AppTheme.healthRed,
                      label: '${p.health} / ${p.maxHealth}',
                      trailLabel: 'Health',
                    ),
                    const SizedBox(height: 5),
                    // XP bar
                    _StatBar(
                      icon: '⭐',
                      value: p.experience,
                      max: p.experienceToNext,
                      color: AppTheme.xpYellow,
                      label: '${p.experience} / ${p.experienceToNext}',
                      trailLabel: 'Experience',
                    ),
                    const SizedBox(height: 8),
                    // Gold & Gems row
                    Row(
                      children: [
                        _CurrencyChip(emoji: '🪙', value: p.gold),
                        const SizedBox(width: 12),
                        _CurrencyChip(emoji: '💎', value: p.gems),
                        const Spacer(),
                        if (p.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  '${p.currentStreak}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _avatarEmoji(String type) {
    switch (type) {
      case 'mage':
        return '🧙';
      case 'healer':
        return '🧑‍⚕️';
      case 'rogue':
        return '🥷';
      default:
        return '⚔️';
    }
  }
}

class _StatBar extends StatelessWidget {
  final String icon;
  final int value;
  final int max;
  final Color color;
  final String label;
  final String trailLabel;

  const _StatBar({
    required this.icon,
    required this.value,
    required this.max,
    required this.color,
    required this.label,
    required this.trailLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          trailLabel,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String emoji;
  final int value;

  const _CurrencyChip({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
