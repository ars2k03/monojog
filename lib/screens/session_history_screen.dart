import 'package:flutter/material.dart';
import 'package:monojog/services/database_service.dart';
import 'package:monojog/theme/app_theme.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _error;

  // ── Adaptive helpers ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg =>
      _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);
  Color get _card =>
      _isDark ? AppTheme.darkSurface : Colors.white;
  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF0D1117);
  Color get _textSec =>
      _isDark ? Colors.white60 : const Color(0xFF5A6070);
  Color get _textMuted =>
      _isDark ? Colors.white38 : Colors.black45;
  Color get _border =>
      _isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.07);

  List<BoxShadow> get _shadow => _isDark
      ? []
      : [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 3))
  ];

  // ── Data ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'focus_sessions',
        orderBy: 'start_time DESC',
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _sessions = results;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load sessions.';
        });
      }
      debugPrint('SessionHistory load error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  double _completionRate(int actual, int target) =>
      target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Session History',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: _textPrimary),
        ),
        backgroundColor:
        _isDark ? AppTheme.primaryDark : Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: _border))
          : _error != null
          ? _buildErrorState()
          : _sessions.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  // ── Empty / Error states ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded,
                  size: 44,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text('No sessions yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Start a focus session to see your history here.',
              style: TextStyle(
                  color: _textSec, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 52,
              color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(color: _textSec, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSessions();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  // ── Session List ──────────────────────────────────────────────────────
  Widget _buildList() {
    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in _sessions) {
      final date = (s['date'] as String?) ?? 'Unknown';
      grouped.putIfAbsent(date, () => []).add(s);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: grouped.length,
      itemBuilder: (ctx, i) {
        final date = grouped.keys.elementAt(i);
        final daySessions = grouped[date]!;
        final dayTotal =
        daySessions.fold<int>(0, (sum, s) => sum + ((s['actual_duration_minutes'] as int?) ?? 0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date header ───────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Row(
                children: [
                  Text(date,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _textSec,
                          letterSpacing: 0.3)),
                  const Spacer(),
                  Text('$dayTotal min total',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.8))),
                ],
              ),
            ),
            // ── Cards ─────────────────────────────────────
            ...daySessions.map((s) => _buildSessionCard(s)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> s) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(
        s['start_time'] as int? ?? 0);
    final targetMin = s['target_duration_minutes'] as int? ?? 0;
    final actualMin = s['actual_duration_minutes'] as int? ?? 0;
    final completed = (s['is_completed'] as int? ?? 0) == 1;
    final progress = _completionRate(actualMin, targetMin);

    final statusColor =
    completed ? AppTheme.successColor : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? AppTheme.successColor.withValues(alpha: 0.25)
              : Colors.redAccent.withValues(alpha: 0.2),
        ),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── Status icon ──────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // ── Status + time ────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'Completed' : 'Cancelled',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: statusColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(startTime),
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSec,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // ── Duration ─────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$actualMin min',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _textPrimary),
                  ),
                  Text(
                    'of $targetMin min',
                    style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          // ── Progress bar ──────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: statusColor.withValues(
                        alpha: _isDark ? 0.1 : 0.12),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}