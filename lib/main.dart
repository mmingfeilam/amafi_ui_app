import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AmafiApp()); // CHANGE 1: AmafiApp → AmafiApp
}

class AmafiApp extends StatelessWidget {
  // CHANGE 2: AmafiApp → AmafiApp
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amafi AI', // CHANGE 3: 'Amafi AI' → 'Amafi AI'
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1E3A8A), // Keep this - it's good for finance
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
