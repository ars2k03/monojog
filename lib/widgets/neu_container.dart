import 'dart:ui';
import 'package:flutter/material.dart';

class NeuContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final bool isPressed;
  final BoxShape shape;
  final BoxBorder? border;

  const NeuContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.isPressed = false,
    this.shape = BoxShape.rectangle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // Premium glassmorphic card for dark mode
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(20)),
          shape: shape,
          border: border ??
              Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E2E).withValues(alpha: isPressed ? 0.7 : 0.95),
              const Color(0xFF16161F).withValues(alpha: isPressed ? 0.5 : 0.85),
            ],
          ),
          boxShadow: isPressed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.02),
                    offset: const Offset(0, -1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: shape == BoxShape.circle
              ? BorderRadius.circular(999)
              : (borderRadius as BorderRadius? ?? BorderRadius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      );
    }

    // Light mode - classic neumorphic
    const bgColor = Color(0xFFE0E5EC);
    const lightShadow = Colors.white;
    const darkShadow = Color(0xFFA3B1C6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(20)),
        shape: shape,
        border: border,
        boxShadow: isPressed
            ? null
            : [
                const BoxShadow(
                  color: darkShadow,
                  offset: Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: lightShadow,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}
