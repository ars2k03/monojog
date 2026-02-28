import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monojog/providers/auth_provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/providers/locale_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/widgets/neu_container.dart';
import 'package:monojog/start_page/login_screen.dart';

import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  bool _showSecondsInWidget = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('settings.notifications') ?? true;
      _hapticsEnabled = prefs.getBool('settings.haptics') ?? true;
      _showSecondsInWidget = prefs.getBool('settings.widget_seconds') ?? true;
      _loading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _handleSignOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showSignOutDialog(bool isDark) {
    final locale = context.read<LocaleProvider>();
    final bgColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textSecColor = isDark ? AppTheme.darkTextSec : AppTheme.lightTextSec;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          locale.isBengali ? 'লগআউট করবেন?' : 'Sign Out?',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          locale.isBengali
              ? 'আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'
              : 'Are you sure you want to sign out?',
          style: TextStyle(color: textSecColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              locale.isBengali ? 'না' : 'Cancel',
              style: TextStyle(color: textSecColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              locale.isBengali ? 'লগআউট' : 'Sign Out',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final focus = context.watch<FocusProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // ── Theme-aware colors ───────────────────────────────────────────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final textSecColor = isDark ? AppTheme.darkTextSec : AppTheme.lightTextSec;
    final iconColor = isDark ? AppTheme.primaryColor : AppTheme.secondaryColor;

    // Current theme label for SegmentedButton
    final currentThemeLabel = switch (themeProvider.themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      _ => 'System default',
    };

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Profile Section ────────────────────────────────────
          _sectionTitle('Profile'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.16),
                  child: const Icon(Icons.person_rounded,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.displayName ??
                            (auth.isOfflineMode
                                ? 'Offline User'
                                : 'Guest'),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.email ??
                            (auth.isOfflineMode
                                ? 'Local device session'
                                : 'No email connected'),
                        style: TextStyle(
                          color: textSecColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSignOutDialog(isDark),
                  icon: const Icon(Icons.logout_rounded,
                      size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Appearance Section ─────────────────────────────────
          _sectionTitle('Appearance'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
              leading: Icon(
                isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: iconColor,
              ),
              title: Text('Theme',
                  style: TextStyle(color: textColor)),
              subtitle: Text(currentThemeLabel,
                  style: TextStyle(color: textSecColor, fontSize: 12)),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Light',
                    icon: Icon(Icons.light_mode_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'System default',
                    icon: Icon(Icons.brightness_auto_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'Dark',
                    icon: Icon(Icons.dark_mode_rounded, size: 16),
                  ),
                ],
                selected: {currentThemeLabel},
                onSelectionChanged: (value) {
                  themeProvider.changeTheme(value.first);
                },
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: isDark
                          ? AppTheme.darkTextSec.withValues(alpha: 0.3)
                          : AppTheme.lightTextSec.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── App Experience Section ─────────────────────────────
          _sectionTitle('App Experience'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded,
                      color: iconColor),
                  title: Text('Language',
                      style: TextStyle(color: textColor)),
                  subtitle: Text(
                    locale.isBengali ? 'Bengali' : 'English',
                    style: TextStyle(color: textSecColor),
                  ),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('EN')),
                      ButtonSegment(value: 'bn', label: Text('BN')),
                    ],
                    selected: {locale.locale},
                    onSelectionChanged: (value) {
                      locale.setLocale(value.first);
                    },
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    setState(() => _notificationsEnabled = v);
                    await _saveBool('settings.notifications', v);
                  },
                  title: Text('Notifications',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('Reminder and focus alerts',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: iconColor),
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                SwitchListTile(
                  value: _hapticsEnabled,
                  onChanged: (v) async {
                    setState(() => _hapticsEnabled = v);
                    await _saveBool('settings.haptics', v);
                  },
                  title: Text('Haptics',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('Touch feedback and vibration',
                      style: TextStyle(color: textSecColor)),
                  secondary:
                  Icon(Icons.vibration_rounded, color: iconColor),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Focus Engine Section ───────────────────────────────
          _sectionTitle('Focus Engine'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                SwitchListTile(
                  value: focus.isStrictMode,
                  onChanged: focus.setStrictMode,
                  title: Text('Strict Mode',
                      style: TextStyle(color: textColor)),
                  subtitle: Text(
                      'Prevents ending focus early without force',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.lock_clock_rounded,
                      color: AppTheme.accentPurple),
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                SwitchListTile(
                  value: focus.blockAllApps,
                  onChanged: focus.setBlockAllApps,
                  title: Text('Block all apps',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('Max focus mode for deep work',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.block_rounded,
                      color: AppTheme.accentPurple),
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                SwitchListTile(
                  value: focus.enableDND,
                  onChanged: focus.setEnableDND,
                  title: Text('Enable DND during focus',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('Silence notifications while studying',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.do_not_disturb_alt_rounded,
                      color: AppTheme.accentPurple),
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                ListTile(
                  leading: Icon(Icons.timelapse_rounded,
                      color: AppTheme.accentPurple),
                  title: Text('Default focus duration',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('${focus.targetMinutes} minutes',
                      style: TextStyle(color: textSecColor)),
                  trailing: SizedBox(
                    width: 130,
                    child: Slider(
                      value: focus.targetMinutes
                          .toDouble()
                          .clamp(15, 120),
                      min: 15,
                      max: 120,
                      divisions: 21,
                      label: '${focus.targetMinutes}m',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) =>
                          focus.setTargetMinutes(v.round()),
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                ListTile(
                  leading: Icon(Icons.free_breakfast_rounded,
                      color: AppTheme.accentPurple),
                  title: Text('Short break duration',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('${focus.shortBreakMinutes} minutes',
                      style: TextStyle(color: textSecColor)),
                  trailing: SizedBox(
                    width: 130,
                    child: Slider(
                      value: focus.shortBreakMinutes
                          .toDouble()
                          .clamp(3, 30),
                      min: 3,
                      max: 30,
                      divisions: 9,
                      label: '${focus.shortBreakMinutes}m',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) =>
                          focus.setShortBreakMinutes(v.round()),
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                ListTile(
                  leading: Icon(Icons.nights_stay_rounded,
                      color: AppTheme.accentPurple),
                  title: Text('Long break duration',
                      style: TextStyle(color: textColor)),
                  subtitle: Text('${focus.longBreakMinutes} minutes',
                      style: TextStyle(color: textSecColor)),
                  trailing: SizedBox(
                    width: 130,
                    child: Slider(
                      value: focus.longBreakMinutes
                          .toDouble()
                          .clamp(10, 60),
                      min: 10,
                      max: 60,
                      divisions: 10,
                      label: '${focus.longBreakMinutes}m',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) =>
                          focus.setLongBreakMinutes(v.round()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Android Home Widget Section ────────────────────────
          _sectionTitle('Android Home Widget'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                SwitchListTile(
                  value: _showSecondsInWidget,
                  onChanged: (v) async {
                    final focusProvider =
                    context.read<FocusProvider>();
                    setState(() => _showSecondsInWidget = v);
                    await _saveBool('settings.widget_seconds', v);
                    await focusProvider.refreshHomeWidget();
                  },
                  title: Text('Show seconds in widget',
                      style: TextStyle(color: textColor)),
                  subtitle: Text(
                      'Display MM:SS live-like countdown text',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.widgets_rounded,
                      color: AppTheme.accentPurple),
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black12),
                ListTile(
                  leading: Icon(Icons.refresh_rounded,
                      color: AppTheme.accentPurple),
                  title: Text('Refresh widget now',
                      style: TextStyle(color: textColor)),
                  subtitle: Text(
                      'Push latest focus state to Android home screen',
                      style: TextStyle(color: textSecColor)),
                  onTap: () async {
                    final focusProvider =
                    context.read<FocusProvider>();
                    final messenger =
                    ScaffoldMessenger.of(context);
                    await focusProvider.refreshHomeWidget();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Widget refreshed')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Data & Safety Section ──────────────────────────────
          _sectionTitle('Data & Safety'),
          NeuContainer(
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
              leading: const Icon(Icons.restart_alt_rounded,
                  color: AppTheme.warningColor),
              title: Text('Reset all local data',
                  style: TextStyle(color: textColor)),
              subtitle: Text(
                  'Removes habits, rewards, and progress',
                  style: TextStyle(color: textSecColor)),
              onTap: () => _showResetDialog(context, isDark),
            ),
          ),

          const SizedBox(height: 20),

          // ── Sign Out Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutDialog(isDark),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                auth.isOfflineMode ? 'Go to Login' : 'Sign Out',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                    Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Reset Dialog ─────────────────────────────────────────────────────────
  void _showResetDialog(BuildContext context, bool isDark) {
    final bgColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final textSecColor =
    isDark ? AppTheme.darkTextSec : AppTheme.lightTextSec;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete all data?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will erase your local profile, rewards, habits, and progress. This cannot be undone.',
          style: TextStyle(color: textSecColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSecColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final gameProvider = context.read<GameProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await gameProvider.resetAllData();
              if (!context.mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('All local data deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}