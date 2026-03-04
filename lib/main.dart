import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monojog/firebase_options.dart';
import 'package:monojog/theme/theme_provider.dart';
import 'package:monojog/providers/auth_provider.dart';
import 'package:monojog/providers/study_provider.dart';
import 'package:monojog/providers/focus_provider.dart';
import 'package:monojog/providers/game_provider.dart';
import 'package:monojog/providers/study_room_provider.dart';
import 'package:monojog/providers/locale_provider.dart';
import 'package:monojog/providers/sleep_provider.dart';
import 'package:monojog/providers/habit_provider.dart';
import 'package:monojog/providers/task_provider.dart';
import 'package:monojog/start_page/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => StudyRoomProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SleepProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const MonojogApp(),
    ),
  );
}

class MonojogApp extends StatelessWidget {
  const MonojogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Monojog',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),

      themeMode: themeProvider.themeMode,

      // 🔥 Magic part
      builder: (context, child) {
        final isDark =
            Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
            isDark ? Colors.black : Colors.white,
            systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },

      home: const SplashScreen(),
    );
  }
}