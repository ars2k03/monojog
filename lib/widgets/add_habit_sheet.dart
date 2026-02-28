import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/models/habit.dart';
import 'package:monojog/providers/habit_provider.dart';

class AddHabitSheet extends StatefulWidget {
  final Habit? editHabit;
  const AddHabitSheet({super.key, this.editHabit});
  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  late final TextEditingController _titleCtrl;
  String _emoji = '✅';
  String _color = '#7C4DFF';
  HabitRepeat _repeat = HabitRepeat.daily;
  List<int> _customDays = [];
  HabitCategory _category = HabitCategory.custom;
  int? _reminderHour;
  int? _reminderMinute;

  bool get _isEdit => widget.editHabit != null;

  static const _colors = [
    '#7C4DFF', '#E040FB', '#FF4D6D', '#FF6B35',
    '#FFD700', '#4CAF50', '#00E5A0', '#00B4D8',
    '#06D6A0', '#3B82F6', '#6366F1', '#8B5CF6',
    '#F59E0B', '#EF4444', '#14B8A6', '#EC4899',
  ];

  static const _emojis = [
    '✅', '💧', '📖', '🚶', '📝', '📵', '⏰', '🛏️',
    '🤸', '🥣', '📋', '😴', '🧘', '📚', '💻', '🎯',
    '🔥', '💡', '📧', '🏋️', '🧴', '🥗', '🚫', '💊',
    '🌅', '🌙', '🎨', '🎸', '🏃', '🧹', '💤', '🍎',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final h = widget.editHabit!;
      _titleCtrl = TextEditingController(text: h.title);
      _emoji = h.emoji;
      _color = h.color;
      _repeat = h.repeat;
      _customDays = List.from(h.customDays);
      _category = h.category;
      _reminderHour = h.reminderHour;
      _reminderMinute = h.reminderMinute;
    } else {
      _titleCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Color _hex(String hex) {
    final c = hex.replaceAll('#', '');
    return Color(int.parse(c.length == 6 ? 'FF$c' : c, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF14141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? 'Edit Habit' : 'New Habit',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 20),

            // ── Title ──
            _sectionLabel('Habit Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Drink 8 glasses of water',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF8B8FA3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // ── Emoji ──
            _sectionLabel('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _emojis.map((e) {
                final sel = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: sel ? _hex(_color).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? _hex(_color).withValues(alpha: 0.5) : Colors.transparent,
                        width: sel ? 2 : 0,
                      ),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 18))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Color ──
            _sectionLabel('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _colors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _hex(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: sel ? 3 : 0,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: _hex(c).withValues(alpha: 0.4), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Category ──
            _sectionLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: HabitCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _hex(_color).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? _hex(_color).withValues(alpha: 0.4) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(cat.label,
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? Colors.white : const Color(0xFF8B8FA3),
                          )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Repeat ──
            _sectionLabel('Repeat'),
            const SizedBox(height: 8),
            Row(
              children: HabitRepeat.values.map((r) {
                final sel = _repeat == r;
                final label = r == HabitRepeat.daily ? 'Daily'
                    : r == HabitRepeat.weekdays ? 'Weekdays'
                    : r == HabitRepeat.weekends ? 'Weekends' : 'Custom';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _repeat = r),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _hex(_color).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? _hex(_color).withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: Text(label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : const Color(0xFF8B8FA3),
                        )),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom days picker
            if (_repeat == HabitRepeat.custom) ...[
              const SizedBox(height: 12),
              Row(
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon..7=Sun
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final sel = _customDays.contains(day);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (sel) { _customDays.remove(day); }
                          else { _customDays.add(day); }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 40,
                        decoration: BoxDecoration(
                          color: sel ? _hex(_color) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(labels[i],
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : const Color(0xFF8B8FA3),
                            )),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 20),

            // ── Reminder ──
            _sectionLabel('Reminder'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickReminder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded,
                      color: _reminderHour != null ? _hex(_color) : const Color(0xFF8B8FA3), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _reminderHour != null
                          ? '${_reminderHour! > 12 ? _reminderHour! - 12 : (_reminderHour == 0 ? 12 : _reminderHour!)}:${(_reminderMinute ?? 0).toString().padLeft(2, '0')} ${_reminderHour! >= 12 ? 'PM' : 'AM'}'
                          : 'No reminder',
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _reminderHour != null ? Colors.white : const Color(0xFF8B8FA3),
                      ),
                    ),
                    const Spacer(),
                    if (_reminderHour != null)
                      GestureDetector(
                        onTap: () => setState(() { _reminderHour = null; _reminderMinute = null; }),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF8B8FA3), size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ──
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_hex(_color), _hex(_color).withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _hex(_color).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Text(_isEdit ? 'Save Changes' : 'Create Habit',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8B8FA3), letterSpacing: 0.5));
  }

  Future<void> _pickReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour ?? 8, minute: _reminderMinute ?? 0),
    );
    if (time != null) {
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final habits = context.read<HabitProvider>();

    if (_isEdit) {
      habits.updateHabit(widget.editHabit!.copyWith(
        title: title,
        emoji: _emoji,
        color: _color,
        repeat: _repeat,
        customDays: _customDays,
        reminderHour: _reminderHour,
        reminderMinute: _reminderMinute,
        category: _category,
      ));
    } else {
      habits.createHabit(
        title: title,
        emoji: _emoji,
        color: _color,
        repeat: _repeat,
        customDays: _customDays,
        reminderHour: _reminderHour,
        reminderMinute: _reminderMinute,
        category: _category,
      );
    }

    Navigator.pop(context);
  }
}