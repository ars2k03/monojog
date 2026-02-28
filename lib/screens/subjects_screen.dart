import 'package:flutter/material.dart';
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

  static const List<String> _subjectIcons = [
    '📚',
    '📐',
    '🧪',
    '🌍',
    '💻',
    '🎨',
    '🎵',
    '📝',
    '🧮',
    '🔬',
    '📖',
    '🏛️',
    '🧠',
    '⚡',
    '🌿',
  ];

  static const List<int> _subjectColors = [
    0xFF6441A5,
    0xFF9D4EDD,
    0xFF00F5D4,
    0xFFFF4D6D,
    0xFFFEE440,
    0xFF06B6D4,
    0xFFFF6B35,
    0xFF4ECDC4,
    0xFF7B68EE,
    0xFFFF1493,
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final db = await DatabaseService.instance.database;
    // Create subjects table if not exists
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
    final results = await db.query('subjects', orderBy: 'created_at DESC');
    setState(() {
      _subjects = results.map((m) => Subject.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _addSubject() async {
    final nameCtrl = TextEditingController();
    String selectedIcon = '📚';
    int selectedColor = _subjectColors[0];
    int dailyGoal = 60;
    int weeklyGoal = 300;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Subject'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g. Mathematics',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjectIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryColor, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child:
                              Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjectColors.map((c) {
                      final isSelected = c == selectedColor;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Color(c).withValues(alpha: 0.5),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Daily Goal (min)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: '$dailyGoal'),
                          onChanged: (v) => dailyGoal = int.tryParse(v) ?? 60,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Weekly Goal (min)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller:
                              TextEditingController(text: '$weeklyGoal'),
                          onChanged: (v) => weeklyGoal = int.tryParse(v) ?? 300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final subject = Subject(
                    id: _uuid.v4(),
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                    colorValue: selectedColor,
                    dailyGoalMinutes: dailyGoal,
                    weeklyGoalMinutes: weeklyGoal,
                  );
                  final db = await DatabaseService.instance.database;
                  await db.insert('subjects', subject.toMap());
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadSubjects();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSubject(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
    _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects & Goals'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_rounded,
                          size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      const Text('No subjects yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Add subjects to track study goals',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (ctx, i) {
                    final s = _subjects[i];
                    final dailyProgress =
                        (s.totalMinutes / s.dailyGoalMinutes).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: s.color.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: s.color.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: s.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(s.icon,
                                    style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${s.totalMinutes} min total  |  Daily: ${s.dailyGoalMinutes}m  Weekly: ${s.weeklyGoalMinutes}m',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () => _deleteSubject(s.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: dailyProgress,
                              minHeight: 8,
                              backgroundColor: s.color.withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(s.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
