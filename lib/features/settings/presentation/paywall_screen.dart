import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/core/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// ── Free vs. Pro Übersicht ────────────────────────────────────────────────
//
// FREE (kostenlos, dauerhaft):
//   • Vorrat verwalten (unbegrenzt)
//   • Einkaufslisten erstellen & teilen
//   • Haushalt mit bis zu 3 Personen
//   • Haushalt-Wochenplan & Chat
//   • Community: Rezepte & Wochenpläne entdecken, liken, speichern
//   • Eigene Rezepte erstellen & veröffentlichen (max. 3)
//   • Wochenpläne erstellen & teilen (max. 1 aktiver Plan)
//   • KI-Rezepte generieren: 5x pro Woche
//   • Barcode-Scanner (unbegrenzt)
//   • Basis-Nährwertanzeige im Rezept-Detail
//
// PRO (2,99 €/Monat oder 19,99 €/Jahr):
//   • Unlimitierte KI-Rezeptgenerierung
//   • KI-Wochenplan generieren
//   • Vollständiges Nährwert-Tracking (Kalorien, Protein, Carbs, Fett)
//   • Haushalt bis 6 Personen
//   • Eigene Rezepte veröffentlichen (unbegrenzt)
//   • Mehrere aktive Wochenpläne
//   • Allergen-Filter
//   • PDF-Export (Rezepte & Wochenpläne)
//   • Supermarkt-Angebote (coming soon)
// ─────────────────────────────────────────────────────────────────────────

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _yearlySelected = true;
  bool _upgrading = false;
  bool _showPro = true;

  static const _freeFeatures = [
    (Icons.kitchen_rounded, 'Vorrat verwalten', 'Unbegrenzt Artikel'),
    (Icons.shopping_cart_outlined, 'Einkaufslisten', 'Erstellen & mit Haushalt teilen'),
    (Icons.group_outlined, 'Haushalt (max. 3)', 'Gemeinsamer Vorrat & Einkauf'),
    (Icons.auto_awesome_outlined, 'KI-Rezepte', '5x pro Woche'),
    (Icons.qr_code_scanner, 'Barcode-Scanner', 'Unbegrenzt scannen'),
    (Icons.people_outlined, 'Community', 'Rezepte & Pläne entdecken'),
    (Icons.bookmark_border, 'Rezepte veröffentlichen', 'Max. 3 eigene Rezepte'),
  ];

  static const _proFeatures = [
    (Icons.auto_awesome, 'Unlimitierte KI-Rezepte', 'Ohne Wochenlimit generieren'),
    (Icons.calendar_month, 'KI-Wochenplan', 'Kompletten Plan per KI erstellen'),
    (Icons.monitor_heart, 'Nährwert-Tracking', 'Kalorien, Protein, Carbs, Fett'),
    (Icons.group, 'Haushalt bis 6 Personen', 'Mehr Mitglieder einladen'),
    (Icons.bookmark, 'Rezepte & Pläne unbegrenzt', 'Unbegrenzt veröffentlichen'),
    (Icons.no_meals, 'Allergen-Filter', 'Laktose, Gluten, Nüsse etc.'),
    (Icons.picture_as_pdf, 'PDF-Export', 'Rezepte & Wochenpläne drucken'),
    (Icons.local_offer_outlined, 'Supermarkt-Angebote', 'Wochenangebote (coming soon)'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final isPro = subscriptionAsync.valueOrNull?.isPro ?? false;

    if (isPro) {
      return _ProActiveScreen();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(theme),
              const SizedBox(height: 24),

              // Free vs Pro Vergleich
              _buildComparisonToggle(theme),
              const SizedBox(height: 24),

              // Plan-Toggle (einmalig)
              _buildPlanToggle(theme),
              const SizedBox(height: 8),

              // Preis-Ersparnis Hinweis
              if (_yearlySelected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '🎉 Du sparst 15,89 € im Jahr (44%)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Upgrade-Button
              _buildUpgradeButton(theme),
              const SizedBox(height: 12),

              // Bedingungen
              Center(
                child: Text(
                  'Jederzeit kündbar · Keine versteckten Kosten',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Käufe wiederherstellen
              Center(
                child: TextButton(
                  onPressed: _upgrading ? null : _restore,
                  child: Text(
                    'Kauf wiederherstellen',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonToggle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Free / Pro
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showPro = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showPro ? theme.colorScheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_showPro ? [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4, offset: const Offset(0, 1)),
                      ] : null,
                    ),
                    child: Text('Kostenlos',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: !_showPro ? FontWeight.bold : FontWeight.normal,
                          color: !_showPro ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        )),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showPro = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showPro ? theme.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_showPro)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star_rounded, color: Colors.white, size: 14),
                          ),
                        Text('Pro',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _showPro ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Feature-Liste
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: (_showPro ? _proFeatures : _freeFeatures).map((f) => ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _showPro
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(f.$1, size: 18,
                      color: _showPro
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                ),
                title: Text(f.$2, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                subtitle: Text(f.$3, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
                trailing: Icon(
                  _showPro ? Icons.star_rounded : Icons.check_circle_rounded,
                  color: _showPro ? theme.colorScheme.primary : Colors.green.shade600,
                  size: 20,
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text('kokomu Pro',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'KI ohne Limit, Wochenplaner, Nährwert-Tracking.',
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanToggle(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _PlanCard(
          title: 'Monatlich',
          price: '2,99 €',
          subtitle: 'pro Monat',
          isSelected: !_yearlySelected,
          badge: null,
          onTap: () => setState(() => _yearlySelected = false),
        )),
        const SizedBox(width: 12),
        Expanded(child: _PlanCard(
          title: 'Jährlich',
          price: '19,99 €',
          subtitle: '= 1,67 €/Monat',
          isSelected: _yearlySelected,
          badge: '−44%',
          onTap: () => setState(() => _yearlySelected = true),
        )),
      ],
    );
  }


  Widget _buildUpgradeButton(ThemeData theme) {
    return FilledButton(
      onPressed: _upgrading ? null : _upgrade,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.primary,
      ),
      child: _upgrading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              _yearlySelected
                  ? 'Jetzt für 19,99 €/Jahr upgraden ⭐'
                  : 'Jetzt für 2,99 €/Monat upgraden ⭐',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Future<void> _upgrade() async {
    setState(() => _upgrading = true);
    try {
      // RevenueCat aktiv → echter Kauf
      if (RevenueCatService.isInitialized) {
        final products = await RevenueCatService.getProducts();
        final targetId = _yearlySelected
            ? RevenueCatService.yearlyProductId
            : RevenueCatService.monthlyProductId;

        final product = products.firstWhere(
          (p) => p.identifier == targetId,
          orElse: () => products.first,
        );

        final success = await RevenueCatService.purchase(product);
        if (!success || !mounted) return;

        // Subscription-State aktualisieren
        await ref.read(subscriptionProvider.notifier).refresh();
      } else {
        // Fallback: manuelles Upgrade (Demo / Entwicklung)
        final months = _yearlySelected ? 12 : 1;
        await ref.read(subscriptionProvider.notifier).upgradeToPro(months: months);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Willkommen bei kokomu Pro!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on PurchasesError catch (e) {
      if (mounted && e.code != PurchasesErrorCode.purchaseCancelledError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kauf fehlgeschlagen: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _upgrading = true);
    try {
      final isPro = await RevenueCatService.restorePurchases();
      if (isPro) {
        await ref.read(subscriptionProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Käufe wiederhergestellt!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein aktives Abo gefunden'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }
}

// ── Plan-Karte ────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.isSelected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 4),
                Text(price, style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? theme.colorScheme.primary : null,
                )),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pro already active screen ─────────────────────────────────
class _ProActiveScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sub = ref.watch(subscriptionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Mein Abo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded,
                  size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Du hast kokomu Pro! ⭐',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (sub?.validUntilLabel.isNotEmpty == true)
                Text(sub!.validUntilLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text(
                'Genieße alle Pro-Features ohne Einschränkungen.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
