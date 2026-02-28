import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // load save data
  ThemeProvider() {
    _loadTheme();
  }

  // Read saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme') ?? 'System default';

    if (savedTheme == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'Light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  // Change theme and saved theme
  Future<void> changeTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();

    if (theme == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'Light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    await prefs.setString('theme', theme);

    notifyListeners();
  }
}