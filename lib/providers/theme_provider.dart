import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // Default light mode
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkCard = Color(0xFF1E1E1E);
  static const darkCardMedium = Color(0xFF2D2D2D);

  // Light theme colors
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardMedium = Color(0xFFE0E0E0);

  // Common colors
  static const primaryGreen = Color(0xFF4CAF50);
  static const textDark = Color(0xFF212121);
  static const textLight = Color(0xFFFFFFFF);
  static const textGray = Color(0xFF9E9E9E);

  // Get colors based on theme
  Color get backgroundColor => _isDarkMode ? darkBackground : lightBackground;
  Color get cardColor => _isDarkMode ? darkCard : lightCard;
  Color get cardMediumColor => _isDarkMode ? darkCardMedium : lightCardMedium;
  Color get textColor => _isDarkMode ? textLight : textDark;
  Color get textSecondaryColor => textGray;
}
