import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kokomi/core/constants/app_constants.dart';
import 'package:kokomi/core/services/supabase_service.dart';

/// Verwaltet Supabase Realtime-Subscriptions für Einkaufslisten.
///
/// Was ist Supabase Realtime?
/// ─────────────────────────
/// Eine WebSocket-Verbindung zu Supabase. Wenn Person A in einem geteilten
/// Haushalt ein Listenelement abhakt oder hinzufügt, empfängt Person B's
/// App die Änderung in ~100-300ms – ohne Polling oder manuelles Refreshen.
///
/// Technisch: PostgreSQL Logical Replication → Realtime Server → WebSocket → App.
///
/// Kostenlos bis 200 gleichzeitige Verbindungen (Supabase Free Tier).
/// Pro-Plan: 500 Verbindungen.
///
/// Wir nutzen es für:
/// - shopping_list_items: Live-Sync wenn Haushaltsmitglied Item ergänzt/abhakt
/// - (Optional) user_inventory: Vorrat-Sync im Haushalt
class ShoppingListRealtimeService {
  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  /// Startet eine Realtime-Subscription für eine bestimmte Einkaufsliste.
  /// [onUpdate] wird aufgerufen wenn sich Items ändern (INSERT/UPDATE/DELETE).
  void subscribe(String listId, void Function() onUpdate) {
    // Bestehende Sub beenden
    unsubscribe();

    _channel = _client
        .channel('shopping_list_$listId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.tableShoppingList,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'list_id',
            value: listId,
          ),
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.tableShoppingList,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'list_id',
            value: listId,
          ),
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: AppConstants.tableShoppingList,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'list_id',
            value: listId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  /// Beendet die aktive Subscription.
  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}

final shoppingListRealtimeProvider =
    Provider<ShoppingListRealtimeService>((ref) {
  final service = ShoppingListRealtimeService();
  ref.onDispose(service.unsubscribe);
  return service;
});

