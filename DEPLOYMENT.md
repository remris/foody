# Groq-Proxy & Offline-Modus – Deployment Guide

## 🔐 Groq-Proxy (Supabase Edge Function)

### Voraussetzungen
- Supabase CLI installiert: `npm install -g supabase`
- Eingeloggt: `supabase login`
- Projekt verlinkt: `supabase link --project-ref <dein-project-ref>`

### Schritt 1: SQL-Migration ausführen
Im Supabase Dashboard → SQL Editor:
```sql
-- Inhalt von supabase_migration_06_ai_usage_serverside.sql einfügen
```

### Schritt 2: Edge Function deployen
```bash
supabase functions deploy groq-proxy
```

### Schritt 3: Groq API-Key als Secret setzen
```bash
supabase secrets set GROQ_API_KEY=gsk_dein_key_hier
```

### Schritt 4: `.env` Datei bereinigen (API-Key entfernen)
In deiner `.env` Datei:
```
# GROQ_API_KEY=gsk_... ← ENTFERNEN (läuft jetzt über Server)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

### Schritt 5: Testen
Die App ruft jetzt `/functions/v1/groq-proxy` auf statt direkt Groq.
- Bei nicht eingeloggten Usern → 401
- Bei Free-Usern die das Limit erreicht haben → 429 + Paywall
- Bei Pro-Usern → direkt weitergeleitet

---

## 📶 Offline-Modus

### Was ist implementiert
- **Drift SQLite-Datenbank** (`local_database.dart`) mit Tabellen für:
  - Inventar-Items
  - Einkaufslisten + Items
  - Gespeicherte Rezepte
- **Connectivity Provider** (`connectivity_service.dart`) – Stream ob online/offline
- **Offline-Sync Service** (`offline_sync_service.dart`) – synchronisiert bei Reconnect
- **Offline-Banner** (`offline_banner.dart`) – zeigt dezenten Hinweis wenn offline
- **Auto-Sync** in `MainShell` – löst automatisch aus wenn Gerät online geht

### Was noch fehlt (nächster Schritt)
Die Provider (Inventory, Shopping List) müssen auf Offline-First umgestellt werden:

```dart
// Statt:
final data = await SupabaseService.client.from('inventory_items').select();

// Soll sein:
if (isOnline) {
  final data = await SupabaseService.client.from('inventory_items').select();
  await localDb.upsertAll(data); // lokale Kopie aktuell halten
  return data;
} else {
  return localDb.getAllInventoryItems(userId); // lokale Kopie nutzen
}
```

### Initial-Sync (beim ersten Login)
```dart
// In auth_provider.dart nach erfolgreichem Login aufrufen:
final syncService = ref.read(offlineSyncServiceProvider);
await syncService.initialSync(userId);
```

