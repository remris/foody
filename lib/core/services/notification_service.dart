import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service für lokale Push-Benachrichtigungen.
/// Kanäle:
///   expiry_channel   – Ablauf-Erinnerungen (MHD)
///   meal_channel     – Mahlzeit-Erinnerungen (Wochenplaner)
///   household_channel – Haushalt-Nachrichten & Chat
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification-IDs
  static const int _expiryId      = 0;
  static const int _mealReminderId = 1;
  static const int _householdId   = 2;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  // ── Kanal-Definitionen ──────────────────────────────────────────────────

  static const _expiryDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_channel', 'Ablauf-Erinnerungen',
      channelDescription: 'Benachrichtigungen wenn Lebensmittel bald ablaufen',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _mealDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_channel', 'Mahlzeit-Erinnerungen',
      channelDescription: 'Erinnerungen für geplante Mahlzeiten',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _householdDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'household_channel', 'Haushalt',
      channelDescription: 'Nachrichten und Aktivitäten im Haushalt',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ── MHD-Ablauf ──────────────────────────────────────────────────────────

  static Future<void> showExpiryNotification({
    required int count,
    required String itemNames,
  }) async {
    await initialize();
    if (!await isEnabled()) return;
    await _plugin.show(
      _expiryId,
      '⏰ $count Artikel ${count == 1 ? 'läuft' : 'laufen'} bald ab',
      itemNames,
      _expiryDetails,
    );
  }

  // ── Mahlzeit-Erinnerung ─────────────────────────────────────────────────

  /// Zeigt eine Mahlzeit-Erinnerung (z.B. "Heute Abend: Pasta Bolognese").
  static Future<void> showMealReminder({
    required String mealSlotLabel,
    required String recipeTitle,
  }) async {
    await initialize();
    if (!await isMealReminderEnabled()) return;
    await _plugin.show(
      _mealReminderId,
      '🍽️ $mealSlotLabel steht an',
      recipeTitle,
      _mealDetails,
    );
  }

  /// Zeigt eine Erinnerung für alle heutigen Mahlzeiten auf einmal.
  static Future<void> showTodayMealsNotification(
      List<String> mealTitles) async {
    await initialize();
    if (!await isMealReminderEnabled()) return;
    if (mealTitles.isEmpty) return;

    final body = mealTitles.length == 1
        ? mealTitles.first
        : mealTitles.join(' · ');

    await _plugin.show(
      _mealReminderId,
      '🍽️ Heute auf dem Plan',
      body,
      _mealDetails,
    );
  }

  // ── Wochenzusammenfassung ────────────────────────────────────────────────

  static const int _weeklyId = 3;

  static const _weeklyDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'weekly_channel', 'Wochenzusammenfassung',
      channelDescription: 'Sonntägliche Zusammenfassung deiner Kochaktivitäten',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Zeigt die Wochenzusammenfassung (wird sonntags ausgelöst).
  static Future<void> showWeeklySummary({
    required int cookedCount,
    required int streakDays,
    int? savedCalories,
  }) async {
    await initialize();
    if (!await isWeeklySummaryEnabled()) return;

    final body = StringBuffer();
    if (cookedCount > 0) {
      body.write('Du hast $cookedCount× gekocht');
    }
    if (streakDays > 0) {
      body.write(body.isEmpty ? '' : ' · ');
      body.write('🔥 $streakDays Tage Streak');
    }
    if (body.isEmpty) body.write('Diese Woche war ruhig – kommende Woche wieder durchstarten!');

    await _plugin.show(
      _weeklyId,
      '📊 Deine Woche in kokomu',
      body.toString(),
      _weeklyDetails,
    );
  }

  static Future<bool> isWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('weekly_summary_enabled') ?? true;
  }

  static Future<void> setWeeklySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_summary_enabled', enabled);
  }

  // ── Haushalt-Benachrichtigungen ─────────────────────────────────────────

  /// Zeigt eine Haushalt-Chat-Nachricht als Benachrichtigung.
  static Future<void> showHouseholdMessage({
    required String senderName,
    required String message,
  }) async {
    await initialize();
    if (!await isHouseholdNotificationsEnabled()) return;
    await _plugin.show(
      _householdId,
      '🏠 $senderName',
      message,
      _householdDetails,
    );
  }

  /// Zeigt eine Haushalt-Aktivitäts-Benachrichtigung.
  static Future<void> showHouseholdActivity({
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!await isHouseholdNotificationsEnabled()) return;
    await _plugin.show(_householdId, title, body, _householdDetails);
  }

  // ── Alle Benachrichtigungen löschen ─────────────────────────────────────

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Einstellungen ───────────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('expiry_reminders_enabled') ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('expiry_reminders_enabled', enabled);
  }

  static Future<bool> isMealReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('meal_reminders_enabled') ?? true;
  }

  static Future<void> setMealReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('meal_reminders_enabled', enabled);
  }

  static Future<bool> isHouseholdNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('household_notifications_enabled') ?? true;
  }

  static Future<void> setHouseholdNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('household_notifications_enabled', enabled);
  }

  static Future<int> getWarningDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('expiry_warning_days') ?? 3;
  }

  static Future<void> setWarningDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('expiry_warning_days', days);
  }
}

