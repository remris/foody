import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

/// Unterstützte Sprachen in Kokomi
enum AppLanguage {
  system('System', null, '🌐'),
  german('Deutsch', Locale('de'), '🇩🇪'),
  english('English', Locale('en'), '🇬🇧'),
  turkish('Türkçe', Locale('tr'), '🇹🇷'),
  spanish('Español', Locale('es'), '🇪🇸'),
  french('Français', Locale('fr'), '🇫🇷');

  final String label;
  final Locale? locale;
  final String flag;
  const AppLanguage(this.label, this.locale, this.flag);
}

class LocaleNotifier extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved == null) return AppLanguage.system;
    return AppLanguage.values.firstWhere(
      (l) => l.name == saved,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> setLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, lang.name);
    state = AsyncData(lang);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLanguage>(
  LocaleNotifier.new,
);

/// Gibt die aktive Locale zurück (null = System-Default)
final activeLocaleProvider = Provider<Locale?>((ref) {
  return ref.watch(localeProvider).valueOrNull?.locale;
});

