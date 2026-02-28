import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bilingual support: Bengali (bn) and English (en)
class LocaleProvider with ChangeNotifier {
  String _locale = 'en'; // Default English

  String get locale => _locale;
  bool get isBengali => _locale == 'bn';
  bool get isEnglish => _locale == 'en';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_locale') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'bn' ? 'en' : 'bn');
  }

  /// Get translated string by key
  String t(String key) {
    return (_strings[_locale]?[key]) ?? (_strings['en']?[key]) ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'bn': {
      // Nav
      'home': 'হোম',
      'monojog_room': 'মনোযোগ রুম',
      'add_task': 'টাস্ক যোগ',
      'my_account': 'আমার অ্যাকাউন্ট',
      'app_name': 'মনোযোগ',

      // Home
      'dashboard': 'ড্যাশবোর্ড',
      'start_focus': 'ফোকাস সেশন',
      'start_focus_desc': 'ফোকাস টাইমার শুরু করুন',
      'habits': 'অভ্যাস ট্র্যাকার',
      'habits_desc': 'দৈনন্দিন অভ্যাস ট্র্যাক করুন',
      'brain_dump': 'ব্রেইন ডাম্প',
      'brain_dump_desc': 'চিন্তাগুলো লিখে রাখুন',
      'app_block': 'অ্যাপ ব্লক',
      'app_block_desc': 'বিক্ষিপ্ততা কমান',
      'subjects': 'বিষয় ও লক্ষ্য',
      'subjects_desc': 'বিষয়ভিত্তিক লক্ষ্য সেট করুন',
      'session_history': 'সেশন ইতিহাস',
      'session_history_desc': 'আপনার ফোকাস ইতিহাস দেখুন',
      'settings': 'সেটিংস',
      'settings_desc': 'অ্যাপ কাস্টমাইজ করুন',
      'daily_goal': 'দৈনিক লক্ষ্য',
      'weekly_goal': 'সাপ্তাহিক লক্ষ্য',
      'today_focus': 'আজকের ফোকাস',

      // Account
      'statistics': 'পরিসংখ্যান',
      'rewards_rank': 'পুরস্কার ও র‍্যাঙ্ক',
      'total_focus': 'মোট ফোকাস',
      'sessions_done': 'সেশন সম্পন্ন',
      'current_streak': 'বর্তমান স্ট্রিক',
      'longest_streak': 'সর্বোচ্চ স্ট্রিক',
      'days': 'দিন',
      'min': 'মি',
      'your_progress': 'আপনার অগ্রগতি',
      'weekly_focus': 'সাপ্তাহিক ফোকাস (মিনিট)',
      'shop': 'দোকান',
      'ranks': 'র‍্যাঙ্ক',
      'current': 'বর্তমান',

      // Login
      'sign_in': 'লগইন',
      'sign_up': 'অ্যাকাউন্ট তৈরি',
      'offline_mode': 'অফলাইনে ব্যবহার করুন',
      'offline_desc': 'ইন্টারনেট ছাড়া চালান, ডেটা লোকালে সেভ হবে',
      'or': 'অথবা',
      'email': 'ইমেইল',
      'password': 'পাসওয়ার্ড',
      'name': 'আপনার নাম',
      'confirm_password': 'পাসওয়ার্ড নিশ্চিত করুন',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'google_login': 'Google দিয়ে চালিয়ে যান',
      'guest_login': 'গেস্ট হিসেবে চালিয়ে যান',
      'create_account': 'অ্যাকাউন্ট তৈরি করুন',
      'login_btn': 'লগইন করুন',
      'tagline': 'মনোযোগ দিন। ভালো অভ্যাস গড়ুন।',

      // Focus
      'focus_active_warning': 'ফোকাস সেশন চলাকালীন অন্য ফিচারে যাওয়া যাবে না।',
      'focus_stay_warning': 'ফোকাস শেষ না হওয়া পর্যন্ত এই ট্যাবেই থাকুন।',

      // Ranks (chess-style)
      'novice': 'শিক্ষানবিশ',
      'candidate_master': 'ক্যান্ডিডেট মাস্টার',
      'fide_master': 'ফিদে মাস্টার',
      'international_master': 'ইন্টারন্যাশনাল মাস্টার',
      'grandmaster': 'গ্র্যান্ডমাস্টার',
      'super_grandmaster': 'সুপার গ্র্যান্ডমাস্টার',
      'world_champion': 'বিশ্ব চ্যাম্পিয়ন',

      // Anti-cheat
      'idle_penalty': 'নিষ্ক্রিয়তার জন্য সময় কাটা হয়েছে!',
      'app_switch_penalty': 'অ্যাপ ছেড়ে যাওয়ায় পেনাল্টি!',

      // General
      'coming_soon': 'শীঘ্রই আসছে!',
      'cancel': 'বাতিল',
      'ok': 'ঠিক আছে',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'save': 'সংরক্ষণ',
      'language': 'ভাষা',
    },
    'en': {
      // Nav
      'home': 'Home',
      'monojog_room': 'Monojog Room',
      'add_task': 'Add Task',
      'my_account': 'My Account',
      'app_name': 'Monojog',

      // Home
      'dashboard': 'Dashboard',
      'start_focus': 'Focus Session',
      'start_focus_desc': 'Start a focus timer',
      'habits': 'Habit Tracker',
      'habits_desc': 'Track your daily habits',
      'brain_dump': 'Brain Dump',
      'brain_dump_desc': 'Write down your thoughts',
      'app_block': 'App Block',
      'app_block_desc': 'Reduce distractions',
      'subjects': 'Subjects & Goals',
      'subjects_desc': 'Set subject-based goals',
      'session_history': 'Session History',
      'session_history_desc': 'View your focus history',
      'settings': 'Settings',
      'settings_desc': 'Customize the app',
      'daily_goal': 'Daily Goal',
      'weekly_goal': 'Weekly Goal',
      'today_focus': "Today's Focus",

      // Account
      'statistics': 'Statistics',
      'rewards_rank': 'Rewards & Rank',
      'total_focus': 'Total Focus',
      'sessions_done': 'Sessions Done',
      'current_streak': 'Current Streak',
      'longest_streak': 'Longest Streak',
      'days': 'days',
      'min': 'min',
      'your_progress': 'Your Progress',
      'weekly_focus': 'Weekly Focus (minutes)',
      'shop': 'Shop',
      'ranks': 'Ranks',
      'current': 'Current',

      // Login
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'offline_mode': 'Use Offline',
      'offline_desc': 'Use without internet, data saved locally',
      'or': 'or',
      'email': 'Email',
      'password': 'Password',
      'name': 'Your Name',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'google_login': 'Continue with Google',
      'guest_login': 'Continue as Guest',
      'create_account': 'Create Account',
      'login_btn': 'Log In',
      'tagline': 'Focus Better. Build Better Habits.',

      // Focus
      'focus_active_warning': 'Cannot navigate while focus session is active.',
      'focus_stay_warning': 'Stay on this tab until focus ends.',

      // Ranks
      'novice': 'Novice',
      'candidate_master': 'Candidate Master',
      'fide_master': 'FIDE Master',
      'international_master': 'International Master',
      'grandmaster': 'Grandmaster',
      'super_grandmaster': 'Super Grandmaster',
      'world_champion': 'World Champion',

      // Anti-cheat
      'idle_penalty': 'Time deducted for being idle!',
      'app_switch_penalty': 'Penalty for leaving the app!',

      // General
      'coming_soon': 'Coming Soon!',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'language': 'Language',
    },
  };
}
