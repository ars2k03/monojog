import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/theme/app_theme.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  bool _showBlockedOnly = false;
  bool _permissionsChecked = false;
  Map<String, bool> _permissions = {};

  static const _focusChannel = MethodChannel('com.monojog.app/focus');

  // ── Adaptive helpers ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);
  Color get _card => _isDark ? AppTheme.darkSurface : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0D1117);
  Color get _textSec =>
      _isDark ? AppTheme.darkTextSec : const Color(0xFF5A6070);
  Color get _border =>
      _isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.08);
  Color get _iconMuted =>
      _isDark
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.3);

  List<BoxShadow> get _shadow => _isDark
      ? []
      : [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2))
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndLoad();
    }
  }

  Future<void> _checkPermissionsAndLoad() async {
    try {
      final result =
      await _focusChannel.invokeMethod('checkPermissions');
      if (mounted) {
        setState(() {
          _permissions = Map<String, bool>.from(result);
          _permissionsChecked = true;
        });
        if (_hasRequiredPermissions()) {
          context.read<FocusProvider>().loadInstalledApps();
        }
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      if (mounted) {
        setState(() => _permissionsChecked = true);
        context.read<FocusProvider>().loadInstalledApps();
      }
    }
  }

  bool _hasRequiredPermissions() {
    return (_permissions['hasAccessibilityPermission'] ?? false) &&
        (_permissions['hasUsagePermission'] ?? false);
  }

  bool get _hasAccessibility =>
      _permissions['hasAccessibilityPermission'] ?? false;
  bool get _hasUsage => _permissions['hasUsagePermission'] ?? false;
  bool get _hasOverlay => _permissions['hasOverlayPermission'] ?? false;

  Future<void> _requestPermission(String method) async {
    HapticFeedback.mediumImpact();
    try {
      await _focusChannel.invokeMethod(method);
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 12),
            if (_permissionsChecked && !_hasRequiredPermissions())
              _buildPermissionSetup()
            else ...[
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildInfoBanner(),
              const SizedBox(height: 8),
              _buildAppList(),
            ],
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'App Blocker',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
          Consumer<FocusProvider>(
            builder: (ctx, focus, _) {
              final blockedCount =
                  focus.blockedApps.where((a) => a.isBlocked).length;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: blockedCount > 0
                      ? AppTheme.errorColor.withValues(alpha: 0.12)
                      : _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: blockedCount > 0
                        ? AppTheme.errorColor.withValues(alpha: 0.25)
                        : _border,
                  ),
                  boxShadow: _shadow,
                ),
                child: Text(
                  '$blockedCount block',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: blockedCount > 0
                        ? AppTheme.errorColor
                        : _textSec,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Permission Setup ─────────────────────────────────────────────────────
  Widget _buildPermissionSetup() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.security_rounded,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.7)),
            const SizedBox(height: 20),
            Text(
              'পারমিশন সেটআপ করুন',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'অ্যাপ ব্লক করতে নিচের পারমিশনগুলো দিতে হবে',
              style:
              GoogleFonts.inter(fontSize: 13, color: _textSec),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPermissionCard(
              icon: Icons.layers_rounded,
              title: 'ওভারলে পারমিশন',
              subtitle: 'ব্লক স্ক্রিন দেখাতে প্রয়োজন',
              isGranted: _hasOverlay,
              onRequest: () =>
                  _requestPermission('requestOverlayPermission'),
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              icon: Icons.bar_chart_rounded,
              title: 'ব্যবহারের তথ্য অ্যাক্সেস',
              subtitle: 'কোন অ্যাপ চালু আছে তা জানতে প্রয়োজন',
              isGranted: _hasUsage,
              onRequest: () =>
                  _requestPermission('requestUsagePermission'),
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              icon: Icons.accessibility_new_rounded,
              title: 'অ্যাক্সেসিবিলিটি সার্ভিস',
              subtitle: 'ব্লক করা অ্যাপ ডিটেক্ট করতে প্রয়োজন',
              isGranted: _hasAccessibility,
              onRequest: () =>
                  _requestPermission('openAccessibilitySettings'),
            ),

            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _checkPermissionsAndLoad,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'পারমিশন রিফ্রেশ করুন',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    const grantedColor = Colors.green;
    return GestureDetector(
      onTap: isGranted ? null : onRequest,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGranted
              ? grantedColor.withValues(alpha: 0.06)
              : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted
                ? grantedColor.withValues(alpha: 0.25)
                : _border,
          ),
          boxShadow: _shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isGranted
                    ? grantedColor.withValues(alpha: 0.12)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isGranted ? grantedColor : AppTheme.primaryColor,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _textSec),
                  ),
                ],
              ),
            ),
            Icon(
              isGranted
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isGranted ? grantedColor : _iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: _shadow,
              ),
              child: TextField(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for apps...',
                  hintStyle: GoogleFonts.inter(
                    color: _textSec,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon:
                  Icon(Icons.search_rounded, color: _iconMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showBlockedOnly = !_showBlockedOnly);
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _showBlockedOnly
                    ? AppTheme.errorColor.withValues(alpha: 0.12)
                    : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _showBlockedOnly
                      ? AppTheme.errorColor.withValues(alpha: 0.3)
                      : _border,
                ),
                boxShadow: _shadow,
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: _showBlockedOnly
                    ? AppTheme.errorColor
                    : _iconMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Banner ──────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor
              .withValues(alpha: _isDark ? 0.06 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primaryColor
                  .withValues(alpha: _isDark ? 0.1 : 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'অ্যাপ টগল করুন ব্লক করতে। ফোকাস মোড চালু থাকলে ব্লক করা অ্যাপ খোলা যাবে না। মনোযোগ অ্যাপ থেকে ফোকাস মোড বন্ধ করলেই আবার ব্যবহার করতে পারবেন।',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _textSec,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App List ─────────────────────────────────────────────────────────────
  Widget _buildAppList() {
    return Expanded(
      child: Consumer<FocusProvider>(
        builder: (ctx, focus, _) {
          if (focus.installedApps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                    backgroundColor: _border,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ইনস্টল করা অ্যাপ লোড হচ্ছে...',
                    style: GoogleFonts.inter(
                      color: _textSec,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          var filteredApps = focus.installedApps.where((app) {
            final matchesSearch =
            app.appName.toLowerCase().contains(_searchQuery);
            if (_showBlockedOnly) {
              return matchesSearch &&
                  _isAppBlocked(focus, app.packageName);
            }
            return matchesSearch;
          }).toList();

          if (filteredApps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showBlockedOnly
                        ? Icons.block_rounded
                        : Icons.search_off_rounded,
                    color: _textSec.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showBlockedOnly
                        ? 'কোনো ব্লক করা অ্যাপ নেই'
                        : 'কোনো অ্যাপ পাওয়া যায়নি',
                    style: GoogleFonts.inter(
                      color: _textSec,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          filteredApps.sort((a, b) {
            final aBlocked = _isAppBlocked(focus, a.packageName);
            final bBlocked = _isAppBlocked(focus, b.packageName);
            if (aBlocked && !bBlocked) return -1;
            if (!aBlocked && bBlocked) return 1;
            return a.appName
                .toLowerCase()
                .compareTo(b.appName.toLowerCase());
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredApps.length,
            itemBuilder: (ctx, i) {
              final app = filteredApps[i];
              final isBlocked = _isAppBlocked(focus, app.packageName);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildAppTile(focus, app, isBlocked),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppTile(
      FocusProvider focus, dynamic app, bool isBlocked) {
    return Container(
      decoration: BoxDecoration(
        color: isBlocked
            ? AppTheme.errorColor
            .withValues(alpha: _isDark ? 0.04 : 0.05)
            : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked
              ? AppTheme.errorColor.withValues(alpha: 0.2)
              : _border,
        ),
        boxShadow: _shadow,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isBlocked
                ? AppTheme.errorColor.withValues(alpha: 0.12)
                : _isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isBlocked ? Icons.block_rounded : Icons.android_rounded,
            color: isBlocked ? AppTheme.errorColor : _iconMuted,
            size: 20,
          ),
        ),
        title: Text(
          app.appName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _textPrimary,
          ),
        ),
        subtitle: Text(
          app.packageName,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: _textSec,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: GestureDetector(
          onTap: () async {
            HapticFeedback.mediumImpact();
            if (!isBlocked) {
              final confirm =
              await _showBlockConfirmDialog(app.appName);
              if (confirm != true) return;
              await focus.addBlockedApp(app);
            } else {
              await focus.toggleBlockedApp(app.packageName, false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 50,
            height: 28,
            decoration: BoxDecoration(
              color: isBlocked
                  ? AppTheme.errorColor
                  : _isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: isBlocked
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showBlockConfirmDialog(String appName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$appName ব্লক করবেন?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: Text(
          'ফোকাস মোড চালু থাকলে এই অ্যাপ খোলা যাবে না। মনোযোগ অ্যাপ থেকে আনব্লক করতে পারবেন।',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _textSec,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'বাতিল',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _textSec,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'ব্লক করুন',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  bool _isAppBlocked(FocusProvider focus, String packageName) {
    return focus.blockedApps
        .any((app) => app.packageName == packageName && app.isBlocked);
  }
}