import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:monojog/models/focus_session.dart';
import 'package:monojog/models/blocked_app.dart';
import 'package:monojog/services/database_service.dart';
import 'package:monojog/services/history_service.dart';

/// Unified focus intensity levels
enum FocusLevel {
  light,    // 1 - DND only: silence all notifications
  moderate, // 2 - Block reels/ads in social media + block selected apps
  deep,     // 3 - Block ALL installed apps
  strict,   // 4 - Block everything + cannot quit + only emergency calls
}

extension FocusLevelX on FocusLevel {
  String get label {
    switch (this) {
      case FocusLevel.light:    return 'Light Focus';
      case FocusLevel.moderate: return 'Focused';
      case FocusLevel.deep:     return 'Deep Focus';
      case FocusLevel.strict:   return 'Strict Mode';
    }
  }

  String get subtitle {
    switch (this) {
      case FocusLevel.light:    return 'Silence all notifications';
      case FocusLevel.moderate: return 'Block distracting apps & reels';
      case FocusLevel.deep:     return 'Block every app on your phone';
      case FocusLevel.strict:   return 'Locked in — only emergencies';
    }
  }

  String get emoji {
    switch (this) {
      case FocusLevel.light:    return '🔔';
      case FocusLevel.moderate: return '🛡️';
      case FocusLevel.deep:     return '🔒';
      case FocusLevel.strict:   return '⛔';
    }
  }

  Color get color {
    switch (this) {
      case FocusLevel.light:    return const Color(0xFF7C4DFF);
      case FocusLevel.moderate: return const Color(0xFF00E5FF);
      case FocusLevel.deep:     return const Color(0xFFFF6B35);
      case FocusLevel.strict:   return const Color(0xFFFF4D6D);
    }
  }

  IconData get icon {
    switch (this) {
      case FocusLevel.light:    return Icons.notifications_off_rounded;
      case FocusLevel.moderate: return Icons.shield_rounded;
      case FocusLevel.deep:     return Icons.lock_rounded;
      case FocusLevel.strict:   return Icons.block_rounded;
    }
  }

  List<String> get features {
    switch (this) {
      case FocusLevel.light:
        return [
          'Turn off all notifications (DND)',
          'No app blocking — honor system',
          'Can stop session anytime',
        ];
      case FocusLevel.moderate:
        return [
          'Do Not Disturb enabled',
          'Block Facebook & YouTube reels/shorts',
          'Block apps you select',
          'Can stop session anytime',
        ];
      case FocusLevel.deep:
        return [
          'Do Not Disturb enabled',
          'ALL apps blocked — only Monojog runs',
          'Full-screen overlay on any blocked app',
          'Can stop session anytime',
        ];
      case FocusLevel.strict:
        return [
          'Everything from Deep Focus',
          'Cannot stop session until timer ends',
          'Only emergency calls come through',
          'Anti-cheat penalties active',
        ];
    }
  }
}

class FocusProvider with ChangeNotifier, WidgetsBindingObserver {
  static const platform = MethodChannel('com.monojog.app/focus');
  static const MethodChannel _blockChannel =
  MethodChannel("com.monojog.app/blocker");

  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  bool _hasAccessibilityPermission = false;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;

  FocusSession? _currentFocusSession;
  List<BlockedApp> _blockedApps = [];
  List<InstalledApp> _installedApps = [];
  Timer? _focusTimer;
  int _remainingSeconds = 0;
  int _targetMinutes = 25;
  bool _isFocusActive = false;
  bool _hasUsagePermission = false;
  bool _hasOverlayPermission = false;

  // -- Unified Focus Level --
  FocusLevel _focusLevel = FocusLevel.moderate;
  bool _showBreathing = true;
  bool _allowEmergencyCalls = true;

  // -- DND: user এর উপর নির্ভর --
  bool _enableDND = true;

  int _pomodoroCount = 0;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsSinceLongBreak = 0;
  bool _isOnBreak = false;
  bool _isPaused = false;

  // Anti-cheat
  DateTime? _lastActivityTime;
  final int _idleThresholdSeconds = 60;
  final int _idlePenaltySeconds = 10;
  final int _appSwitchPenaltySeconds = 30;
  int _totalPenaltySeconds = 0;
  bool _appInBackground = false;

  // -- Getters --
  FocusSession? get currentFocusSession => _currentFocusSession;
  List<BlockedApp> get blockedApps => _blockedApps;
  List<InstalledApp> get installedApps => _installedApps;
  int get remainingSeconds => _remainingSeconds;
  int get targetMinutes => _targetMinutes;
  bool get isFocusActive => _isFocusActive;
  bool get hasUsagePermission => _hasUsagePermission;
  bool get hasOverlayPermission => _hasOverlayPermission;

