import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:monojog/models/subject_model.dart';
import 'package:monojog/services/database_service.dart';
import 'package:uuid/uuid.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _uuid = const Uuid();
  List<Subject> _subjects = [];
  bool _isLoading = true;

  // ── Adaptive helpers ────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg =>
      _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);
  Color get _card =>
      _isDark ? AppTheme.darkSurface : Colors.white;
  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF0D1117);
  Color get _textSec =>
      _isDark ? AppTheme.darkTextSec : const Color(0xFF5A6070);
  Color get _border =>
      _isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.08);
  Color get _inputFill =>
      _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);

  List<BoxShadow> _cardShadow(Color accent) => [
    BoxShadow(
      color: accent.withValues(alpha: _isDark ? 0.08 : 0.12),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
    if (!_isDark)
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
  ];

  // ── Data ────────────────────────────────────────────────────────────────
  static const List<String> _subjectIcons = [
    '📚', '📐', '🧪', '🌍', '💻', '🎨',
    '🎵', '📝', '🧮', '🔬', '📖', '🏛️',
    '🧠', '⚡', '🌿',
  ];

  static const List<int> _subjectColors = [
    0xFF6441A5, 0xFF9D4EDD, 0xFF00BFA5, 0xFFE53935,
    0xFFF9A825, 0xFF0097A7, 0xFFFF6B35, 0xFF26A69A,
    0xFF7B68EE, 0xFFE91E8C,
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subjects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT DEFAULT '📚',
          color_value INTEGER DEFAULT 6570405,
          total_minutes INTEGER DEFAULT 0,
          daily_goal_minutes INTEGER DEFAULT 60,
          weekly_goal_minutes INTEGER DEFAULT 300,
          created_at TEXT NOT NULL
        )
      ''');
      final results =
      await db.query('subjects', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _subjects = results.map((m) => Subject.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> _addOrEditSubject([Subject? existing]) async {
    final nameCtrl =
    TextEditingController(text: existing?.name ?? '');
    final dailyCtrl = TextEditingController(
        text: '${existing?.dailyGoalMinutes ?? 60}');
    final weeklyCtrl = TextEditingController(
        text: '${existing?.weeklyGoalMinutes ?? 300}');
    String selectedIcon = existing?.icon ?? '📚';
    int selectedColor =
        existing?.colorValue ?? _subjectColors[0];
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDlgDark =
              Theme.of(ctx).brightness == Brightness.dark;
          final dlgCard =
          isDlgDark ? AppTheme.darkSurface : Colors.white;
          final dlgBg =
          isDlgDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);
          final dlgText =
          isDlgDark ? Colors.white : const Color(0xFF0D1117);
          final dlgSec = isDlgDark
              ? AppTheme.darkTextSec
              : const Color(0xFF5A6070);

          return AlertDialog(
            backgroundColor: dlgCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Text(
              existing == null ? 'Add Subject' : 'Edit Subject',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: dlgText,
                  fontSize: 18),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ──────────────────────────────────
                      TextFormField(
                        controller: nameCtrl,
                        style: TextStyle(
                            color: dlgText, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Mathematics',
                          labelStyle: TextStyle(color: dlgSec),
                          hintStyle: TextStyle(
                              color: dlgSec.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: dlgBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.red, width: 2),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Subject name is required'
                            : null,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // ── Icon picker ───────────────────────────
                      Text('Icon',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: dlgText,
                              fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subjectIcons.map((icon) {
                          final isSel = icon == selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setDialogState(() => selectedIcon = icon);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppTheme.primaryColor
                                    .withValues(alpha: 0.15)
                                    : dlgBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? AppTheme.primaryColor
                                      : (isDlgDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.black.withValues(alpha: 0.07)),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Color picker ──────────────────────────
                      Text('Color',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: dlgText,
                              fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _subjectColors.map((c) {
                          final isSel = c == selectedColor;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setDialogState(() => selectedColor = c);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: isSel
                                    ? Border.all(
                                    color: isDlgDark
                                        ? Colors.white
                                        : Colors.white,
                                    width: 3)
                                    : null,
                                boxShadow: isSel
                                    ? [
                                  BoxShadow(
                                      color: Color(c)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8)
                                ]
                                    : null,
                              ),
                              child: isSel
                                  ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Goals ─────────────────────────────────
                      Text('Goals',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: dlgText,
                              fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: dailyCtrl,
                              style: TextStyle(
                                  color: dlgText,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Daily (min)',
                                labelStyle: TextStyle(color: dlgSec),
                                filled: true,
                                fillColor: dlgBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Invalid'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: weeklyCtrl,
                              style: TextStyle(
                                  color: dlgText,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Weekly (min)',
                                labelStyle: TextStyle(color: dlgSec),
                                filled: true,
                                fillColor: dlgBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Invalid'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: dlgSec)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final dailyGoal =
                      int.tryParse(dailyCtrl.text.trim()) ?? 60;
                  final weeklyGoal =
                      int.tryParse(weeklyCtrl.text.trim()) ?? 300;

                  final subject = Subject(
                    id: existing?.id ?? _uuid.v4(),
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                    colorValue: selectedColor,
                    totalMinutes: existing?.totalMinutes ?? 0,
                    dailyGoalMinutes: dailyGoal,
                    weeklyGoalMinutes: weeklyGoal,
                  );
                  final db = await DatabaseService.instance.database;
                  if (existing == null) {
                    await db.insert('subjects', subject.toMap());
                  } else {
                    await db.update('subjects', subject.toMap(),
                        where: 'id = ?', whereArgs: [subject.id]);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadSubjects();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(existing == null ? 'Add' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subject?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                fontSize: 17)),
        content: Text(
          'All study records for "${subject.name}" will be removed.',
          style: TextStyle(color: _textSec, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final db = await DatabaseService.instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [subject.id]);
    _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Subjects & Goals',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _textPrimary,
              fontSize: 20),
        ),
        backgroundColor: _isDark ? AppTheme.primaryDark : Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _addOrEditSubject();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: _border))
          : _subjects.isEmpty
          ? _buildEmptyState()
          : _buildSubjectList(),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_rounded,
                  size: 48,
                  color:
                  AppTheme.primaryColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text('No subjects yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Add subjects to track your study goals and progress.',
              style: TextStyle(
                  color: _textSec, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _addOrEditSubject,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add First Subject',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Subject List ─────────────────────────────────────────────────────────
  Widget _buildSubjectList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _subjects.length,
      itemBuilder: (ctx, i) {
        final s = _subjects[i];
        final dailyProgress =
        (s.totalMinutes / s.dailyGoalMinutes).clamp(0.0, 1.0);
        final weeklyProgress =
        (s.totalMinutes / s.weeklyGoalMinutes).clamp(0.0, 1.0);

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _addOrEditSubject(s);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.color.withValues(alpha: 0.25)),
              boxShadow: _cardShadow(s.color),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(s.icon,
                              style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary)),
                          const SizedBox(height: 3),
                          Text(
                            '${_formatMin(s.totalMinutes)} studied  •  D: ${s.dailyGoalMinutes}m  W: ${s.weeklyGoalMinutes}m',
                            style: TextStyle(
                                fontSize: 11,
                                color: _textSec,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // Action menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: _textSec, size: 20),
                      color: _card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) {
                        if (val == 'edit') _addOrEditSubject(s);
                        if (val == 'delete') _deleteSubject(s);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded,
                                color: AppTheme.primaryColor, size: 18),
                            const SizedBox(width: 10),
                            Text('Edit',
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(children: [
                            Icon(Icons.delete_rounded,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Daily progress ────────────────────────────
                Row(
                  children: [
                    Text('Daily',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _textSec)),
                    const Spacer(),
                    Text(
                      '${(dailyProgress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: dailyProgress >= 1.0
                              ? Colors.green
                              : s.color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: dailyProgress,
                    minHeight: 7,
                    backgroundColor:
                    s.color.withValues(alpha: _isDark ? 0.1 : 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        dailyProgress >= 1.0 ? Colors.green : s.color),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Weekly progress ───────────────────────────
                Row(
                  children: [
                    Text('Weekly',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _textSec)),
                    const Spacer(),
                    Text(
                      '${(weeklyProgress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: weeklyProgress >= 1.0
                              ? Colors.green
                              : s.color.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: weeklyProgress,
                    minHeight: 5,
                    backgroundColor:
                    s.color.withValues(alpha: _isDark ? 0.08 : 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        weeklyProgress >= 1.0
                            ? Colors.green
                            : s.color.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatMin(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}