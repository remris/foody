import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kokomi/core/services/supabase_service.dart';

/// FCM Push Notification Service
///
/// Initialisierung in main.dart NACH Supabase.initialize():
///   await PushNotificationService.initialize();
///
/// Voraussetzungen:
///   - android/app/google-services.json vorhanden
///   - ios/Runner/GoogleService-Info.plist vorhanden
///   - APNs-Zertifikat in Apple Developer Console
///
/// Supabase-Tabelle push_tokens muss existieren (supabase_migration_20_push_tokens.sql)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Wichtig: Firebase muss auch im Background initialisiert sein
  await Firebase.initializeApp();
  debugPrint('🔔 FCM Background Message: ${message.messageId}');
  // Lokale Notification für Background-Nachrichten anzeigen
  await PushNotificationService._showLocalFromRemote(message);
}

class PushNotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // High-Priority Channel für FCM (Android 8+)
  static const _fcmChannel = AndroidNotificationChannel(
    'fcm_high_importance',
    'Push-Benachrichtigungen',
    description: 'Wichtige Benachrichtigungen von Kokomi',
    importance: Importance.max,
  );

  // ── Initialisierung ────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase initialisieren (benötigt google-services.json / GoogleService-Info.plist)
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('⚠️ Firebase nicht konfiguriert (kein google-services.json?): $e');
      // App läuft trotzdem weiter – nur ohne Push-Notifications
      return;
    }

    // Berechtigungen anfragen
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Push-Benachrichtigungen vom User abgelehnt');
      return;
    }

    // Lokale Notification-Plugin für Foreground-Nachrichten einrichten
    await _localPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_fcmChannel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Background Handler registrieren
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground Handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App aus Notification geöffnet (Background → Tapped)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App kalt gestartet via Notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // FCM-Token speichern
    await _saveToken();

    // Token-Refresh listener
    _fcm.onTokenRefresh.listen((newToken) => _saveTokenToSupabase(newToken));

    _initialized = true;
    debugPrint('✅ PushNotificationService initialisiert');
  }

  // ── Token-Management ───────────────────────────────────────────────────

  static Future<void> _saveToken() async {
    try {
      // iOS: APNS-Token erst registrieren
      if (Platform.isIOS) {
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true,
        );
      }
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('⚠️ FCM Token konnte nicht gespeichert werden: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
      debugPrint('✅ FCM Token gespeichert');
    } catch (e) {
      debugPrint('⚠️ FCM Token konnte nicht in Supabase gespeichert werden: $e');
    }
  }

  /// Beim Logout Token entfernen
  static Future<void> removeToken() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      final token = await _fcm.getToken();
      if (userId != null && token != null) {
        await SupabaseService.client
            .from('push_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
      await _fcm.deleteToken();
      _initialized = false;
    } catch (e) {
      debugPrint('⚠️ FCM Token konnte nicht entfernt werden: $e');
    }
  }

  // ── Message Handler ────────────────────────────────────────────────────

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 FCM Foreground: ${message.notification?.title}');
    await _showLocalFromRemote(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification getappt: ${message.data}');
    // TODO: Navigation zu spezifischem Screen basierend auf message.data['route']
    // Beispiel: if (message.data['route'] == 'household_chat') GoRouter.go('/household');
  }

  static Future<void> _showLocalFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'fcm_high_importance',
      'Push-Benachrichtigungen',
      channelDescription: 'Wichtige Benachrichtigungen von Kokomi',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Topic Subscriptions (für Broadcast-Nachrichten) ───────────────────

  /// Alle User auf globalen Kanal subscriben (z.B. App-Updates)
  static Future<void> subscribeToGlobal() async {
    await _fcm.subscribeToTopic('global');
    await _fcm.subscribeToTopic('de'); // deutschsprachige Nutzer
  }

  /// Haushalt-spezifischen Kanal subscriben
  static Future<void> subscribeToHousehold(String householdId) async {
    await _fcm.subscribeToTopic('household_$householdId');
  }

  static Future<void> unsubscribeFromHousehold(String householdId) async {
    await _fcm.unsubscribeFromTopic('household_$householdId');
  }

  // ── Einstellungen (werden von notification_service.dart geerbt) ────────

  static Future<String?> getToken() => _fcm.getToken();
}

