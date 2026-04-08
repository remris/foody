import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/core/services/revenuecat_service.dart';

/// Abo-Status des aktuellen Users.
/// Phase 1: Supabase `subscriptions`-Tabelle, manuell setzbar.
/// Phase 2: RevenueCat-Integration (purchases_flutter) – aktiv wenn API-Key gesetzt.
class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const SubscriptionState.free();

    // RevenueCat initialisieren (nur wenn API-Key konfiguriert)
    await RevenueCatService.init(userId);

    // RevenueCat hat Vorrang wenn initialisiert
    if (RevenueCatService.isInitialized) {
      final isPro = await RevenueCatService.checkIsPro();
      if (isPro) {
        return const SubscriptionState(
          plan: SubscriptionPlan.pro,
          source: 'revenuecat',
        );
      }
    }

    // Fallback: Supabase (manuelle Upgrades / Early Adopter)
    return _fetchFromSupabase(userId);
  }

  Future<SubscriptionState> _fetchFromSupabase(String userId) async {
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return const SubscriptionState.free();

      final plan = response['plan'] as String? ?? 'free';
      final validUntilStr = response['valid_until'] as String?;
      DateTime? validUntil;
      if (validUntilStr != null) {
        validUntil = DateTime.tryParse(validUntilStr);
      }

      // Prüfen ob Pro noch gültig ist
      final isPro = plan == 'pro' &&
          (validUntil == null || validUntil.isAfter(DateTime.now()));

      return SubscriptionState(
        plan: isPro ? SubscriptionPlan.pro : SubscriptionPlan.free,
        validUntil: validUntil,
        source: response['source'] as String? ?? 'manual',
      );
    } catch (_) {
      return const SubscriptionState.free();
    }
  }

  /// Setzt den Plan auf Pro (Phase 1: manuell für Tests / Early Adopter).
  Future<void> upgradeToPro({int months = 1}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final validUntil = DateTime.now().add(Duration(days: 30 * months));

    try {
      final client = SupabaseService.client;
      await client.from('subscriptions').upsert({
        'user_id': userId,
        'plan': 'pro',
        'valid_until': validUntil.toIso8601String(),
        'source': 'manual',
      });
      state = AsyncData(SubscriptionState(
        plan: SubscriptionPlan.pro,
        validUntil: validUntil,
        source: 'manual',
      ));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = AsyncData(await _fetchFromSupabase(userId));
  }

  /// Kündigt das Pro-Abo (setzt Plan zurück auf Free).
  Future<void> cancelSubscription() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    try {
      await SupabaseService.client.from('subscriptions').upsert({
        'user_id': userId,
        'plan': 'free',
        'valid_until': null,
        'source': 'cancelled',
      });
      state = const AsyncData(SubscriptionState.free());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

enum SubscriptionPlan { free, pro }

class SubscriptionState {
  final SubscriptionPlan plan;
  final DateTime? validUntil;
  final String source;

  const SubscriptionState({
    required this.plan,
    this.validUntil,
    this.source = 'free',
  });

  const SubscriptionState.free()
      : plan = SubscriptionPlan.free,
        validUntil = null,
        source = 'free';

  bool get isPro => plan == SubscriptionPlan.pro;
  bool get isFree => plan == SubscriptionPlan.free;

  String get planLabel => isPro ? 'Pro ⭐' : 'Free';

  String get validUntilLabel {
    if (validUntil == null) return '';
    final d = validUntil!;
    return 'Gültig bis ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);

/// Convenience-Provider: gibt direkt `isPro` zurück.
final isProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull?.isPro ?? false;
});

