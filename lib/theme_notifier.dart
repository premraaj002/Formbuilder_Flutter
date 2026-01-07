import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'app_theme_mode';

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      setThemeFromString(savedTheme, persist: false);
    }
  }

  Future<void> setThemeMode(ThemeMode mode, {bool persist = true}) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeModeString);
    }
    
    notifyListeners();
  }

  Future<void> setThemeFromString(String? theme, {bool persist = true}) async {
    ThemeMode mode;
    switch (theme) {
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }
    await setThemeMode(mode, persist: persist);
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
      default:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  Color getThemeBasedColor(BuildContext context, {required Color lightColor, required Color darkColor}) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }
}


