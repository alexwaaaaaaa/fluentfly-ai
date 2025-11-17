import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state
enum AppThemeMode { light, dark, system }

/// Theme state notifier that manages theme mode and persistence
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(AppThemeMode.dark) {
    _loadTheme();
  }

  /// Load theme preference from shared preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);

      if (themeString != null) {
        state = AppThemeMode.values.firstWhere(
          (mode) => mode.name == themeString,
          orElse: () => AppThemeMode.dark,
        );
      }
    } catch (e) {
      // If loading fails, keep default dark theme
      debugPrint('Error loading theme: $e');
    }
  }

  /// Set theme mode and persist to shared preferences
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (state == AppThemeMode.dark) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.dark);
    }
  }

  /// Get the actual ThemeMode for Flutter
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider for getting the actual ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  ref.watch(themeProvider); // Watch for changes
  final notifier = ref.read(themeProvider.notifier);
  return notifier.themeMode;
});

/// Provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == AppThemeMode.dark;
});
