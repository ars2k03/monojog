import 'dart:math';
import 'package:flutter/material.dart';
import 'package:monojog/theme/app_theme.dart';

/// A breathing exercise screen shown before focus sessions
/// to calm the mind and prepare for deep concentration.
class BreathingExercise extends StatefulWidget {
  final VoidCallback onComplete;
  final int cycles;

  const BreathingExercise({
    super.key,
    required this.onComplete,
    this.cycles = 3,
  });

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _ringController;
  late Animation<double> _breathAnimation;

  int _currentCycle = 0;
  String _instruction = 'Breathe In';
  bool _isInhaling = true;

  // 4-7-8 breathing pattern (inhale 4s, hold 7s, exhale 8s)
  static const int _inhaleMs = 4000;
  static const int _holdMs = 3000;
  static const int _exhaleMs = 5000;
  static const int _totalMs = _inhaleMs + _holdMs + _exhaleMs;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: _inhaleMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _holdMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: _exhaleMs.toDouble(),
      ),
    ]).animate(_breathController);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _breathController.addListener(_updatePhase);
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentCycle++;
        if (_currentCycle >= widget.cycles) {
          widget.onComplete();
        } else {
          _breathController.forward(from: 0.0);
        }
      }
    });

    // Start after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _breathController.forward();
      }
    });
  }

  void _updatePhase() {
    final progress = _breathController.value;
    const inhaleEnd = _inhaleMs / _totalMs;
    const holdEnd = (_inhaleMs + _holdMs) / _totalMs;

    String newInstruction;
    bool newInhaling;

    if (progress < inhaleEnd) {
      newInstruction = 'Breathe In...';
      newInhaling = true;
    } else if (progress < holdEnd) {
      newInstruction = 'Hold...';
      newInhaling = true;
    } else {
      newInstruction = 'Breathe Out...';
      newInhaling = false;
    }

    if (newInstruction != _instruction) {
      setState(() {
        _instruction = newInstruction;
        _isInhaling = newInhaling;
      });
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0221),
              Color(0xFF1A0533),
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Title
              Text(
                'Calm Your Mind',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentCycle + 1} / ${widget.cycles} Cycles',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // Breathing circle
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating ring
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (ctx, child) {
                        return Transform.rotate(
                          angle: _ringController.value * 2 * pi,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.gemColor.withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 125,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppTheme.gemColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.gemColor
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Breathing circle
                    AnimatedBuilder(
                      animation: _breathAnimation,
                      builder: (ctx, _) {
                        final scale = _breathAnimation.value;
                        return Container(
                          width: 180 * scale,
                          height: 180 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (_isInhaling
                                        ? AppTheme.gemColor
                                        : AppTheme.accentPurple)
                                    .withValues(alpha: 0.3),
                                (_isInhaling
                                        ? AppTheme.gemColor
                                        : AppTheme.accentPurple)
                                    .withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: (_isInhaling
                                      ? AppTheme.gemColor
                                      : AppTheme.accentPurple)
                                  .withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isInhaling
                                        ? AppTheme.gemColor
                                        : AppTheme.accentPurple)
                                    .withValues(alpha: 0.2 * scale),
                                blurRadius: 30 * scale,
                                spreadRadius: 5 * scale,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Instruction text
                    Text(
                      _instruction,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Motivational text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Deep breathing increases oxygen to the brain,\nimproving focus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
