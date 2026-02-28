import 'package:flutter/material.dart';
import 'package:monojog/theme/app_theme.dart';
import 'home_screen.dart';
import 'my_day_screen.dart';
import 'focus_screen.dart';
import 'sleep_screen.dart';
import 'study_room_screen.dart';
import 'garden_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      const MyDayScreen(),
      const FocusScreen(),
      const SleepScreen(),
      const StudyRoomScreen(),
      const GardenScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', isDark),
              _navItem(1, Icons.check_circle_outline, Icons.check_circle_rounded, 'Todo', isDark),
              _navItem(2, Icons.rocket_launch_outlined, Icons.rocket_launch_rounded, 'Focus', isDark),
              _navItem(3, Icons.nightlight_outlined, Icons.nightlight_rounded, 'Sleep', isDark),
              _navItem(4, Icons.meeting_room_outlined, Icons.meeting_room_rounded, 'Room', isDark),
              _navItem(5, Icons.eco_outlined, Icons.eco_rounded, 'Garden', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isDark ? AppTheme.primaryColor : const Color(0xFF1A1A2E);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? color
                    : isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? color
                      : isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}