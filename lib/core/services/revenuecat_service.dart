import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat Service – initialisiert das SDK und stellt Käufe bereit.
class RevenueCatService {
  static bool _initialized = false;

  // Product IDs aus .env (oder Fallback)
  static String get monthlyProductId =>
      dotenv.env['RC_PRODUCT_MONTHLY'] ?? 'prod10e2383bd9';

  static String get yearlyProductId =>
      dotenv.env['RC_PRODUCT_YEARLY'] ?? 'prod1ed47ebcf3';

  static Future<void> init(String? userId) async {
    if (_initialized) return;

    final androidKey = dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
    final iosKey = dotenv.env['REVENUECAT_IOS_KEY'] ?? '';

    if (androidKey.isEmpty || androidKey == 'DEIN_REVENUECAT_ANDROID_PUBLIC_KEY') {
      debugPrint('⚠️ RevenueCat: Kein API Key konfiguriert – Käufe nicht aktiv');
      return;
    }

    await Purchases.setLogLevel(LogLevel.info);

    final config = PurchasesConfiguration(
      Platform.isAndroid ? androidKey : iosKey,
    )..appUserID = userId;

    await Purchases.configure(config);
    _initialized = true;
    debugPrint('✅ RevenueCat initialisiert');
  }

  /// Lädt verfügbare Produkte
  static Future<List<StoreProduct>> getProducts() async {
    if (!_initialized) return [];
    try {
      return await Purchases.getProducts([monthlyProductId, yearlyProductId]);
    } catch (e) {
      debugPrint('RevenueCat getProducts Fehler: $e');
      return [];
    }
  }

  /// Kauft ein Produkt und gibt zurück ob Pro aktiv ist
  static Future<bool> purchase(StoreProduct product) async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.purchaseStoreProduct(product);
      return _isPro(info);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Stellt Käufe wieder her
  static Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      return _isPro(info);
    } catch (e) {
      debugPrint('RevenueCat restorePurchases Fehler: $e');
      return false;
    }
  }

  /// Prüft ob User aktuell Pro hat
  static Future<bool> checkIsPro() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return _isPro(info);
    } catch (e) {
      return false;
    }
  }

  static bool _isPro(CustomerInfo info) {
    // Prüfe ob eine aktive Entitlement namens "pro" existiert
    return info.entitlements.active.containsKey('pro') ||
        info.activeSubscriptions.any((s) =>
            s.contains(monthlyProductId) || s.contains(yearlyProductId));
  }

  static bool get isInitialized => _initialized;
}

