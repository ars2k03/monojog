import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/theme/app_theme.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  String _searchQuery = '';
  bool _showBlockedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusProvider>().loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'App Blocker',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Consumer<FocusProvider>(
                    builder: (ctx, focus, _) {
                      final blockedCount = focus.blockedApps
                          .where((a) => a.isBlocked)
                          .length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: blockedCount > 0
                              ? AppTheme.errorColor.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: blockedCount > 0
                                ? AppTheme.errorColor.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          '$blockedCount blocked',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: blockedCount > 0
                                ? AppTheme.errorColor
                                : AppTheme.darkTextSec,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search & Filter ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: TextField(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search apps...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.darkTextSec,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 20),
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
                  // Filter toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showBlockedOnly = !_showBlockedOnly),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _showBlockedOnly
                            ? AppTheme.errorColor.withValues(alpha: 0.15)
                            : AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _showBlockedOnly
                              ? AppTheme.errorColor.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: _showBlockedOnly
                            ? AppTheme.errorColor
                            : Colors.white.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryColor.withValues(alpha: 0.7),
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toggle apps to block them during focus sessions. Blocked apps cannot be opened while focusing.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkTextSec,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── App List ──
            Expanded(
              child: Consumer<FocusProvider>(
                builder: (ctx, focus, _) {
                  if (focus.installedApps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading installed apps...',
                            style: GoogleFonts.inter(
                              color: AppTheme.darkTextSec,
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
                      child: Text(
                        _showBlockedOnly
                            ? 'No blocked apps'
                            : 'No apps found',
                        style: GoogleFonts.inter(
                          color: AppTheme.darkTextSec,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  // Sort: blocked apps first
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
                    itemCount: filteredApps.length,
                    itemBuilder: (ctx, i) {
                      final app = filteredApps[i];
                      final isBlocked =
                          _isAppBlocked(focus, app.packageName);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBlocked
                                ? AppTheme.errorColor.withValues(alpha: 0.04)
                                : AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isBlocked
                                  ? AppTheme.errorColor.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? AppTheme.errorColor
                                        .withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isBlocked
                                    ? Icons.block_rounded
                                    : Icons.android_rounded,
                                color: isBlocked
                                    ? AppTheme.errorColor
                                    : Colors.white.withValues(alpha: 0.4),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              app.appName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              app.packageName,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppTheme.darkTextSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: GestureDetector(
                              onTap: () async {
                                if (isBlocked) {
                                  await focus.toggleBlockedApp(
                                      app.packageName, false);
                                } else {
                                  await focus.addBlockedApp(app);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? AppTheme.errorColor
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
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
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAppBlocked(FocusProvider focus, String packageName) {
    return focus.blockedApps
        .any((app) => app.packageName == packageName && app.isBlocked);
  }
}
