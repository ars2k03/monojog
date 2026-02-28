import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  int _selectedType = 0; // 0=habit, 1=daily, 2=todo
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  int _difficulty = 2;
  bool _isPositive = true;
  int _targetMinutes = 30;

  final _types = [
    {
      'icon': Icons.repeat_rounded,
      'label': 'Habit',
      'color': AppTheme.accentPurple
    },
    {
      'icon': Icons.calendar_today_rounded,
      'label': 'Daily',
      'color': AppTheme.primaryColor
    },
    {
      'icon': Icons.check_circle_outline_rounded,
      'label': 'To-Do',
      'color': AppTheme.successColor
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final notes = _notesController.text.trim();
    final game = context.read<GameProvider>();

    switch (_selectedType) {
      case 0:
        game.addHabit(title,
            notes: notes.isEmpty ? null : notes,
            isPositive: _isPositive,
            difficulty: _difficulty);
        break;
      case 1:
        game.addDaily(title,
            notes: notes.isEmpty ? null : notes,
            targetMinutes: _targetMinutes,
            difficulty: _difficulty);
        break;
      case 2:
        game.addTodo(title,
            notes: notes.isEmpty ? null : notes, difficulty: _difficulty);
        break;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add New Task',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            const SizedBox(height: 24),

            // Type selector
            Row(
              children: List.generate(3, (i) {
                final t = _types[i];
                final sel = _selectedType == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  (t['color'] as Color).withValues(alpha: 0.2),
                                  (t['color'] as Color).withValues(alpha: 0.05),
                                ],
                              )
                            : null,
                        color: sel
                            ? null
                            : (isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel
                              ? t['color'] as Color
                              : Colors.grey.withValues(alpha: 0.2),
                          width: sel ? 2 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: (t['color'] as Color)
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(t['icon'] as IconData,
                              color: sel ? t['color'] as Color : Colors.grey,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? t['color'] as Color : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter task name...'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Notes (optional)...'),
            ),
            const SizedBox(height: 16),

            // Difficulty
            Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _diffChip(1, 'Easy', AppTheme.easyGreen),
                const SizedBox(width: 8),
                _diffChip(2, 'Medium', AppTheme.mediumYellow),
                const SizedBox(width: 8),
                _diffChip(3, 'Hard', AppTheme.hardRed),
              ],
            ),

            // Habit-specific: positive/negative
            if (_selectedType == 0) ...[
              const SizedBox(height: 16),
              Text('Type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeChip(true, '➕ Good Habit', AppTheme.successColor),
                  const SizedBox(width: 8),
                  _typeChip(false, '➖ Bad Habit', AppTheme.errorColor),
                ],
              ),
            ],

            // Daily-specific: target minutes
            if (_selectedType == 1) ...[
              const SizedBox(height: 16),
              Text('Target Time: $_targetMinutes min',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _targetMinutes.toDouble(),
                min: 10,
                max: 180,
                divisions: 17,
                activeColor: AppTheme.primaryColor,
                label: '$_targetMinutes min',
                onChanged: (v) => setState(() => _targetMinutes = v.round()),
              ),
            ],

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Add Task'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _diffChip(int val, String label, Color color) {
    final sel = _difficulty == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel ? color : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? color : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(bool positive, String label, Color color) {
    final sel = _isPositive == positive;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPositive = positive),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel ? color : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? color : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
