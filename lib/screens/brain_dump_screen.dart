import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:monojog/widgets/neu_container.dart';

class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final _textController = TextEditingController();
  String _selectedType = 'general';

  // ── Adaptive helpers ────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg =>
      _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);

  Color get _cardBg =>
      _isDark ? AppTheme.darkCard : Colors.white;

  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF0D1117);

  Color get _textSec =>
      _isDark ? AppTheme.darkTextSec : const Color(0xFF5A6070);

  Color get _borderColor =>
      _isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.08);

  Color get _inputFill =>
      _isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);

  List<BoxShadow> get _cardShadow => _isDark
      ? []
      : [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3))
  ];

  // ────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveDump() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<GameProvider>().addBrainDump(text, type: _selectedType);
    _textController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Brain Dump',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: _textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: Column(
        children: [
          // ── Input Area ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              boxShadow: _cardShadow,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write down all your thoughts here before focusing.',
                  style: TextStyle(
                    color: _textSec,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What are you thinking?',
                    hintStyle: TextStyle(color: _textSec),
                    filled: true,
                    fillColor: _inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTypeChip('general', 'General'),
                    const SizedBox(width: 12),
                    _buildTypeChip('pre_focus', 'Pre-Focus'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _saveDump,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 4,
                        shadowColor:
                        AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text('Save',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── List Area ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<GameProvider>(
              builder: (ctx, game, _) {
                if (game.brainDumps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology_rounded,
                            size: 64,
                            color: _textSec.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No Notes',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textSec)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: game.brainDumps.length,
                  itemBuilder: (ctx, i) {
                    final dump = game.brainDumps[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: _cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                // Type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: dump.type == 'pre_focus'
                                        ? AppTheme.accentPurple
                                        .withValues(alpha: 0.12)
                                        : _textSec.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: dump.type == 'pre_focus'
                                          ? AppTheme.accentPurple
                                          .withValues(alpha: 0.3)
                                          : _borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    dump.type == 'pre_focus'
                                        ? 'Pre-Focus'
                                        : 'General',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: dump.type == 'pre_focus'
                                          ? AppTheme.accentPurple
                                          : _textSec,
                                    ),
                                  ),
                                ),
                                // Date
                                Text(
                                  DateFormat('dd MMM, hh:mm a')
                                      .format(dump.createdAt),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _textSec,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              dump.text,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : _textSec.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : _textSec,
          ),
        ),
      ),
    );
  }
}