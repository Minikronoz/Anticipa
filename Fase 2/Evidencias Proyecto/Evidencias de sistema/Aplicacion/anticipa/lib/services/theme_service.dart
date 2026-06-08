import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_config';

  static Future<ThemeConfig> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_themeKey);
    if (json == null) return ThemeConfig.defaultTheme();
    try {
      return ThemeConfig.fromJson(jsonDecode(json));
    } catch (_) {
      return ThemeConfig.defaultTheme();
    }
  }

  static Future<void> saveTheme(ThemeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, jsonEncode(config.toJson()));
  }

  static Future<void> resetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}