  FocusLevel get focusLevel => _focusLevel;
  bool get showBreathing => _showBreathing;
  bool get allowEmergencyCalls => _allowEmergencyCalls;

  // ── DND getter: এখন user controllable ──
  bool get enableDND => _enableDND;

  // Derived from focus level
  bool get isStrictMode => _focusLevel == FocusLevel.strict;
  bool get blockAllApps =>
      _focusLevel == FocusLevel.deep || _focusLevel == FocusLevel.strict;

  int get pomodoroCount => _pomodoroCount;
  int get breakMinutes => _shortBreakMinutes;
  bool get isOnBreak => _isOnBreak;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  bool get isPaused => _isPaused;
  int get totalPenaltySeconds => _totalPenaltySeconds;
  bool get appInBackground => _appInBackground;
  int get idleThresholdSeconds => _idleThresholdSeconds;
  int get appSwitchPenaltySeconds => _appSwitchPenaltySeconds;

  bool get isSessionRunning => _isFocusActive || _isOnBreak;

  /// Global session type currently active (for cross-provider sync)
  static String? _globalActiveSession;
  static String? get globalActiveSession => _globalActiveSession;
  static bool get isAnySessionActive => _globalActiveSession != null;
  static void claimSession(String type) => _globalActiveSession = type;
  static void releaseSession(String type) {
    if (_globalActiveSession == type) _globalActiveSession = null;
  }

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (_targetMinutes == 0) return 0;
    final totalSeconds = _targetMinutes * 60;
    final elapsed = totalSeconds - _remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  int get elapsedMinutes {
    if (_targetMinutes == 0) return 0;
    final totalSeconds = _targetMinutes * 60;
    final elapsed = totalSeconds - _remainingSeconds;
    return elapsed ~/ 60;
  }


  Future<void> _saveBlockedAppsToNative() async {
    try {
      final blockedPackages =
      _blockedApps.map((app) => app.packageName).toList();

      await _blockChannel.invokeMethod(
        "saveBlockedApps",
        blockedPackages,
      );
    } catch (e) {
      debugPrint("Failed to save blocked apps: $e");
    }
  }

  // -- Setters --
  void setFocusLevel(FocusLevel level) {
    _focusLevel = level;
    _saveSettings();
    notifyListeners();
  }

  void setShowBreathing(bool v) {
    _showBreathing = v;
    _saveSettings();
    notifyListeners();
  }

  void setAllowEmergencyCalls(bool v) {
    _allowEmergencyCalls = v;
    _saveSettings();
    notifyListeners();
  }

  // ── DND setter: এখন user on/off করতে পারবে ──
  void setEnableDND(bool v) {
    _enableDND = v;
    _saveSettings();
    notifyListeners();
  }

  void setTargetMinutes(int minutes) {
    _targetMinutes = minutes.clamp(1, 1440);
    _remainingSeconds = minutes * 60;
    _saveSettings();
    _syncAndroidWidget();
    notifyListeners();
  }

  void setShortBreakMinutes(int v) {
    _shortBreakMinutes = v.clamp(1, 30);
    _saveSettings();
    notifyListeners();
  }

  void setLongBreakMinutes(int v) {
    _longBreakMinutes = v.clamp(5, 60);
    _saveSettings();
    notifyListeners();
  }

  // -- Backward compat stubs --
  void setStrictMode(bool v) =>
      setFocusLevel(v ? FocusLevel.strict : FocusLevel.moderate);
  void setBlockAllApps(bool v) =>
      setFocusLevel(v ? FocusLevel.deep : FocusLevel.moderate);
  void setBreakMinutes(int v) => setShortBreakMinutes(v);

  FocusProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSettings();
    await _loadBlockedApps();
    await checkPermissions();
    await loadInstalledApps();
    await _syncAndroidWidget();
  }

  Future<void> checkPermissions() async {
    try {
      final result = await platform.invokeMethod('checkPermissions');
      _hasUsagePermission = result['hasUsagePermission'] ?? false;
      _hasOverlayPermission = result['hasOverlayPermission'] ?? false;
      _hasAccessibilityPermission =
          result['hasAccessibilityPermission'] ?? false;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('Failed to check permissions: ${e.message}');
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } on PlatformException catch (e) {
      debugPrint('Failed to request usage permission: ${e.message}');
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } on PlatformException catch (e) {
      debugPrint('Failed to request overlay permission: ${e.message}');
    }
  }

  Future<void> loadInstalledApps() async {
    try {
      final result = await platform.invokeMethod('getInstalledApps');
      final List<dynamic> apps = result ?? [];

      _installedApps = apps
          .map((app) =>
          InstalledApp.fromMap(Map<String, dynamic>.from(app)))
          .toList()
        ..sort((a, b) =>
            a.appName.toLowerCase()
                .compareTo(b.appName.toLowerCase()));

      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('Failed to load installed apps: ${e.message}');
    }
  }

  Future<void> _loadBlockedApps() async {
    final apps = await _db.getAllAppsInBlockList();
    _blockedApps = apps.map((a) => BlockedApp.fromMap(a)).toList();
    notifyListeners();
  }

  Future<void> addBlockedApp(InstalledApp app) async {
    final existing = _blockedApps.any((b) => b.packageName == app.packageName);

    if (existing) {
      await _db.updateBlockedApp(app.packageName, true);
    } else {
      final blockedApp = BlockedApp(
        id: _uuid.v4(),
        packageName: app.packageName,
        appName: app.appName,
        isBlocked: true,
      );
      await _db.insertBlockedApp(blockedApp.toMap());
    }

    await _loadBlockedApps();

    await _saveBlockedAppsToNative();   // 👈 এটা যোগ করো
  }

  Future<void> removeBlockedApp(String packageName) async {
    await _db.deleteBlockedApp(packageName);
    await _loadBlockedApps();

    await _saveBlockedAppsToNative();   // 👈 এটা যোগ করো
  }

  Future<void> toggleBlockedApp(String packageName, bool isBlocked) async {
    if (!isBlocked) {
      await _db.deleteBlockedApp(packageName);
    } else {
      await _db.updateBlockedApp(packageName, isBlocked);
    }

    await _loadBlockedApps();

    await _saveBlockedAppsToNative();   // 👈 এটা যোগ করো
  }

  List<String> _resolveBlockedApps() {
    switch (_focusLevel) {
      case FocusLevel.light:
        return [];

      case FocusLevel.moderate:
        final userApps = _blockedApps
            .where((app) => app.isBlocked)
            .map((app) => app.packageName)
            .toList();
        const socialMediaPkgs = [
          'com.facebook.katana',
          'com.facebook.lite',
          'com.facebook.orca',
          'com.instagram.android',
          'com.google.android.youtube',
          'com.zhiliaoapp.musically',
          'com.ss.android.ugc.trill',
          'com.snapchat.android',
          'com.twitter.android',
          'com.reddit.frontpage',
        ];
        for (final pkg in socialMediaPkgs) {
          if (!userApps.contains(pkg)) userApps.add(pkg);
        }
        return userApps;

      case FocusLevel.deep:
      case FocusLevel.strict:
        return _installedApps.map((app) => app.packageName).toList();
    }
  }

  Future<bool> startFocusSession() async {
    if (!_hasAccessibilityPermission) {
      await platform.invokeMethod('openAccessibilitySettings');

      // Wait for user to come back
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();

      if (!_hasAccessibilityPermission) {
        return false;
      }
    }

    if (_isFocusActive || _isOnBreak) {
      debugPrint('[FocusProvider] Session already active.');
      return false;
    }
    if (isAnySessionActive) {
      debugPrint('[FocusProvider] Another session ($globalActiveSession) is active.');
      return false;
    }
    claimSession('focus');

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final activeBlockedApps = _resolveBlockedApps();

    _currentFocusSession = FocusSession(
      id: _uuid.v4(),
      startTime: now,
      targetDurationMinutes: _targetMinutes,
      date: today,
      blockedApps: activeBlockedApps,
    );

    _remainingSeconds = _targetMinutes * 60;
    _isFocusActive = true;
    _isPaused = false;
    _isOnBreak = false;
    _totalPenaltySeconds = 0;
    _lastActivityTime = DateTime.now();
    _appInBackground = false;

    if (activeBlockedApps.isNotEmpty) {
      try {
        await platform.invokeMethod('startFocusMode', {
          'blockedApps': activeBlockedApps,
          'durationMinutes': _targetMinutes,
        });
      } on PlatformException catch (e) {
        debugPrint('Failed to start focus mode: ${e.message}');
      }
    }

    // ── DND: user এর setting অনুযায়ী চালু করো ──
    if (_enableDND) {
      try {
        await platform.invokeMethod('enableDND');
      } on PlatformException catch (e) {
        debugPrint('Failed to enable DND: ${e.message}');
      }
    }

    await _db.insertFocusSession(_currentFocusSession!.toMap());

    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_focusLevel == FocusLevel.strict) _checkIdle();
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds % 30 == 0) _syncAndroidWidget();
        notifyListeners();
      } else {
        completeFocusSession();
      }
    });

    await _syncAndroidWidget();
    notifyListeners();
    return true;
  }

  Future<void> completeFocusSession() async {
    if (!_isFocusActive || _currentFocusSession == null) return;

    _focusTimer?.cancel();
    _focusTimer = null;

    final now = DateTime.now();
    final actualMinutes = _targetMinutes - (_remainingSeconds ~/ 60);

    final completedSession = _currentFocusSession!.copyWith(
      endTime: now,
      actualDurationMinutes: actualMinutes,
      isCompleted: true,
    );

    try {
      await platform.invokeMethod('stopFocusMode');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop focus mode: ${e.message}');
    }

    // ── DND: user এর setting অনুযায়ী বন্ধ করো ──
    if (_enableDND) {
      try {
        await platform.invokeMethod('disableDND');
      } on PlatformException catch (e) {
        debugPrint('Failed to disable DND: ${e.message}');
      }
    }

    await _db.updateFocusSession(completedSession.id, completedSession.toMap());
    await _updateDailyFocusStats(actualMinutes);

    try {
      await HistoryService.instance.logEvent(
        'focus_session',
        '${_focusLevel.label} session completed',
        '${actualMinutes}min focus at ${_focusLevel.label} level',
        duration: actualMinutes,
        xp: 10 + actualMinutes ~/ 5,
        gold: 2 + actualMinutes ~/ 15,
        metadata: {
          'level': _focusLevel.name,
          'target_minutes': _targetMinutes,
          'penalty_seconds': _totalPenaltySeconds,
          'pomodoro_count': _pomodoroCount + 1,
          'dnd_enabled': _enableDND,
        },
      );
    } catch (_) {}

    _pomodoroCount++;
    _sessionsSinceLongBreak++;
    _isFocusActive = false;
    _isPaused = false;
    _currentFocusSession = null;
    _remainingSeconds = _targetMinutes * 60;
    releaseSession('focus');

    final breakDuration =
    _sessionsSinceLongBreak >= 4 ? _longBreakMinutes : _shortBreakMinutes;
    if (_sessionsSinceLongBreak >= 4) _sessionsSinceLongBreak = 0;

    await startBreak(durationMinutes: breakDuration);
    await _syncAndroidWidget();
    notifyListeners();
  }

  Future<void> startBreak({int? durationMinutes}) async {
    _focusTimer?.cancel();
    _isOnBreak = true;
    _isFocusActive = false;
    _remainingSeconds = (durationMinutes ?? _shortBreakMinutes) * 60;
    _isPaused = false;

    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds % 30 == 0) _syncAndroidWidget();
        notifyListeners();
      } else {
        _focusTimer?.cancel();
        _focusTimer = null;
        _isOnBreak = false;
        _isPaused = false;
        _remainingSeconds = _targetMinutes * 60;
        _syncAndroidWidget();
        notifyListeners();
      }
    });

    await _syncAndroidWidget();
    notifyListeners();
  }

  void skipBreak() {
    if (!_isOnBreak) return;
    _focusTimer?.cancel();
    _focusTimer = null;
    _isOnBreak = false;
    _isPaused = false;
    _remainingSeconds = _targetMinutes * 60;
    _syncAndroidWidget();
    notifyListeners();
  }

  Future<void> cancelFocusSession({bool force = false}) async {
    if (!_isFocusActive && !_isOnBreak) return;
    if (isStrictMode && !force && _isFocusActive) return;

    _focusTimer?.cancel();
    _focusTimer = null;

    try {
      await platform.invokeMethod('stopFocusMode');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop focus mode: ${e.message}');
    }

    // ── DND: user এর setting অনুযায়ী বন্ধ করো ──
    if (_enableDND) {
      try {
        await platform.invokeMethod('disableDND');
      } on PlatformException catch (e) {
        debugPrint('Failed to disable DND: ${e.message}');
      }
    }

    if (_currentFocusSession != null) {
      final now = DateTime.now();
      final actualMinutes = _targetMinutes - (_remainingSeconds ~/ 60);
      final cancelledSession = _currentFocusSession!.copyWith(
        endTime: now,
        actualDurationMinutes: actualMinutes,
        isCompleted: false,
      );
      await _db.updateFocusSession(
          cancelledSession.id, cancelledSession.toMap());
    }

    _isFocusActive = false;
    _isOnBreak = false;
    _isPaused = false;
    _currentFocusSession = null;
    _remainingSeconds = _targetMinutes * 60;
    releaseSession('focus');

    await _syncAndroidWidget();
    notifyListeners();
  }

  void pauseFocusSession() {
    if (!_isFocusActive || _isPaused) return;
    if (isStrictMode) return;
    _isPaused = true;
    _syncAndroidWidget();
    notifyListeners();
  }

  void resumeFocusSession() {
    if (!_isFocusActive || !_isPaused) return;
    _isPaused = false;
    _syncAndroidWidget();
    notifyListeners();
  }

  void reportActivity() {
    _lastActivityTime = DateTime.now();
  }

  void onAppLifecycleChanged(bool isResumed) {
    if (!_isFocusActive || _isOnBreak) return;
    if (!isResumed) {
      _appInBackground = true;
      if (_focusLevel == FocusLevel.strict || _focusLevel == FocusLevel.deep) {
        _applyPenalty(_appSwitchPenaltySeconds, 'app_switch');
      }
    } else {
      _appInBackground = false;
    }
    notifyListeners();
  }

  void _applyPenalty(int seconds, String reason) {
    _totalPenaltySeconds += seconds;
    _remainingSeconds =
        (_remainingSeconds - seconds).clamp(0, _targetMinutes * 60);
    debugPrint(
        '[AntiCheat] Penalty $seconds s ($reason). Total: $_totalPenaltySeconds s');
    if (_remainingSeconds <= 0) completeFocusSession();
  }

  void _checkIdle() {
    if (_lastActivityTime == null) return;
    final idleSeconds =
        DateTime.now().difference(_lastActivityTime!).inSeconds;
    if (idleSeconds >= _idleThresholdSeconds) {
      _applyPenalty(_idlePenaltySeconds, 'idle');
      _lastActivityTime = DateTime.now();
    }
  }

  Future<void> _updateDailyFocusStats(int focusMinutes) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existingStats = await _db.getDailyStats(today);

    if (existingStats != null) {
      await _db.insertOrUpdateDailyStats({
        'id': existingStats['id'],
        'date': today,
        'total_study_minutes': existingStats['total_study_minutes'],
        'total_focus_minutes':
        (existingStats['total_focus_minutes'] as int) + focusMinutes,
        'sessions_completed': existingStats['sessions_completed'],
        'streak_days': existingStats['streak_days'],
      });
    } else {
      await _db.insertOrUpdateDailyStats({
        'id': _uuid.v4(),
        'date': today,
        'total_study_minutes': 0,
        'total_focus_minutes': focusMinutes,
        'sessions_completed': 0,
        'streak_days': 1,
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final levelIdx = prefs.getInt('focus.level') ?? FocusLevel.moderate.index;
    _focusLevel =
    FocusLevel.values[levelIdx.clamp(0, FocusLevel.values.length - 1)];
    _showBreathing =
        prefs.getBool('focus.show_breathing') ?? _showBreathing;
    _allowEmergencyCalls =
        prefs.getBool('focus.allow_emergency_calls') ?? _allowEmergencyCalls;
    // ── DND load ──
    _enableDND = prefs.getBool('focus.enable_dnd') ?? true;
    _targetMinutes =
        prefs.getInt('focus.target_minutes') ?? _targetMinutes;
    _shortBreakMinutes =
        prefs.getInt('focus.short_break_minutes') ?? _shortBreakMinutes;
    _longBreakMinutes =
        prefs.getInt('focus.long_break_minutes') ?? _longBreakMinutes;
    if (!_isFocusActive && !_isOnBreak) {
      _remainingSeconds = _targetMinutes * 60;
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focus.level', _focusLevel.index);
    await prefs.setBool('focus.show_breathing', _showBreathing);
    await prefs.setBool('focus.allow_emergency_calls', _allowEmergencyCalls);
    // ── DND save ──
    await prefs.setBool('focus.enable_dnd', _enableDND);
    await prefs.setInt('focus.target_minutes', _targetMinutes);
    await prefs.setInt('focus.short_break_minutes', _shortBreakMinutes);
    await prefs.setInt('focus.long_break_minutes', _longBreakMinutes);
  }

  Future<void> refreshHomeWidget() async {
    await _syncAndroidWidget();
  }

  Future<void> _syncAndroidWidget() async {
    try {
      await platform.invokeMethod('updateHomeWidget', {
        'isActive': _isFocusActive,
        'isBreak': _isOnBreak,
        'isPaused': _isPaused,
        'time': formattedRemainingTime,
        'targetMinutes': _targetMinutes,
        'pomodoroCount': _pomodoroCount,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermissions();
    }
  }
}