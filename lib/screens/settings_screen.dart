import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _handleDeleteAccount(String password) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.deleteAccount(password: password);
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } else {
      _showErrorSnackbar(
        authProvider.error ?? 'Account deletion failed. Please try again.',
      );
    }
  }

  void _showSignOutDialog(bool isDark) {
    final locale = context.read<LocaleProvider>();
    final bgColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecColor = isDark ? AppTheme.darkTextSec : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          locale.isBengali ? 'লগআউট করবেন?' : 'Sign Out?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
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
            child: Text('Cancel', style: TextStyle(color: textSecColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              locale.isBengali ? 'লগআউট' : 'Sign Out',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    final locale = context.read<LocaleProvider>();
    final auth = context.read<AuthProvider>();
    final bgColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecColor = isDark ? AppTheme.darkTextSec : Colors.grey.shade600;
    final passwordController = TextEditingController();
    bool obscure = true;

    final isGoogleUser =
        auth.user?.providerData.any((p) => p.providerId == 'google.com') ??
            false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            locale.isBengali
                ? 'অ্যাকাউন্ট মুছে ফেলবেন?'
                : 'Delete Account?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isBengali
                    ? 'এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।'
                    : 'This cannot be undone. Your account will be permanently deleted.',
                style: TextStyle(color: textSecColor, fontSize: 13),
              ),
              if (!isGoogleUser) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  cursorColor: isDark ? Colors.white : Colors.black,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: locale.isBengali
                        ? 'পাসওয়ার্ড নিশ্চিত করুন'
                        : 'Confirm your password',
                    labelStyle: TextStyle(color: textSecColor, fontSize: 13),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: textSecColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
              if (isGoogleUser) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locale.isBengali
                            ? 'Google দিয়ে পুনরায় সাইন ইন করতে বলা হবে।'
                            : 'You will be asked to re-authenticate with Google.',
                        style: const TextStyle(
                            color: AppTheme.primaryColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textSecColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleDeleteAccount(
                    isGoogleUser ? '' : passwordController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                locale.isBengali ? 'মুছে ফেলুন' : 'Delete',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.black : Colors.white)),
          backgroundColor: isDark ? Colors.white : Colors.black,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _avatarEmoji(String type) {
    switch (type) {
      case 'mage':   return '🧙';
      case 'healer': return '🧑‍⚕️';
      case 'rogue':  return '🥷';
      default:       return '⚔️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final focus = context.watch<FocusProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive colors — light mode এ dark mode এর মতো স্পষ্ট ──────────
    final bgColor      = isDark ? AppTheme.darkBg     : const Color(0xFFF0EFF8);
    final cardBg       = isDark ? AppTheme.darkCard    : Colors.white;
    final textColor    = isDark ? Colors.white         : const Color(0xFF1A1A2E);
    final textSecColor = isDark ? AppTheme.darkTextSec : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.white10       : Colors.grey.shade200;
    final iconColor    = isDark ? AppTheme.primaryColor : const Color(0xFF5C35D4);
    final sectionColor = isDark ? AppTheme.primaryColor : const Color(0xFF5C35D4);

    final currentThemeLabel = switch (themeProvider.themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      _ => 'System default',
    };

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          locale.isBengali ? 'সেটিংস' : 'Settings',
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

          // ── Profile ────────────────────────────────────────────────
          _sectionTitle(
              locale.isBengali ? 'প্রোফাইল' : 'Profile',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar — auth.avatarType থেকে emoji দেখাবে
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _avatarEmoji(auth.avatarType),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.displayName ??
                              (auth.isOfflineMode
                                  ? (locale.isBengali
                                  ? 'অফলাইন ব্যবহারকারী'
                                  : 'Offline User')
                                  : 'Guest'),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          auth.user?.email ??
                              (auth.isOfflineMode
                                  ? (locale.isBengali
                                  ? 'লোকাল ডিভাইস সেশন'
                                  : 'Local device session')
                                  : (locale.isBengali
                                  ? 'কোনো ইমেইল নেই'
                                  : 'No email connected')),
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
                    label: Text(
                      locale.isBengali ? 'লগআউট' : 'Sign out',
                      style:
                      const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Appearance ─────────────────────────────────────────────
          _sectionTitle(
              locale.isBengali ? 'অ্যাপিয়ারেন্স' : 'Appearance',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: ListTile(
              leading: Icon(
                isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: iconColor,
              ),
              title: Text(locale.isBengali ? 'থিম' : 'Theme',
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.w600)),
              subtitle: Text(currentThemeLabel,
                  style:
                  TextStyle(color: textSecColor, fontSize: 12)),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'Light',
                      icon: Icon(Icons.light_mode_rounded, size: 16)),
                  ButtonSegment(
                      value: 'System default',
                      icon: Icon(
                          Icons.brightness_auto_rounded, size: 16)),
                  ButtonSegment(
                      value: 'Dark',
                      icon: Icon(Icons.dark_mode_rounded, size: 16)),
                ],
                selected: {currentThemeLabel},
                onSelectionChanged: (value) =>
                    themeProvider.changeTheme(value.first),
                style: ButtonStyle(
                  side: WidgetStateProperty.all(BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey.shade300,
                  )),
                  foregroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                        ? Colors.white
                        : textSecColor,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                        ? iconColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── App Experience ─────────────────────────────────────────
          _sectionTitle(
              locale.isBengali
                  ? 'অ্যাপ অভিজ্ঞতা'
                  : 'App Experience',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded,
                      color: iconColor),
                  title: Text(
                      locale.isBengali ? 'ভাষা' : 'Language',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    locale.isBengali ? 'বাংলা' : 'English',
                    style: TextStyle(color: textSecColor),
                  ),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'en', label: Text('EN')),
                      ButtonSegment(
                          value: 'bn', label: Text('BN')),
                    ],
                    selected: {locale.locale},
                    onSelectionChanged: (value) => context
                        .read<LocaleProvider>()
                        .setLocale(value.first),
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                      )),
                      foregroundColor:
                      WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : textSecColor,
                      ),
                      backgroundColor:
                      WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                            ? iconColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),

                Divider(height: 1, color: dividerColor),

                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    setState(() => _notificationsEnabled = v);
                    await _saveBool('settings.notifications', v);
                  },
                  title: Text(
                      locale.isBengali
                          ? 'নোটিফিকেশন'
                          : 'Notifications',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'রিমাইন্ডার ও ফোকাস অ্যালার্ট'
                          : 'Reminder and focus alerts',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: iconColor),
                  activeColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),

                Divider(height: 1, color: dividerColor),

                SwitchListTile(
                  value: _hapticsEnabled,
                  onChanged: (v) async {
                    setState(() => _hapticsEnabled = v);
                    await _saveBool('settings.haptics', v);
                  },
                  title: Text(
                      locale.isBengali
                          ? 'হ্যাপটিক্স'
                          : 'Haptics',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'স্পর্শ ফিডব্যাক এবং ভাইব্রেশন'
                          : 'Touch feedback and vibration',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.vibration_rounded,
                      color: iconColor),
                  activeThumbColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Focus Engine ───────────────────────────────────────────
          _sectionTitle(
              locale.isBengali ? 'ফোকাস ইঞ্জিন' : 'Focus Engine',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              children: [
                SwitchListTile(
                  value: focus.isStrictMode,
                  onChanged: focus.setStrictMode,
                  title: Text(
                      locale.isBengali
                          ? 'স্ট্রিক্ট মোড'
                          : 'Strict Mode',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'জোর না করলে ফোকাস আগে শেষ করা যাবে না'
                          : 'Prevents ending focus early without force',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.lock_clock_rounded,
                      color: iconColor),
                  activeColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),
                Divider(height: 1, color: dividerColor),
                SwitchListTile(
                  value: focus.blockAllApps,
                  onChanged: focus.setBlockAllApps,
                  title: Text(
                      locale.isBengali
                          ? 'সব অ্যাপ ব্লক করুন'
                          : 'Block all apps',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'গভীর কাজের জন্য সর্বোচ্চ ফোকাস মোড'
                          : 'Max focus mode for deep work',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.block_rounded,
                      color: iconColor),
                  activeColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),
                Divider(height: 1, color: dividerColor),
                SwitchListTile(
                  value: focus.enableDND,
                  onChanged: focus.setEnableDND,
                  title: Text(
                      locale.isBengali
                          ? 'ফোকাসে DND চালু করুন'
                          : 'Enable DND during focus',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'পড়ার সময় নোটিফিকেশন বন্ধ করুন'
                          : 'Silence notifications while studying',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(
                      Icons.do_not_disturb_alt_rounded,
                      color: iconColor),
                  activeColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),
                Divider(height: 1, color: dividerColor),
                _sliderTile(
                  icon: Icons.timelapse_rounded,
                  iconColor: iconColor,
                  title: locale.isBengali
                      ? 'ডিফল্ট ফোকাস সময়'
                      : 'Default focus duration',
                  subtitle: locale.isBengali
                      ? '${focus.targetMinutes} মিনিট'
                      : '${focus.targetMinutes} minutes',
                  value:
                  focus.targetMinutes.toDouble().clamp(15, 120),
                  min: 15,
                  max: 120,
                  divisions: 21,
                  label: '${focus.targetMinutes}m',
                  onChanged: (v) =>
                      focus.setTargetMinutes(v.round()),
                  textColor: textColor,
                  textSecColor: textSecColor,
                ),
                Divider(height: 1, color: dividerColor),
                _sliderTile(
                  icon: Icons.free_breakfast_rounded,
                  iconColor: iconColor,
                  title: locale.isBengali
                      ? 'ছোট বিরতির সময়'
                      : 'Short break duration',
                  subtitle: locale.isBengali
                      ? '${focus.shortBreakMinutes} মিনিট'
                      : '${focus.shortBreakMinutes} minutes',
                  value: focus.shortBreakMinutes
                      .toDouble()
                      .clamp(3, 30),
                  min: 3,
                  max: 30,
                  divisions: 9,
                  label: '${focus.shortBreakMinutes}m',
                  onChanged: (v) =>
                      focus.setShortBreakMinutes(v.round()),
                  textColor: textColor,
                  textSecColor: textSecColor,
                ),
                Divider(height: 1, color: dividerColor),
                _sliderTile(
                  icon: Icons.nights_stay_rounded,
                  iconColor: iconColor,
                  title: locale.isBengali
                      ? 'লম্বা বিরতির সময়'
                      : 'Long break duration',
                  subtitle: locale.isBengali
                      ? '${focus.longBreakMinutes} মিনিট'
                      : '${focus.longBreakMinutes} minutes',
                  value: focus.longBreakMinutes
                      .toDouble()
                      .clamp(10, 60),
                  min: 10,
                  max: 60,
                  divisions: 10,
                  label: '${focus.longBreakMinutes}m',
                  onChanged: (v) =>
                      focus.setLongBreakMinutes(v.round()),
                  textColor: textColor,
                  textSecColor: textSecColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Android Home Widget ────────────────────────────────────
          _sectionTitle(
              locale.isBengali
                  ? 'অ্যান্ড্রয়েড হোম উইজেট'
                  : 'Android Home Widget',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              children: [
                SwitchListTile(
                  value: _showSecondsInWidget,
                  onChanged: (v) async {
                    final fp = context.read<FocusProvider>();
                    setState(() => _showSecondsInWidget = v);
                    await _saveBool('settings.widget_seconds', v);
                    await fp.refreshHomeWidget();
                  },
                  title: Text(
                      locale.isBengali
                          ? 'উইজেটে সেকেন্ড দেখান'
                          : 'Show seconds in widget',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'MM:SS লাইভ কাউন্টডাউন দেখান'
                          : 'Display MM:SS live-like countdown text',
                      style: TextStyle(color: textSecColor)),
                  secondary: Icon(Icons.widgets_rounded,
                      color: iconColor),
                  activeColor: isDark?  AppTheme.primaryColor : Colors.teal,
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: Icon(Icons.refresh_rounded,
                      color: iconColor),
                  title: Text(
                      locale.isBengali
                          ? 'উইজেট রিফ্রেশ করুন'
                          : 'Refresh widget now',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      locale.isBengali
                          ? 'হোম স্ক্রিনে সর্বশেষ ফোকাস স্টেট পাঠান'
                          : 'Push latest focus state to Android home screen',
                      style: TextStyle(color: textSecColor)),
                  onTap: () async {
                    final fp = context.read<FocusProvider>();
                    final messenger =
                    ScaffoldMessenger.of(context);
                    await fp.refreshHomeWidget();
                    if (!context.mounted) return;
                    _showErrorSnackbar(locale.isBengali
                        ? 'উইজেট রিফ্রেশ হয়েছে'
                        : 'Widget refreshed');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Data & Safety ──────────────────────────────────────────
          _sectionTitle(
              locale.isBengali
                  ? 'ডেটা ও নিরাপত্তা'
                  : 'Data & Safety',
              sectionColor),
          _card(
            isDark: isDark,
            cardBg: cardBg,
            child: ListTile(
              leading: Icon(Icons.restart_alt_rounded,
                  color: Colors.orange.shade700),
              title: Text(
                  locale.isBengali
                      ? 'সব লোকাল ডেটা মুছুন'
                      : 'Reset all local data',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                  locale.isBengali
                      ? 'অভ্যাস, পুরস্কার এবং অগ্রগতি মুছে যাবে'
                      : 'Removes habits, rewards, and progress',
                  style: TextStyle(color: textSecColor)),
              onTap: () => _showResetDialog(context, isDark),
            ),
          ),

          const SizedBox(height: 20),

          // ── Bottom Action Button ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (auth.isOfflineMode) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                } else {
                  _showDeleteAccountDialog(isDark);
                }
              },
              icon: Icon(
                auth.isOfflineMode
                    ? Icons.person_add_rounded
                    : Icons.delete_forever_rounded,
                size: 20,
              ),
              label: Text(
                auth.isOfflineMode
                    ? (locale.isBengali
                    ? 'অ্যাকাউন্ট তৈরি করুন'
                    : 'Create Account')
                    : (locale.isBengali
                    ? 'অ্যাকাউন্ট মুছুন'
                    : 'Delete Account'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: auth.isOfflineMode
                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                    : Colors.redAccent.withValues(alpha: 0.12),
                foregroundColor: auth.isOfflineMode
                    ? AppTheme.primaryColor
                    : Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: auth.isOfflineMode
                        ? AppTheme.primaryColor
                        .withValues(alpha: 0.4)
                        : Colors.redAccent.withValues(alpha: 0.4),
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

  // ── Card wrapper ─────────────────────────────────────────────────────────
  Widget _card({
    required bool isDark,
    required Color cardBg,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Slider tile helper ────────────────────────────────────────────────────
  Widget _sliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required Color textColor,
    required Color textSecColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style:
          TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: textSecColor)),
      trailing: SizedBox(
        width: 130,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Reset Dialog ──────────────────────────────────────────────────────────
  void _showResetDialog(BuildContext context, bool isDark) {
    final locale = context.read<LocaleProvider>();
    final bgColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecColor =
    isDark ? AppTheme.darkTextSec : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          locale.isBengali ? 'সব ডেটা মুছবেন?' : 'Delete all data?',
          style:
          TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        content: Text(
          locale.isBengali
              ? 'এটি আপনার লোকাল প্রোফাইল, পুরস্কার, অভ্যাস এবং অগ্রগতি মুছে দেবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।'
              : 'This will erase your local profile, rewards, habits, and progress. This cannot be undone.',
          style: TextStyle(color: textSecColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            Text('Cancel', style: TextStyle(color: textSecColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final gameProvider = context.read<GameProvider>();
              Navigator.pop(ctx);
              await gameProvider.resetAllData();
              if (!context.mounted) return;
              _showErrorSnackbar(locale.isBengali
                  ? 'সব ডেটা মুছে ফেলা হয়েছে।'
                  : 'All data has been deleted.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              locale.isBengali ? 'মুছুন' : 'Delete',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}