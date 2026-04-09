import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:kokomu/core/constants/app_theme.dart';
import 'package:kokomu/core/router/app_router.dart';
import 'package:kokomu/core/services/notification_service.dart';
import 'package:kokomu/core/services/push_notification_service.dart';
import 'package:kokomu/core/services/theme_provider.dart';
import 'package:kokomu/core/services/locale_provider.dart';
import 'package:kokomu/features/onboarding/presentation/onboarding_screen.dart';

/// Ob der Onboarding-Flow schon abgeschlossen wurde.
final onboardingCompleteProvider = StateProvider<bool>((ref) => true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden
  await dotenv.load(fileName: '.env');

  // Supabase initialisieren
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Lokale Notifications initialisieren
  await NotificationService.initialize();

  // FCM Push Notifications initialisieren (benötigt google-services.json)
  // Schlägt still fehl wenn Firebase noch nicht konfiguriert ist
  await PushNotificationService.initialize();

  // Wochenzusammenfassung sonntags auslösen (max. 1× pro Tag)
  await _maybeSendWeeklySummary();

  // Onboarding-Status prüfen
  final onboardingDone = await isOnboardingComplete();

  // Sentry DSN aus .env (optional – wenn nicht gesetzt, kein Tracking)
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = 'production';
      },
      appRunner: () => _runApp(onboardingDone),
    );
  } else {
    _runApp(onboardingDone);
  }
}

void _runApp(bool onboardingDone) {
  runApp(ProviderScope(
    overrides: [
      onboardingCompleteProvider.overrideWith((ref) => onboardingDone),
    ],
    child: const kokomuApp(),
  ));
}

class kokomuApp extends ConsumerWidget {
  const kokomuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final colorScheme = ref.watch(colorSchemeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final activeLocale = ref.watch(activeLocaleProvider);

    return MaterialApp.router(
      title: 'kokomu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(colorScheme),
      darkTheme: AppTheme.dark(colorScheme),
      themeMode: themeMode,
      locale: activeLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('tr'),
        Locale('es'),
        Locale('fr'),
      ],
      routerConfig: router,
    );
  }
}

/// Sendet sonntags einmalig die Wochenzusammenfassung.
/// Liest Koch-Streak + Kochanzahl aus SharedPreferences.
Future<void> _maybeSendWeeklySummary() async {
  final now = DateTime.now();
  if (now.weekday != DateTime.sunday) return; // Nur sonntags

  final prefs = await SharedPreferences.getInstance();
  final lastSentKey = 'weekly_summary_last_sent';
  final lastSent = prefs.getString(lastSentKey);
  final todayStr = '${now.year}-${now.month}-${now.day}';

  if (lastSent == todayStr) return; // Heute schon gesendet

  // Werte aus SharedPreferences lesen (werden von den Providern gesetzt)
  final streak = prefs.getInt('cook_streak') ?? 0;
  // Gekochte Rezepte diese Woche zählen (via last_cooked_dates)
  final cookedRaw = prefs.getString('last_cooked_dates');
  int cookedThisWeek = 0;
  if (cookedRaw != null) {
    try {
      final list = (jsonDecode(cookedRaw) as List).cast<String>();
      final weekAgo = now.subtract(const Duration(days: 7));
      cookedThisWeek = list
          .where((d) {
            final date = DateTime.tryParse(d);
            return date != null && date.isAfter(weekAgo);
          })
          .length;
    } catch (_) {}
  }

  await NotificationService.showWeeklySummary(
    cookedCount: cookedThisWeek,
    streakDays: streak,
  );

  await prefs.setString(lastSentKey, todayStr);
}

