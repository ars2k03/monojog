import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monojog/theme/app_theme.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Title Section ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2040), Color(0xFF16161F)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              const Text('🌳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Forest Rewards',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete focus sessions to grow your forest and earn rewards.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.darkTextSec,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Reward Items ──
        _buildRewardTile(
          emoji: '🌱',
          title: 'Seedling',
          description: 'Complete 1 focus session',
          unlocked: true,
        ),
        _buildRewardTile(
          emoji: '🌿',
          title: 'Sapling',
          description: 'Complete 5 focus sessions',
          unlocked: true,
        ),
        _buildRewardTile(
          emoji: '🌲',
          title: 'Young Tree',
          description: 'Complete 15 focus sessions',
          unlocked: false,
        ),
        _buildRewardTile(
          emoji: '🏔️',
          title: 'Forest Guardian',
          description: 'Complete 50 focus sessions',
          unlocked: false,
        ),
        _buildRewardTile(
          emoji: '👑',
          title: 'Forest Legend',
          description: 'Complete 100 focus sessions',
          unlocked: false,
        ),
      ],
    );
  }

  Widget _buildRewardTile({
    required String emoji,
    required String title,
    required String description,
    required bool unlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.goldColor.withValues(alpha: 0.04)
            : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppTheme.goldColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Text(emoji,
              style: TextStyle(
                  fontSize: 28,
                  color: unlocked ? null : Colors.white.withValues(alpha: 0.3))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.darkTextSec,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Unlocked',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
              ),
            )
          else
            Icon(Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.15), size: 20),
        ],
      ),
    );
  }
}
