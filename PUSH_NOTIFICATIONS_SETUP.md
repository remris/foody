# 🔔 Push Notifications – Setup Anleitung

## Voraussetzungen
- `firebase_core` und `firebase_messaging` sind bereits in `pubspec.yaml`
- `push_notification_service.dart` ist implementiert
- `supabase_migration_20_push_tokens.sql` wurde ausgeführt

---

## Schritt 1: Firebase-Projekt anlegen

1. Gehe zu [console.firebase.google.com](https://console.firebase.google.com)
2. **„Projekt hinzufügen"** → Name: `foody-app`
3. Google Analytics: Optional aktivieren
4. Projekt erstellen → Fertig

---

## Schritt 2: Android-App registrieren

1. Im Firebase-Projekt: **„Android-App hinzufügen"** (Android-Icon)
2. Android-Paketname: `de.foodyapp.app`
3. App-Spitzname: `Foody Android`
4. Debug-Signing-Zertifikat SHA-1 eingeben (optional, für Auth-Features nötig):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. `google-services.json` herunterladen
6. Datei kopieren nach: `android/app/google-services.json`
7. In `android/build.gradle.kts` (Zeile ganz unten):
   ```kotlin
   // Bereits vorhanden? Falls nicht:
   plugins {
     id("com.google.gms.google-services") version "4.4.0" apply false
   }
   ```
8. In `android/app/build.gradle.kts` ganz oben `plugins {}` ergänzen:
   ```kotlin
   plugins {
     id("com.android.application")
     id("com.google.gms.google-services")  // ← NEU
     id("org.jetbrains.kotlin.android")
   }
   ```

---

## Schritt 3: iOS-App registrieren

1. Im Firebase-Projekt: **„iOS-App hinzufügen"** (Apple-Icon)
2. Bundle-ID: `de.foodyapp.app`
3. `GoogleService-Info.plist` herunterladen
4. In Xcode: Rechtsklick auf `Runner` → „Add Files to Runner" → `GoogleService-Info.plist` hinzufügen (Target: Runner aktivieren)
5. APNs-Schlüssel in Firebase hinterlegen:
   - Firebase Console → Projekteinstellungen → Cloud Messaging → Apple App-Konfiguration
   - APNs-Authentifizierungsschlüssel hochladen (aus [developer.apple.com](https://developer.apple.com) → Keys → neuen Key mit APNs-Berechtigung erstellen)
6. In Xcode → Runner → Signing & Capabilities → `+` → **Push Notifications** aktivieren
7. In Xcode → Runner → Signing & Capabilities → `+` → **Background Modes** → **Remote notifications** aktivieren

---

## Schritt 4: FCM Server Key für Edge Function

1. Firebase Console → Projekteinstellungen → **Cloud Messaging**
2. **Server-Schlüssel** kopieren (Legacy) ODER Service Account JSON für FCM v1 API verwenden
3. Supabase Secret setzen:
   ```bash
   supabase secrets set FCM_SERVER_KEY=<dein-server-schlüssel>
   ```

---

## Schritt 5: Edge Functions deployen

```bash
# Im Projekt-Root:
supabase functions deploy send-push
supabase functions deploy revenuecat-webhook

# Secrets setzen (falls noch nicht geschehen):
supabase secrets set REVENUECAT_WEBHOOK_SECRET=<zufälliger-sicherer-string>
supabase secrets set FCM_SERVER_KEY=<firebase-server-key>
```

---

## Schritt 6: Supabase SQL ausführen

Im Supabase SQL Editor ausführen:
- `supabase_migration_20_push_tokens.sql` (push_tokens + notification_settings Tabellen)
- `supabase_migration_21_revenuecat_subscriptions.sql` (subscriptions erweitern)

---

## Schritt 7: RevenueCat Webhook konfigurieren

1. [app.revenuecat.com](https://app.revenuecat.com) → dein Projekt → **Integrations → Webhooks**
2. **„+ Neuen Webhook hinzufügen"**
3. URL: `https://<dein-project-ref>.supabase.co/functions/v1/revenuecat-webhook`
4. Authorization Header: `Bearer <REVENUECAT_WEBHOOK_SECRET>` (selber Wert wie oben)
5. Events aktivieren: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE`, `PRODUCT_CHANGE`
6. **Testen**: „Send Test Event" → Supabase Edge Function Logs prüfen

---

## Testen (ohne echtes Gerät)

```bash
# Push-Notification manuell auslösen:
curl -X POST https://<project>.supabase.co/functions/v1/send-push \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "<deine-user-id>",
    "title": "Test 🔔",
    "body": "Push Notifications funktionieren!",
    "data": {"route": "home"}
  }'
```

---

## Checkliste

- [ ] Firebase-Projekt angelegt
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Android `build.gradle.kts` aktualisiert
- [ ] iOS Push Notifications Capability aktiviert
- [ ] iOS Background Modes → Remote notifications aktiviert
- [ ] APNs-Key in Firebase hinterlegt
- [ ] `FCM_SERVER_KEY` als Supabase Secret gesetzt
- [ ] `REVENUECAT_WEBHOOK_SECRET` als Supabase Secret gesetzt
- [ ] Edge Functions deployed (`send-push`, `revenuecat-webhook`)
- [ ] SQL-Migrationen ausgeführt (20 + 21)
- [ ] RevenueCat Webhook URL konfiguriert
- [ ] Test-Push erfolgreich empfangen

