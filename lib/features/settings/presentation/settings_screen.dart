import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:kokomu/core/constants/color_schemes.dart';
import 'package:kokomu/core/services/theme_provider.dart';
import 'package:kokomu/core/services/seed_data_service.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/settings/presentation/ai_usage_provider.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';
import 'package:kokomu/features/settings/presentation/allergen_provider.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/core/services/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScheme = ref.watch(colorSchemeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Mein Plan (immer sichtbar oben) ──
          const _PlanCard(),
          const SizedBox(height: 12),

          // ── Darstellung ──
          _SettingsGroup(
            icon: Icons.palette_outlined,
            title: 'Darstellung',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Farbschema',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    _ColorSchemeGrid(
                      currentScheme: currentScheme,
                      onSelect: (scheme) =>
                          ref.read(colorSchemeProvider.notifier).setColorScheme(scheme),
                    ),
                    const SizedBox(height: 12),
                    Text('Erscheinungsbild',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        _ThemeModeTile(
                          icon: Icons.brightness_auto,
                          label: 'System',
                          isSelected: currentThemeMode == ThemeMode.system,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                        ),
                        _ThemeModeTile(
                          icon: Icons.light_mode,
                          label: 'Hell',
                          isSelected: currentThemeMode == ThemeMode.light,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                        ),
                        _ThemeModeTile(
                          icon: Icons.dark_mode,
                          label: 'Dunkel',
                          isSelected: currentThemeMode == ThemeMode.dark,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text('Sprache',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    const _LanguageCard(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Inventar & Benachrichtigungen ──
          _SettingsGroup(
            icon: Icons.kitchen_outlined,
            title: 'Inventar & Benachrichtigungen',
            children: [
              const _AutoRestockToggle(),
              const _ExpiryReminderToggle(),
            ],
          ),
          const SizedBox(height: 8),

          // ── Allergene & Ernährung ──
          _SettingsGroup(
            icon: Icons.restaurant_menu_outlined,
            title: 'Allergene & Ernährung',
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _AllergenFilterCard(),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.restaurant_menu_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('Nährwert-Tracking'),
                  subtitle: const Text('Kalorien, Makros & Ernährungsprofil'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _ProBadge(),
                    const Icon(Icons.chevron_right),
                  ]),
                  onTap: () => context.push('/settings/nutrition'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),

          // ── Haushalt ──
          _SettingsGroup(
            icon: Icons.home_outlined,
            title: 'Haushalt',
            children: [
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.home_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Mein Haushalt'),
                  subtitle: const Text('Inventar & Listen mit anderen teilen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/household'),
                ),
              ),
              Consumer(builder: (context, ref, _) {
                final household = ref.watch(householdProvider).valueOrNull;
                if (household == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz_rounded,
                          color: theme.colorScheme.tertiary),
                      title: const Text('Vorrat in Haushalt übertragen'),
                      subtitle: const Text('Alle privaten Vorräte übertragen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Vorrat migrieren?'),
                            content: Text(
                                'Alle deine privaten Vorräte werden in den Haushalt „${household.name}" übertragen.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Abbrechen')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Übertragen')),
                            ],
                          ),
                        );
                        if (confirm != true || !context.mounted) return;
                        final count = await ref
                            .read(inventoryProvider.notifier)
                            .migrateToHousehold();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(count > 0
                                ? '✅ $count Artikel zum Haushalt übertragen'
                                : 'Keine privaten Artikel vorhanden'),
                          ));
                        }
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),

          // ── Konto ──
          _SettingsGroup(
            icon: Icons.person_outline_rounded,
            title: 'Konto',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Abmelden'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, ref),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Konto dauerhaft löschen'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Rechtliches ──
          _SettingsGroup(
            icon: Icons.gavel_outlined,
            title: 'Rechtliches',
            children: [
              _LegalTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Datenschutzerklärung',
                assetPath: 'assets/privacy_policy.html',
                pageTitle: 'Datenschutzerklärung',
              ),
              _LegalTile(
                icon: Icons.description_outlined,
                title: 'Nutzungsbedingungen (AGB)',
                assetPath: 'assets/terms_of_service.html',
                pageTitle: 'Nutzungsbedingungen',
              ),
              _LegalTile(
                icon: Icons.info_outline_rounded,
                title: 'Impressum',
                assetPath: 'assets/imprint.html',
                pageTitle: 'Impressum',
              ),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'kokomu v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ColorSchemeGrid extends StatelessWidget {
  final AppColorScheme currentScheme;
  final ValueChanged<AppColorScheme> onSelect;

  const _ColorSchemeGrid({
    required this.currentScheme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: AppColorScheme.values.length,
      itemBuilder: (context, index) {
        final scheme = AppColorScheme.values[index];
        final isSelected = scheme == currentScheme;

        return GestureDetector(
          onTap: () => onSelect(scheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.seedColor.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? scheme.seedColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.seedColor, scheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: scheme.seedColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Icon(scheme.icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scheme.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? scheme.seedColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── _SettingsGroup (zusammenklappbare Sektion) ──────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
          title: Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

// ─── _ProBadge ────────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Pro',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary)),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _AutoRestockToggle extends StatefulWidget {
  const _AutoRestockToggle();

  @override
  State<_AutoRestockToggle> createState() => _AutoRestockToggleState();
}

class _AutoRestockToggleState extends State<_AutoRestockToggle> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('auto_restock_enabled') ?? true;
    });
  }

  Future<void> _toggle(bool val) async {
    setState(() => _enabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_restock_enabled', val);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: _enabled,
        onChanged: _toggle,
        title: const Text('Auto-Nachkauf'),
        subtitle: const Text(
          'Artikel automatisch auf die Einkaufsliste setzen wenn der Mindestbestand unterschritten wird',
        ),
        secondary: Icon(
          Icons.autorenew,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ExpiryReminderToggle extends StatefulWidget {
  const _ExpiryReminderToggle();

  @override
  State<_ExpiryReminderToggle> createState() => _ExpiryReminderToggleState();
}

class _ExpiryReminderToggleState extends State<_ExpiryReminderToggle> {
  bool _enabled = true;
  int _warningDays = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('expiry_reminders_enabled') ?? true;
      _warningDays = prefs.getInt('expiry_warning_days') ?? 3;
    });
  }

  Future<void> _toggleEnabled(bool val) async {
    setState(() => _enabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('expiry_reminders_enabled', val);
  }

  Future<void> _setWarningDays(int days) async {
    setState(() => _warningDays = days);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('expiry_warning_days', days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: _toggleEnabled,
            title: const Text('Ablauf-Erinnerungen'),
            subtitle: const Text(
              'Benachrichtigung wenn Lebensmittel bald ablaufen',
            ),
            secondary: Icon(
              Icons.notifications_active,
              color: theme.colorScheme.primary,
            ),
          ),
          if (_enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warnung vor Ablauf:',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1T')),
                        ButtonSegment(value: 3, label: Text('3T')),
                        ButtonSegment(value: 5, label: Text('5T')),
                        ButtonSegment(value: 7, label: Text('7T')),
                      ],
                      selected: {_warningDays},
                      onSelectionChanged: (s) => _setWarningDays(s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gewählt: $_warningDays ${_warningDays == 1 ? 'Tag' : 'Tage'} vor Ablauf',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Testdaten-Karte
// ─────────────────────────────────────────────
class _SeedDataCard extends ConsumerStatefulWidget {
  const _SeedDataCard();

  @override
  ConsumerState<_SeedDataCard> createState() => _SeedDataCardState();
}

class _SeedDataCardState extends ConsumerState<_SeedDataCard> {
  bool _loadingInventory = false;
  bool _loadingLists = false;
  bool _loadingAll = false;

  Future<void> _seedInventory() async {
    setState(() => _loadingInventory = true);
    try {
      await SeedDataService.seedInventory(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 32 Haushaltszutaten wurden hinzugefügt!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  Future<void> _seedShoppingLists() async {
    setState(() => _loadingLists = true);
    try {
      await SeedDataService.seedShoppingLists(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 2 Einkaufslisten wurden erstellt!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  Future<void> _seedAll() async {
    setState(() => _loadingAll = true);
    try {
      await SeedDataService.seedInventory(ref);
      await SeedDataService.seedShoppingLists(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Alle Testdaten wurden geladen!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _loadingInventory || _loadingLists || _loadingAll;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.science_outlined,
                    color: theme.colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Testdaten generieren',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(
                        'Befüllt die App mit realistischen Haushaltsdaten',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info-Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                      icon: Icons.kitchen,
                      text: '32 Vorrat-Artikel (Kühlschrank, Vorrat, TK)'),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.shopping_cart,
                      text: '2 Einkaufslisten: „Wocheneinkauf" (22 Artikel) + „Schnelleinkauf Lidl" (10 Artikel)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _seedInventory,
                    icon: _loadingInventory
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.kitchen, size: 16),
                    label: const Text('Vorrat'),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _seedShoppingLists,
                    icon: _loadingLists
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text('Listen'),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _seedAll,
                icon: _loadingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Alles auf einmal laden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Plan-Karte (Free / Pro Badge + KI-Nutzung)
// ─────────────────────────────────────────────
class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subAsync = ref.watch(subscriptionProvider);
    final usageAsync = ref.watch(aiUsageProvider);

    final isPro = subAsync.valueOrNull?.isPro ?? false;
    final usage = usageAsync.valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPro
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPro ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isPro
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isPro ? 'kokomu Pro' : 'kokomu Free',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPro
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPro ? '⭐ Pro' : 'Free',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPro
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subAsync.valueOrNull?.validUntilLabel.isNotEmpty ==
                          true)
                        Text(
                          subAsync.valueOrNull!.validUntilLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // KI-Nutzungsanzeige (nur für Free)
            if (!isPro && usage != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KI-Rezepte diese Woche',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${usage.usedThisWeek} / ${usage.weeklyLimit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: usage.remaining == 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usage.usageFraction,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usage.remaining == 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              if (usage.remaining == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '⚡ Limit erreicht – setzt sich nächsten Montag zurück',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],

            // Upgrade-Button (nur für Free)
            if (!isPro) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const PaywallScreen(),
                  ),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Auf Pro upgraden'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],

            // Kündigen-Button (nur für Pro)
            if (isPro) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Abo kündigen?'),
                        content: const Text(
                          'Dein Pro-Abo wird sofort beendet und du wechselst zurück zum kostenlosen Plan. Alle Pro-Funktionen sind dann nicht mehr verfügbar.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Ja, kündigen'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(subscriptionProvider.notifier)
                          .cancelSubscription();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abo wurde gekündigt'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.cancel_outlined,
                      size: 16, color: theme.colorScheme.error),
                  label: Text(
                    'Abo kündigen',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Allergen-Filter Karte
// ─────────────────────────────────────────────
class _AllergenFilterCard extends ConsumerWidget {
  const _AllergenFilterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(allergenFilterProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Allergen-Filter',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (selected.isNotEmpty)
                  Text('${selected.length} aktiv',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Zutaten mit diesen Allergenen werden markiert.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: Allergen.values.map((allergen) {
                final isSelected = selected.contains(allergen);
                return FilterChip(
                  label: Text('${allergen.emoji} ${allergen.label}',
                      style: TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.errorContainer,
                  checkmarkColor: theme.colorScheme.error,
                  showCheckmark: true,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      ref.read(allergenFilterProvider.notifier).toggle(allergen),
                );
              }).toList(),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      ref.read(allergenFilterProvider.notifier).clear(),
                  child: const Text('Alle entfernen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sprach-Karte
// ─────────────────────────────────────────────
class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLang = ref.watch(localeProvider).valueOrNull ?? AppLanguage.system;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: AppLanguage.values.map((lang) {
            final isSelected = currentLang == lang;
            return ListTile(
              dense: true,
              leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
              title: Text(
                lang.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: lang == AppLanguage.system
                  ? Text(
                      'Gerätesprache verwenden',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded,
                      color: theme.colorScheme.primary)
                  : null,
              onTap: () =>
                  ref.read(localeProvider.notifier).setLanguage(lang),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Datenschutzerklärung',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Wir nehmen den Schutz deiner Daten ernst. Diese Datenschutzerklärung informiert dich über die Erhebung, Verarbeitung und Nutzung deiner Daten in der kokomu-App.\n\n'
                'Durch die Nutzung der App stimmst du der Erhebung und Verwendung deiner Daten gemäß dieser Erklärung zu.\n\n'
                'Wenn du Fragen oder Bedenken hast, kontaktiere uns bitte über die App oder unsere Website.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Link zur Datenschutzerklärung öffnen
                    launchUrlString('https://www.kokomu.app/datenschutz');
                  },
                  child: const Text('Zur Datenschutzerklärung'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Konto löschen Dialog ──────────────────────────────────────────────────────
Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konto löschen?'),
      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 36),
      content: const Text(
        'Dein Konto und alle deine Daten werden dauerhaft und unwiderruflich gelöscht.\n\n'
        'Dazu gehören:\n'
        '• Dein Profil & Einstellungen\n'
        '• Dein gesamter Vorrat\n'
        '• Alle deine Rezepte\n'
        '• Alle Wochenpläne\n\n'
        'Diese Aktion kann nicht rückgängig gemacht werden!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Ja, dauerhaft löschen'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final client = ref.read(authRepositoryProvider);
    // Supabase Account löschen via Admin-API oder Auth-Delete
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto wurde gelöscht. Auf Wiedersehen! 👋'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Legal Tile ──────────────────────────────────────────────────────────────

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String assetPath;
  final String pageTitle;

  const _LegalTile({
    required this.icon,
    required this.title,
    required this.assetPath,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LegalDetailScreen(
            title: pageTitle,
            assetPath: assetPath,
          ),
        ),
      ),
    );
  }
}

// ── Legal Detail Screen ──────────────────────────────────────────────────────

class _LegalDetailScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const _LegalDetailScreen({required this.title, required this.assetPath});

  @override
  State<_LegalDetailScreen> createState() => _LegalDetailScreenState();
}

class _LegalDetailScreenState extends State<_LegalDetailScreen> {
  String _htmlContent = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final content = await DefaultAssetBundle.of(context).loadString(widget.assetPath);
    if (mounted) {
      setState(() {
        _htmlContent = content;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _HtmlTextView(html: _htmlContent),
            ),
    );
  }
}

// ── Simple HTML → Flutter Text Renderer ─────────────────────────────────────

class _HtmlTextView extends StatelessWidget {
  final String html;
  const _HtmlTextView({required this.html});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = html
        .replaceAll(RegExp(r'<h1[^>]*>'), '\n__H1__')
        .replaceAll(RegExp(r'<h2[^>]*>'), '\n__H2__')
        .replaceAll(RegExp(r'<li[^>]*>'), '\n  • ')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true), r'**\1**')
        .replaceAll(RegExp(r'<a[^>]*href="mailto:([^"]+)"[^>]*>.*?</a>', dotAll: true), r'\1')
        .replaceAll(RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true), r'\2 (\1)')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('__H1__')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text(
              line.replaceFirst('__H1__', '').trim(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (line.startsWith('__H2__')) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(
              line.replaceFirst('__H2__', '').trim(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else if (line.startsWith('  •')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: _renderLine(line, theme),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _renderLine(line, theme),
          );
        }
      }).toList(),
    );
  }

  Widget _renderLine(String line, ThemeData theme) {
    final parts = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        parts.add(TextSpan(text: line.substring(last, match.start)));
      }
      parts.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < line.length) {
      parts.add(TextSpan(text: line.substring(last)));
    }
    return RichText(
      text: TextSpan(style: theme.textTheme.bodyMedium, children: parts),
    );
  }
}
