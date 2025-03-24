import 'package:flutter/material.dart';
import 'screens/start_page.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true; // Default to dark mode

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set system overlay style
    SystemChrome.setSystemUIOverlayStyle(
      _isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return MaterialApp(
      title: 'Mausam Macha',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? darkTheme : lightTheme,
      home: StartPage(
        toggleTheme: toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

// Add these theme definitions
final darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF64FFDA),
    surface: Color(0xFF1A1A1A),
    background: Color(0xFF121212),
  ),
  useMaterial3: true,
  fontFamily: 'Tektur',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 32,
      letterSpacing: -0.5,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      letterSpacing: 0.15,
      color: Colors.white70,
    ),
    bodyLarge: TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: 0.5,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 14,
      letterSpacing: 0.25,
      color: Colors.white70,
    ),
  ),
);

final lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0288D1),
    secondary: Color(0xFF00ACC1),
    surface: Colors.white,
    background: Color(0xFFF5F5F5),
  ),
  useMaterial3: true,
  fontFamily: 'Tektur',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 32,
      letterSpacing: -0.5,
      color: Colors.black,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      letterSpacing: 0.15,
      color: Colors.black87,
    ),
    bodyLarge: TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: 0.5,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 14,
      letterSpacing: 0.25,
      color: Colors.black87,
    ),
  ),
);
