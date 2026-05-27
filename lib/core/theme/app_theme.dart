import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF03121C);
  static const Color secondaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFFDFDFD);

  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  static const Color textDark = Color(0xFF03121C);
  static const Color textLight = Color(0xFF717171);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: const TextTheme().apply(fontFamily: 'Cairo').copyWith(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        bodyLarge: const TextStyle(
          color: textDark,
        ),
        bodyMedium: const TextStyle(
          color: textLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Cairo', color: primaryColor, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 340,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  static void showSnack(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message, 
        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white), 
        textAlign: TextAlign.center,
      ),
      backgroundColor: color ?? successColor,
      behavior: SnackBarBehavior.floating,
      width: 340,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  static String formatScore(double score) {
    if (score == score.truncateToDouble()) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
  }
}
