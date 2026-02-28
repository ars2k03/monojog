import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:monojog/start_page/login_screen.dart';
import 'package:monojog/screens/main_screen.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:monojog/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final String _fullText = 'শান্ত ছোট্ট গাছের মতো মনোযোগ বাড়াও';
  String _displayedText = '';
  bool _showCursor = true;
  bool _isChecking = false;
  Timer? _typingTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.4, 0),
    ).animate(
        CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    _startTyping();
    _startCursorBlink();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    int charIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < _fullText.length) {
        setState(() => _displayedText = _fullText.substring(0, charIndex + 1));
        charIndex++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _displayedText = '');
          _startTyping();
        });
      }
    });
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _showCursor = !_showCursor);
    });
  }

  // FirebaseAuth.instance.currentUser check
  void _handleStart() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final auth = context.read<AuthProvider>();

    // SharedPreferences load wait
    if (!auth.isOfflineModeLoaded) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return !context.read<AuthProvider>().isOfflineModeLoaded;
      });
    }

    if (!mounted) return;

    if (auth.isOfflineMode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? const MainScreen() : const LoginScreen(),
      ),
    );

    setState(() => _isChecking = false);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Lottie.asset('assets/images/Book loading.json'),
                  const SizedBox(height: 60),
                  _buildText(isDarkMode),
                  const SizedBox(height: 150),
                  _buildButton(isDarkMode),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(bool isDarkMode) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF00E5FF), Color(0xFF2979FF)] // Dark: bright cyan → blue
              : [Color(0xFF0091EA), Color(0xFF1565C0)], // Light: deeper cyan → deep blue (better contrast)
        ).createShader(bounds),
          child: Text(
            'মনোযোগ',
            style: GoogleFonts.notoSerifBengali(
              fontSize: 50,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),

        const SizedBox(height: 15),

        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: _displayedText),
              TextSpan(
                text: _showCursor ? '|' : ' ',
                style: GoogleFonts.notoSerifBengali(
                  color: const Color(0xFFFF0000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          style: GoogleFonts.notoSerifBengali(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.7),
            letterSpacing: 0.3,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(bool isDarkMode) {
    return SizedBox(
      width: 200,
      height: 60,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C27B0),
                Color(0xFF7B1FA2),
                Color(0xFF4A148C),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            onTap: _handleStart,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isChecking)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[

                  Text(
                    'শুরু করুন',
                    style: GoogleFonts.notoSerifBengali(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}