import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kokomu/core/constants/color_schemes.dart';

const _colorSchemeKey = 'app_color_scheme';
const _themeModeKey = 'app_theme_mode';

/// Provider für das aktuelle Farbschema.
final colorSchemeProvider =
    NotifierProvider<ColorSchemeNotifier, AppColorScheme>(
  ColorSchemeNotifier.new,
);

/// Provider für den ThemeMode (hell/dunkel/system).
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ColorSchemeNotifier extends Notifier<AppColorScheme> {
  @override
  AppColorScheme build() {
    _loadFromPrefs();
    return AppColorScheme.kokomu; // Default
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_colorSchemeKey);
    if (saved != null) {
      final scheme = AppColorScheme.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => AppColorScheme.kokomu,
      );
      state = scheme;
    }
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, scheme.name);
  }
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system; // Default
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    if (saved != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

