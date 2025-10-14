import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryBlue = Color(0xFF1976D2);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF757575);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF212121);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: white,
      ),
    );
  }

  // Status colors
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return errorRed;
      case 'In Progress':
        return warningOrange;
      case 'Resolved':
        return successGreen;
      default:
        return darkGrey;
    }
  }

  // Issue type colors
  static Color getIssueTypeColor(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'pothole':
        return const Color(0xFF8D6E63);
      case 'garbage':
        return const Color(0xFF795548);
      case 'water leak':
        return const Color(0xFF2196F3);
      case 'street light':
        return const Color(0xFFFFC107);
      case 'traffic':
        return const Color(0xFFF44336);
      case 'road damage':
        return const Color(0xFF607D8B);
      case 'sewage':
        return const Color(0xFF795548);
      case 'other':
        return const Color(0xFF9E9E9E);
      default:
        return darkGrey;
    }
  }
}
