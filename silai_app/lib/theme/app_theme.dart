import 'package:flutter/material.dart';


class AppColors {
  // Core theme colors
  static const Color primary = Color(0xFF9E4B3B); 
  // ... any other unique core colors you have ...

  // Blueprint theme colors (Ensure there is only ONE of each below)
  static const Color cream = Color(0xFFFDFBF7);
  static const Color white = Colors.white;
  static const Color divider = Color(0xFFEFEBE4);
  static const Color espresso = Color(0xFF2A1E17);
  static const Color textMuted = Color(0xFF8A7F75);
  static const Color iconMuted = Color(0xFFC4BDB3);
  static const Color blushLight = Color(0xFFFBEFEA);
  static const Color brick = Color(0xFF9E4B3B);
  static const Color terracotta = Color(0xFFC87A65);
  static const Color dustyRose = Color(0xFFE8C3BA);
  static const Color walnut = Color(0xFF5A4538);
  static const Color cardBg = Colors.white; // Or Color(0xFFFFFFFF) / Color(0xFFFDFBF7)
  static const Color softWhite = Color(0xFFF9F9F9);

}
class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Lato',
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.light(
          primary: AppColors.terracotta,
          secondary: AppColors.dustyRose,
          surface: AppColors.cardBg,
          onPrimary: AppColors.white,
          onSecondary: AppColors.espresso,
          onSurface: AppColors.espresso,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.brick),
          titleTextStyle: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.brick,
          unselectedItemColor: AppColors.iconMuted,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brick,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.softWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
}
