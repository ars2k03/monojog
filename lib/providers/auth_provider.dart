import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '437910509347-qahcmrgsjaqd12hlpbvkb5a4262eq9be.apps.googleusercontent.com',
  );

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  bool _isOfflineModeLoaded = false;

  static const String _offlineModeKey = 'is_offline_mode';
  static const String _avatarKey = 'profile.avatar';

  String _avatarType = 'warrior';

  // ── Getters ──────────────────────────────────────────────────────────────
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_isOfflineMode;
  bool get isOfflineMode => _isOfflineMode;
  bool get isInitialized => _isInitialized;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isOfflineModeLoaded => _isOfflineModeLoaded;
  String get avatarType => _avatarType;

  AuthProvider() {
    _initAuth();
  }

  // ── Auth State Listener ──────────────────────────────────────────────────
  void _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(_offlineModeKey) ?? false;
    _avatarType = prefs.getString(_avatarKey) ?? 'warrior';
    _isOfflineModeLoaded = true;
    notifyListeners();

    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  // ── Google Sign In ───────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearErrorSilent();

      // আগের sign in clear করো
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false; // user নিজে cancel করেছে
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _error = 'Google authentication tokens are missing. Please try again.';
        _setLoading(false);
        return false;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final googleName = googleUser.displayName?.trim();
      final currentName = userCredential.user?.displayName?.trim();
      if ((currentName == null || currentName.isEmpty) &&
          googleName != null &&
          googleName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(googleName);
        await userCredential.user?.reload();
        _user = _auth.currentUser;
      }

      _isOfflineMode = false;
      await _saveOfflineMode(false);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} — ${e.message}');
      _error = _mapFirebaseError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('sign_in_canceled')) {
        _setLoading(false);
        return false;
      }
      _error = 'Google sign-in failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Email Sign In ────────────────────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearErrorSilent();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _isOfflineMode = false;
      await _saveOfflineMode(false);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      debugPrint('Email Sign-In Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // ── Email Sign Up ────────────────────────────────────────────────────────
  Future<bool> signUpWithEmail(
      String name, String email, String password) async {
    try {
      _setLoading(true);
      _clearErrorSilent();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
        _user = _auth.currentUser;
      }

      await credential.user?.sendEmailVerification();

      _isOfflineMode = false;
      await _saveOfflineMode(false);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Sign up failed. Please try again.';
      debugPrint('Email Sign-Up Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // ── Send Password Reset ──────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _clearErrorSilent();
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Could not send reset email. Please try again.';
      debugPrint('Reset Password Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // ── Resend Email Verification ────────────────────────────────────────────
  Future<bool> resendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (e) {
      debugPrint('Resend verification error: $e');
      return false;
    }
  }

  // ── Check Email Verified ─────────────────────────────────────────────────
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return _user?.emailVerified ?? false;
    } catch (e) {
      debugPrint('Check email verified error: $e');
      return false;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _isOfflineMode = false;
    await _saveOfflineMode(false);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }

  // ── Delete Account ───────────────────────────────────────────────────────
  /// Email user হলে password দিয়ে re-authenticate করে delete করে।
  /// Google user হলে Google re-authenticate করে delete করে।
  Future<bool> deleteAccount({String password = ''}) async {
    try {
      _setLoading(true);
      _clearErrorSilent();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _error = 'No user is currently signed in.';
        _setLoading(false);
        return false;
      }

      final isGoogleUser =
      currentUser.providerData.any((p) => p.providerId == 'google.com');

      if (isGoogleUser) {
        // Google re-authentication
        try {
          final googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            _setLoading(false);
            return false;
          }
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await currentUser.reauthenticateWithCredential(credential);
        } catch (e) {
          _error = 'Re-authentication failed. Please try again.';
          _setLoading(false);
          return false;
        }
      } else {
        // Email/password re-authentication
        if (password.isEmpty) {
          _error = 'Please enter your password to confirm.';
          _setLoading(false);
          return false;
        }
        try {
          final email = currentUser.email ?? '';
          final credential = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await currentUser.reauthenticateWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          _error = _mapFirebaseError(e.code);
          _setLoading(false);
          return false;
        }
      }

      // Firebase account delete
      await currentUser.delete();

      // Local cleanup
      _isOfflineMode = false;
      await _saveOfflineMode(false);
      _user = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Account deletion failed. Please try again.';
      debugPrint('Delete Account Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // ── Offline Mode ─────────────────────────────────────────────────────────
  Future<void> enterOfflineMode() async {
    _isOfflineMode = true;
    await _saveOfflineMode(true);
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ── Update Display Name ──────────────────────────────────────────────────
  Future<bool> updateDisplayName(String name) async {
    try {
      if (name.trim().isEmpty) return false;
      await _auth.currentUser?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update display name error: $e');
      return false;
    }
  }

  // ── Update Avatar ────────────────────────────────────────────────────────
  Future<void> updateAvatar(String avatarType) async {
    _avatarType = avatarType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarType);
    notifyListeners();
  }

  // ── SharedPreferences Helper ─────────────────────────────────────────────
  Future<void> _saveOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, value);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _clearErrorSilent() {
    _error = null;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // ── Error Mapping ────────────────────────────────────────────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      default:
        return 'Something went wrong. Please try again. ($code)';
    }
  }
}