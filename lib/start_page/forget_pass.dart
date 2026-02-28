import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/auth_provider.dart';
import 'package:monojog/start_page/verification.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Firebase Password Reset ───────────────────────────────────────────
  Future<void> _handleSendLink() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(_emailCtrl.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CheckEmailScreen(
          email: _emailCtrl.text.trim(),
          mode: CheckEmailMode.passwordReset,
        )),
      );
    } else {
      _showErrorSnackbar(
          auth.error ?? 'Could not send reset email. Please try again.');
    }
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

  // ── Validator ─────────────────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    // ── Adaptive Colors ─────────────────────────────────────────────────
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFFF5F4FF);
    final cardColor =
    isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorder =
    isDark ? Colors.white.withValues(alpha: 0.09) : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
    isDark ? AppTheme.darkTextSec : Colors.grey.shade600;
    final inputFill =
    isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50;
    final inputBorder =
    isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;
    final inputFocusBorder =
    AppTheme.primaryColor.withValues(alpha: isDark ? 0.7 : 0.9);
    final hintColor =
    isDark ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Back Button ───────────────────────────────────
              _buildBackButton(isDark, textPrimary),

              const SizedBox(height: 32),

              // ── Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor
                            .withValues(alpha: isDark ? 0.3 : 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────
              Center(
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "No worries! We'll send a reset link to your email.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // ── Card ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cardBorder),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email',
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "We'll send a password reset link to this address.",
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Email Field ─────────────────────────────
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSendLink(),
                        style: GoogleFonts.inter(
                            color: textPrimary, fontSize: 15),
                        autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'example@email.com',
                          hintStyle: GoogleFonts.inter(
                              color: hintColor, fontSize: 14),
                          labelStyle: GoogleFonts.inter(
                              color: textSecondary, fontSize: 14),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: textSecondary, size: 20),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                            BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                            BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: inputFocusBorder, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Colors.redAccent, width: 1.5),
                          ),
                          errorStyle: GoogleFonts.inter(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                        validator: _validateEmail,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Send Button ─────────────────────────────
                    _buildSendButton(isLoading),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Back to Login
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            size: 15,
                            color: isDark? AppTheme.primaryColor : Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Back to Sign In',
                          style: GoogleFonts.inter(
                            color: isDark? AppTheme.primaryColor : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Back Button ───────────────────────────────────────────────────────
  Widget _buildBackButton(bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
        Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
      ),
    );
  }

  // ── Send Button ───────────────────────────────────────────────────────
  Widget _buildSendButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleSendLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isLoading
              ? AppTheme.primaryColor.withValues(alpha: 0.6)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
            BoxShadow(
              color:
              const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
              key: ValueKey('loader'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              'Send Reset Link',
              key: const ValueKey('text'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}