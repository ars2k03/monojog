import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:monojog/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

enum CheckEmailMode { verification, passwordReset }

class CheckEmailScreen extends StatefulWidget {
  final String email;
  final CheckEmailMode mode;

  const CheckEmailScreen({
    super.key,
    required this.email,
    required this.mode,
  });

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  bool _isResending = false;
  bool _resentSuccess = false;

  @override
  void dispose() {
    super.dispose();
  }

  // ── Open Email App ────────────────────────────────────────────────────
  Future<void> _openEmailApp() async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        final Uri emailUri = Uri.parse('message://');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          _showErrorSnackbar('Could not open email app');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Could not open email app');
    }
  }

  // ── Resend Email ──────────────────────────────────────────────────────
  Future<void> _handleResend() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });

    final auth = context.read<AuthProvider>();

    bool success;
    if (widget.mode == CheckEmailMode.verification) {
      success = await auth.resendEmailVerification();
    } else {
      success = await auth.sendPasswordReset(widget.email);
    }

    if (!mounted) return;

    setState(() {
      _isResending = false;
      _resentSuccess = success;
    });

    if (!success) {
      _showErrorSnackbar('Failed to send email. Please try again.');
    }

    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _resentSuccess = false);
    }
  }

  void _goToLogin() {
    final auth = context.read<AuthProvider>();
    auth.signOut();

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: isDark? Colors.black : Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark? Colors.black : Colors.white
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? Colors.white : Colors.black,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive Colors ──────────────────────────────────────────────────
    final bgColor         = isDark ? AppTheme.darkBg : const Color(0xFFF5F4FF);
    final cardColor       = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final cardBorder      = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;
    final textPrimary     = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary   = isDark ? Colors.white.withValues(alpha: 0.65) : Colors.grey.shade600;
    final emailChipBg     = isDark ? AppTheme.primaryColor.withValues(alpha: 0.18) : AppTheme.primaryColor.withValues(alpha: 0.18);
    final emailChipBorder = AppTheme.primaryColor.withValues(alpha: 0.45);
    final dividerColor    = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;

    final isVerification = widget.mode == CheckEmailMode.verification;
    final title       = isVerification ? 'Verify Your Email' : 'Check Your Email';
    final subtitle    = isVerification
        ? 'We sent a verification link to the email below:'
        : 'We sent a password reset link to the email below:';
    final instruction = isVerification
        ? 'Click the link in the email to verify your account. Once verified, you can sign in.'
        : 'Click the link in the email to set a new password.';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ── Icon ────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ────────────────────────────────────────────
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // ── Subtitle ─────────────────────────────────────────
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // ── Email Chip ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: emailChipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: emailChipBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.email,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Info Card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.open_in_new_rounded,
                      text: instruction,
                      textColor: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.folder_outlined,
                      text: "Can't find the email? Check your spam or junk folder.",
                      textColor: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.timer_outlined,
                      text: 'The link will expire in 1 hour. Request a new one if needed.',
                      textColor: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Open Email App Button ────────────────────────────
              _buildOpenEmailButton(isDark),

              const SizedBox(height: 14),

              // ── Go to Sign In Button ─────────────────────────────
              _buildLoginButton(),

              const SizedBox(height: 20),

              // ── Resend Section ───────────────────────────────────
              _buildResendSection(textSecondary, isDark),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Open Email App Button ─────────────────────────────────────────────
  Widget _buildOpenEmailButton(bool isDark) {
    return GestureDetector(
      onTap: _openEmailApp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ?  Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red,
            width: 1.8,
          ),

        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.open_in_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 10),
            Text(
              'Open Email App',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Login Button ──────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Go to Sign In',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── Resend Section ────────────────────────────────────────────────────
  Widget _buildResendSection(Color textSecondary, bool isDark) {
    if (_resentSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Email sent successfully!',
              style: GoogleFonts.inter(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isResending ? null : _handleResend,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Didn't receive the email? ",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            _isResending
                ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark? AppTheme.primaryColor : Colors.red,
              ),
            )
                : Text(
              'Resend',
              style: GoogleFonts.inter(
                color: isDark? AppTheme.primaryColor : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Row ──────────────────────────────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color textColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : AppTheme.primaryColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isDark? AppTheme.primaryColor : Colors.black),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}