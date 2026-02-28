import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/providers/auth_provider.dart';
import 'package:monojog/providers/locale_provider.dart';
import 'package:monojog/screens/statistics_screen.dart';
import 'package:monojog/screens/rewards_screen.dart';
import 'package:monojog/screens/settings_screen.dart';
import 'package:monojog/widgets/neu_container.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<GameProvider, AuthProvider, LocaleProvider>(
      builder: (ctx, game, auth, locale, _) {
        final profile = game.profile;

        return Column(
          children: [
            // Profile Summary Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: NeuContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _avatarEmoji(profile.avatarType),
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user?.displayName ??
                                (auth.isOfflineMode
                                    ? (locale.isBengali
                                        ? 'Offline User'
                                        : 'Offline User')
                                    : (locale.isBengali ? 'Guest' : 'Guest')),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.military_tech_rounded,
                                  color: AppTheme.goldColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                locale.isBengali
                                    ? profile.levelTitleBengali
                                    : profile.levelTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lv. ${profile.level}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Settings & Logout
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                        if (!auth.isOfflineMode)
                          IconButton(
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white70, size: 20),
                            onPressed: () => _showLogoutDialog(auth, locale),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NeuContainer(
                borderRadius: BorderRadius.circular(16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor:
                      isDark ? AppTheme.darkTextSec : AppTheme.lightTextSec,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.bar_chart_rounded, size: 20),
                      text: locale.t('statistics'),
                    ),
                    const Tab(
                      icon: Icon(Icons.emoji_events_rounded, size: 20),
                      text: 'Forest Rewards',
                    ),
                  ],
                ),
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  StatisticsScreen(),
                  RewardsScreen(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(AuthProvider auth, LocaleProvider locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.isBengali ? 'Logout' : 'Logout'),
        content: Text(locale.isBengali
            ? 'Are you sure you want to logout?'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(locale.t('yes')),
          ),
        ],
      ),
    );
  }

  String _avatarEmoji(String type) {
    switch (type) {
      case 'mage':
        return '🧙';
      case 'healer':
        return '🧝';
      case 'rogue':
        return '🥷';
      default:
        return '⚔️';
    }
  }
}
