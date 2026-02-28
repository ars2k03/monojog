import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:monojog/providers/auth_provider.dart';
import 'package:monojog/start_page/verification.dart';
import '../screens/main_screen.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool isGoogleLoading = false;
  bool isLoading = false;



  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Firebase Email Sign Up ────────────────────────────────────────────
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ UX: Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });


    final auth = context.read<AuthProvider>();
    final success = await auth.signUpWithEmail(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });


    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CheckEmailScreen(
          email: _emailCtrl.text.trim(),
          mode: CheckEmailMode.verification,
        )),
      );
    } else {
      _showErrorSnackbar(auth.error ?? 'Sign up failed. Please try again.');
    }
  }

  // ── Google Sign Up ────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => isGoogleLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;

    setState(() => isGoogleLoading = false);

    if (success) {
      // ✅ Google sign-in → straight to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CheckEmailScreen(
          email: _emailCtrl.text.trim(),
          mode: CheckEmailMode.verification,
        )),
      );

    } else if (auth.error != null) {
      _showErrorSnackbar(auth.error!);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive Colors ─────────────────────────────────────────────────
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFFF5F4FF);
    final cardColor =
    isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorder =
    isDark ? Colors.white.withValues(alpha: 0.09) : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
    isDark ? AppTheme.darkTextSec : Colors.grey.shade600;
    final dividerColor =
    isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey;
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ── Logo ──────────────────────────────────────────
              RepaintBoundary(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor
                            .withValues(alpha: isDark ? 0.3 : 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/tree.png',
                    cacheWidth: 144,
                    cacheHeight: 144,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Create Account',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Start your focus journey today 🌱',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Main Card ─────────────────────────────────────
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
                  children: [
                    // ── Google Button ────────────────────────────
                    _buildGoogleButton(isDark, isGoogleLoading),

                    const SizedBox(height: 22),

                    // ── Divider ─────────────────────────────────
                    _buildDivider(dividerColor, textSecondary),

                    const SizedBox(height: 22),

                    // ── Form ────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            hint: 'Enter your name',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            inputFill: inputFill,
                            inputBorder: inputBorder,
                            inputFocusBorder: inputFocusBorder,
                            hintColor: hintColor,
                            validator: _validateName,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'example@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            inputFill: inputFill,
                            inputBorder: inputBorder,
                            inputFocusBorder: inputFocusBorder,
                            hintColor: hintColor,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            inputFill: inputFill,
                            inputBorder: inputBorder,
                            inputFocusBorder: inputFocusBorder,
                            hintColor: hintColor,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _confirmPassCtrl,
                            label: 'Confirm Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSignUp(),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            inputFill: inputFill,
                            inputBorder: inputBorder,
                            inputFocusBorder: inputFocusBorder,
                            hintColor: hintColor,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                              _obscureConfirmPass =
                              !_obscureConfirmPass),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Submit Button ───────────────────────────
                    _buildSubmitButton(isDark, isLoading),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Sign In Link ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.inter(
                        color: textSecondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  //Google Sign In Button
  Widget _buildGoogleButton(bool isDark, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white : Colors.black,
              width: 1.5,
            ),
          ),
          elevation: 0,
        ),
        child: isLoading? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: isDark? Colors.white : Colors.black,
            backgroundColor: isDark? Colors.black : Colors.white ,
            strokeWidth: 2,
          ),
        ) : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google.png',
              height: 22,
              width: 22,
              cacheWidth: 44,
              cacheHeight: 44,
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────
  Widget _buildDivider(Color dividerColor, Color textColor) {
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 0.8)),
      ],
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required Color inputFill,
    required Color inputBorder,
    required Color inputFocusBorder,
    required Color hintColor,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: GoogleFonts.inter(color: textPrimary, fontSize: 15),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputFill,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: inputFocusBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle:
        GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isDark, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : _handleSignUp,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade300,
            width: 1.5,
          ),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: isLoading? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ) : Text(
              'Sign Up',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Validators ────────────────────────────────────────────────────────
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}