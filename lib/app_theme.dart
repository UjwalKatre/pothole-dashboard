import 'package:flutter/material.dart';

class AppTheme {
  // Government of India color palette - light theme
  static const Color primaryBlue = Color(0xFF003580);
  static const Color accentOrange = Color(0xFFFF6600);
  static const Color lightBlue = Color(0xFF0066CC);
  static const Color successGreen = Color(0xFF1A7A40);
  static const Color warningAmber = Color(0xFFF5A623);
  static const Color errorRed = Color(0xFFCC0000);
  static const Color backgroundGrey = Color(0xFFF0F4F8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFDDE3EC);
  static const Color textDark = Color(0xFF1A2332);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: lightBlue,
        error: errorRed,
        background: backgroundGrey,
        surface: cardWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: borderGrey, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: accentOrange,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textMedium, fontSize: 14),
        bodyMedium: TextStyle(color: textMedium, fontSize: 13),
        bodySmall: TextStyle(color: textLight, fontSize: 12),
        labelLarge: TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderGrey,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return errorRed;
      case 'high':
        return const Color(0xFFE53E3E);
      case 'medium':
        return warningAmber;
      default:
        return successGreen;
    }
  }

  static Color severityBg(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFFEBEB);
      case 'high':
        return const Color(0xFFFFF0F0);
      case 'medium':
        return const Color(0xFFFFF8E6);
      default:
        return const Color(0xFFEBF5EE);
    }
  }
}
