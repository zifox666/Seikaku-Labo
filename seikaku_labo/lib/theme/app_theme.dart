import 'package:flutter/material.dart';

/// EVE Online 风格深色主题
class AppTheme {
  AppTheme._();

  // EVE Online 色调
  static const Color _primaryColor = Color(0xFF3A9BDC); // EVE 蓝
  static const Color _accentColor = Color(0xFFE8A33D); // EVE 金/橙
  static const Color _surfaceColor = Color(0xFF1A1A2E); // 深空背景
  static const Color _cardColor = Color(0xFF16213E); // 面板背景
  static const Color _scaffoldBg = Color(0xFF0F0F1A); // 最深背景
  static const Color _errorColor = Color(0xFFCF6679);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'W04',
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: _surfaceColor,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white70,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: _scaffoldBg,
      cardColor: _cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceColor,
        indicatorColor: _primaryColor.withAlpha(60),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.white54, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryColor);
          }
          return const IconThemeData(color: Colors.white54);
        }),
      ),
      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _primaryColor.withAlpha(40)),
        ),
      ),
      dividerColor: Colors.white12,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
        labelLarge: TextStyle(color: _primaryColor),
      ),
    );
  }
}
