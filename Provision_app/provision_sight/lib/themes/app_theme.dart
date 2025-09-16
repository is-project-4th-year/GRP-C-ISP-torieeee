// themes/app_themes.dart
import 'package:flutter/material.dart';

class AppThemes {
  static final darkGreenTheme = ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Color(0xFF1B5E20), // Dark green
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: Color(0xFF121212), // Dark background
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.greenAccent),
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF2E7D32),
      elevation: 4,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFF1B5E20),
      textTheme: ButtonTextTheme.primary,
    ),
    appBarTheme: AppBarTheme(
      color: Color(0xFF1B5E20),
      iconTheme: IconThemeData(color: Colors.white),
    ),
  );
}