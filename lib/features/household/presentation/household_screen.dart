import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_chat_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/household/presentation/household_meal_plan_preference_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/models/household.dart';

// ────────────────────────────────────────────────────────────────────────────

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(householdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mein Haushalt')),
      body: householdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (household) => household == null
            ? _NoHouseholdView()
            : _HouseholdDetailView(household: household),
      ),
    );
  }
}

class _NoHouseholdView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NoHouseholdView> createState() => _NoHouseholdViewState();
}

class _NoHouseholdViewState extends ConsumerState<_NoHouseholdView> {
  // Letzte Anfrage lokal merken um Status anzeigen zu kÃ¶nnen
  String? _pendingHouseholdId;
  String? _pendingHouseholdName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Status der offenen Anfrage laden
    final statusAsync = _pendingHouseholdId != null
        ? ref.watch(myJoinRequestStatusProvider(_pendingHouseholdId!))
        : null;

    // Wenn Anfrage angenommen wurde â†’ Haushalt neu laden
    if (statusAsync?.valueOrNull == 'accepted') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(householdProvider);
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.home_outlined,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Status offener Anfrage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_pendingHouseholdId != null) ...[
              _JoinRequestStatusBanner(
                householdName: _pendingHouseholdName,
                statusAsync: statusAsync,
                onCancel: () => setState(() {
                  _pendingHouseholdId = null;
                  _pendingHouseholdName = null;
                }),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Text('Kein Haushalt', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Erstelle einen Haushalt oder tritt einem bei, um Inventar und Einkaufslisten zu teilen.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add_home),
                label: const Text('Haushalt erstellen'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showJoinDialog(context),
                icon: const Icon(Icons.group_add),
                label: const Text('Mit Code beitreten'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haushalt erstellen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'z.B. "Familie Müller", "WG Schillerstr."',
            prefixIcon: Icon(Icons.home),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(householdProvider.notifier).createHousehold(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  await _showHouseholdJoinedDialog(context, ref);
                }
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final codeController = TextEditingController();
    final profileDisplayName = ref.read(ownProfileProvider).valueOrNull?.displayName ?? '';
    final nameController = TextEditingController(
      text: profileDisplayName.isNotEmpty
          ? profileDisplayName
          : ref.read(currentUserProvider)?.email?.split('@').first ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haushalt beitreten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Einladungscode',
                hintText: 'z.B. AB12CD',
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Dein Name im Haushalt',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Der Admin muss deiner Anfrage zustimmen.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              // Haushalt vorab suchen um den Namen zu bekommen
              final repo = ref.read(householdRepoProvider);
              final household = await repo.findByInviteCode(code);
              if (household == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ungültiger Code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              final error = await ref
                  .read(householdProvider.notifier)
                  .requestToJoin(code, name.isEmpty ? 'Mitglied' : name);
              if (context.mounted) {
                if (error == null) {
                  setState(() {
                    _pendingHouseholdId = household.id;
                    _pendingHouseholdName = household.name;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'âœ… Anfrage an â€ž${household.name}" gesendet!'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Anfrage senden'),
          ),
        ],
      ),
    );
  }
}

/// Banner der den Status einer offenen Beitrittsanfrage anzeigt.
class _JoinRequestStatusBanner extends StatelessWidget {
  final String? householdName;
  final AsyncValue<String?>? statusAsync;
  final VoidCallback onCancel;

  const _JoinRequestStatusBanner({
    this.householdName,
    this.statusAsync,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = statusAsync?.valueOrNull;

    Color bgColor;
    Color borderColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'accepted':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        icon = Icons.check_circle_rounded;
        title = 'Anfrage angenommen!';
        subtitle = 'Du wirst gleich dem Haushalt hinzugefügtâ€¦';
      case 'rejected':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        icon = Icons.cancel_rounded;
        title = 'Anfrage abgelehnt';
        subtitle = 'Der Admin hat deine Anfrage abgelehnt.';
      default:
        bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        borderColor = theme.colorScheme.primary.withValues(alpha: 0.4);
        icon = Icons.hourglass_top_rounded;
        title = 'Anfrage ausstehend';
        subtitle = householdName != null
            ? 'Warte auf BestÃ¤tigung vom Admin von â€ž$householdName".'
            : 'Warte auf BestÃ¤tigung vom Admin.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 40,
              color: status == 'accepted'
                  ? Colors.green.shade600
                  : status == 'rejected'
                      ? Colors.red.shade600
                      : theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          if (status == null || status == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Anfrage zurückziehen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Anderen Haushalt beitreten'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog der nach Haushalt-Erstellen/Beitreten erscheint.
/// Fragt ob der User seinen persÃ¶nlichen Wochenplan auf den Haushalt übertragen mÃ¶chte.
Future<void> _showHouseholdJoinedDialog(
    BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.calendar_month_rounded,
          size: 48, color: theme.colorScheme.primary),
      title: const Text('Gemeinsamer Wochenplan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MÃ¶chtest du deinen Wochenplan mit dem Haushalt teilen?\n\n'
            'â€¢ Alle Mitglieder sehen und bearbeiten denselben Plan\n'
            'â€¢ Dein persÃ¶nlicher Plan bleibt erhalten\n'
            'â€¢ Du kannst das jederzeit im Haushalt-Tab Ã¤ndern',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Nein â†’ persÃ¶nlicher Plan bleibt, kein Haushalt-Plan
            ref
                .read(householdMealPlanPreferenceProvider.notifier)
                .setUseHouseholdPlan(false);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'âœ“ Haushalt beigetreten. Dein Wochenplan bleibt persÃ¶nlich.'),
              ),
            );
          },
          child: const Text('Nein, persÃ¶nlicher Plan'),
        ),
        FilledButton(
          onPressed: () {
            // Ja â†’ Haushalt-Plan aktivieren
            ref
                .read(householdMealPlanPreferenceProvider.notifier)
                .setUseHouseholdPlan(true);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âœ“ Haushalt-Wochenplan aktiviert!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('Ja, Haushalt-Plan nutzen'),
        ),
      ],
    ),
  );
}

class _HouseholdDetailView extends ConsumerStatefulWidget {
  final Household household;
  const _HouseholdDetailView({required this.household});

  @override
  ConsumerState<_HouseholdDetailView> createState() =>
      _HouseholdDetailViewState();
}

class _HouseholdDetailViewState extends ConsumerState<_HouseholdDetailView>
    with SingleTickerProviderStateMixin {
  Household get household => widget.household;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Haushalt frisch laden (damit neue DB-Spalten wie shared_* korrekt geladen werden)
      ref.invalidate(householdProvider);
      ref.invalidate(pendingJoinRequestsProvider(widget.household.id));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(householdMembersProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final theme = Theme.of(context);
    final memberCount = membersAsync.valueOrNull?.length ?? 0;

    return Column(
      children: [
        // â”€â”€ Header-Karte â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Emoji-Icon
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              household.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$memberCount Mitglieder · Erstellt ${_formatCreated(household.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.home_rounded,
                            size: 28,
                            color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Einladungscode
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EINLADUNGSCODE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                household.inviteCode ?? 'â€“',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (household.inviteCode != null) {
                              Clipboard.setData(ClipboardData(
                                  text: household.inviteCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code kopiert!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_outlined, size: 15),
                          label: const Text('Kopieren'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ Tab-Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              indicator: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('Mitglieder'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('Aktivität'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 16),
                      SizedBox(width: 4),
                      Text('Chat'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // â”€â”€ Tab-Inhalte â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // â”€â”€ Tab 1: Mitglieder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _MembersTab(
                household: household,
                membersAsync: membersAsync,
                currentUserId: currentUserId,
                onKick: (member) =>
                    _confirmKick(context, ref, member),
                onLeave: () {
                  final members =
                      membersAsync.valueOrNull ?? [];
                  final isAdmin = members.any(
                      (m) => m.userId == currentUserId && m.isAdmin);
                  _showLeaveDialog(context, ref,
                      isAdmin: isAdmin,
                      memberCount: members.length);
                },
                onDissolve: () =>
                    _showDissolveDialog(context, ref),
              ),
              // â”€â”€ Tab 2: AktivitÃ¤t â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _ActivityTab(),
              // â”€â”€ Tab 3: Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              const _InlineChatTab(),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCreated(DateTime? dt) {
    if (dt == null) return 'Unbekannt';
    const months = [
      'Jan', 'Feb', 'MÃ¤r', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} Min.';
    if (diff.inHours < 24) return '${diff.inHours} Std.';
    return '${diff.inDays} Tagen';
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref,
      {required bool isAdmin, required int memberCount}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haushalt verlassen?'),
        content: Text(
          isAdmin && memberCount > 1
              ? 'Du bist Admin. Wenn du den Haushalt verlÃ¤sst, '
                  'wird ein anderes Mitglied automatisch Admin.'
              : memberCount == 1 && isAdmin
                  ? 'Du bist das letzte Mitglied. Der Haushalt wird beim Verlassen gelÃ¶scht.'
                  : 'MÃ¶chtest du deinen Haushalt verlassen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ref
                  .read(householdMealPlanPreferenceProvider.notifier)
                  .reset();
              await ref.read(householdProvider.notifier).leave();
            },
            child: const Text('Ohne Items verlassen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(inventoryProvider.notifier)
                  .migrateFromHousehold();
              ref
                  .read(householdMealPlanPreferenceProvider.notifier)
                  .reset();
              await ref.read(householdProvider.notifier).leave();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Items mitnehmen & verlassen'),
          ),
        ],
      ),
    );
  }

  void _showDissolveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Colors.red.shade700, size: 36),
        title: const Text('Haushalt auflÃ¶sen?'),
        content: const Text(
          'Alle Mitglieder werden entfernt und der Haushalt wird '
          'dauerhaft gelÃ¶scht. Diese Aktion kann nicht rückgÃ¤ngig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ref
                  .read(householdMealPlanPreferenceProvider.notifier)
                  .reset();
              await ref.read(householdProvider.notifier).dissolve();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Endgültig auflÃ¶sen'),
          ),
        ],
      ),
    );
  }

  void _confirmKick(
      BuildContext context, WidgetRef ref, HouseholdMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitglied entfernen?'),
        content: Text(
          'â€ž${member.displayName ?? 'Mitglied'}" wird aus dem Haushalt '
          'entfernt und verliert den Zugriff auf alle geteilten Daten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(householdProvider.notifier)
                  .removeMember(member.id);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${member.displayName ?? 'Mitglied'} wurde entfernt.'),
                  ),
                );
              }
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Tab 1: Mitglieder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MembersTab extends ConsumerWidget {
  final Household household;
  final AsyncValue<List<HouseholdMember>> membersAsync;
  final String? currentUserId;
  final void Function(HouseholdMember) onKick;
  final VoidCallback onLeave;
  final VoidCallback onDissolve;

  const _MembersTab({
    required this.household,
    required this.membersAsync,
    required this.currentUserId,
    required this.onKick,
    required this.onLeave,
    required this.onDissolve,
  });

  String _formatSince(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'MÃ¤r', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return 'Seit ${months[dt.month - 1]}. ${dt.year}';
  }

  Color _avatarColor(int index) {
    const colors = [
      Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF00BCD4),
      Color(0xFF795548), Color(0xFF607D8B),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin = membersAsync.valueOrNull
            ?.any((m) => m.userId == currentUserId && m.isAdmin) ??
        false;
    final memberCount = membersAsync.valueOrNull?.length ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // â”€â”€ Mitglieder-Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Card(
          child: membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Fehler: $e'),
            ),
            data: (members) => Column(
              children: members.asMap().entries.map((entry) {
                final i = entry.key;
                final member = entry.value;
                final isMe = member.userId == currentUserId;
                final avatarColor = _avatarColor(i);
                final initial = (member.displayName?.isNotEmpty == true)
                    ? member.displayName![0].toUpperCase()
                    : 'M';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    member.displayName ?? 'Mitglied',
                    style: TextStyle(
                      fontWeight: isMe
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _formatSince(member.joinedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: member.isAdmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  size: 12,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text('Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  )),
                            ],
                          ),
                        )
                      : isAdmin && !isMe
                          ? IconButton(
                              icon: Icon(
                                Icons.person_remove_outlined,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              tooltip: 'Entfernen',
                              onPressed: () => onKick(member),
                            )
                          : const Icon(Icons.person_outline,
                              color: Colors.grey, size: 20),
                );
              }).toList(),
            ),
          ),
        ),

        // â”€â”€ Beitrittsanfragen (nur Admin) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Consumer(
          builder: (context, ref, _) {
            if (!isAdmin) return const SizedBox.shrink();
            final requestsAsync = ref
                .watch(pendingJoinRequestsProvider(household.id));
            return requestsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text(
                          'BEITRITTSANFRAGEN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${requests.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Card(
                      child: Column(
                        children: requests.map((req) {
                          final initial =
                              (req.displayName?.isNotEmpty == true)
                                  ? req.displayName![0].toUpperCase()
                                  : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: theme.colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(req.displayName ?? 'Unbekannt',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle:
                                const Text('MÃ¶chte beitreten'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton(
                                  onPressed: () async {
                                    await ref
                                        .read(householdProvider
                                            .notifier)
                                        .acceptJoinRequest(req);
                                    ref.invalidate(
                                        pendingJoinRequestsProvider(
                                            household.id));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'âœ… ${req.displayName ?? 'Mitglied'} aufgenommen!'),
                                      ));
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    textStyle:
                                        const TextStyle(fontSize: 13),
                                  ),
                                  child:
                                      const Text('Annehmen'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () async {
                                    await ref
                                        .read(householdProvider
                                            .notifier)
                                        .rejectJoinRequest(req.id);
                                    ref.invalidate(
                                        pendingJoinRequestsProvider(
                                            household.id));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Anfrage abgelehnt.'),
                                      ));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    textStyle:
                                        const TextStyle(fontSize: 13),
                                  ),
                                  child: const Text('Ablehnen'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        // ── Gemeinsam nutzen (Admin-Einstellungen) ──────────────────────
        Consumer(
          builder: (context, ref, _) {
            final household = ref.watch(householdProvider).valueOrNull;
            final isAdmin = membersAsync.valueOrNull
                    ?.any((m) => m.userId == currentUserId && m.isAdmin) ??
                false;
            if (household == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'GEMEINSAM NUTZEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isAdmin) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(nur Admin)',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      _HouseholdSettingTile(
                        icon: Icons.kitchen_outlined,
                        iconColor: const Color(0xFFFF7043),
                        label: 'Gemeinsamer Vorrat',
                        subtitle: 'Alle sehen & bearbeiten den gleichen Vorrat',
                        value: household.sharedInventory,
                        isAdmin: isAdmin,
                        onChanged: (v) => ref
                            .read(householdProvider.notifier)
                            .updateSetting(sharedInventory: v),
                      ),
                      Divider(
                          height: 1,
                          indent: 56,
                          color: theme.colorScheme.outlineVariant),
                      _HouseholdSettingTile(
                        icon: Icons.shopping_cart_outlined,
                        iconColor: const Color(0xFF26A69A),
                        label: 'Gemeinsame Einkaufsliste',
                        subtitle: 'Alle Mitglieder teilen eine Einkaufsliste',
                        value: household.sharedShoppingList,
                        isAdmin: isAdmin,
                        onChanged: (v) => ref
                            .read(householdProvider.notifier)
                            .updateSetting(sharedShoppingList: v),
                      ),
                      Divider(
                          height: 1,
                          indent: 56,
                          color: theme.colorScheme.outlineVariant),
                      _HouseholdSettingTile(
                        icon: Icons.calendar_month_outlined,
                        iconColor: const Color(0xFF42A5F5),
                        label: 'Gemeinsamer Wochenplan',
                        subtitle: 'Alle Mitglieder planen gemeinsam',
                        value: household.sharedMealPlan,
                        isAdmin: isAdmin,
                        onChanged: (v) => ref
                            .read(householdProvider.notifier)
                            .updateSetting(sharedMealPlan: v),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        // â”€â”€ Haushalt verlassen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        const SizedBox(height: 28),
        Center(
          child: TextButton.icon(
            onPressed: () {
              final members = membersAsync.valueOrNull ?? [];
              final admin = members
                  .any((m) => m.userId == currentUserId && m.isAdmin);
              if (admin && members.length == 1) {
                onDissolve();
              } else {
                onLeave();
              }
            },
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('Haushalt verlassen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Haushalt-Einstellungs-Tile (Admin-only Toggle) ──────────────────────────
class _HouseholdSettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final bool isAdmin;
  final ValueChanged<bool> onChanged;
  const _HouseholdSettingTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isAdmin,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: isAdmin ? onChanged : null,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// â”€â”€â”€ Tab 2: AktivitÃ¤t â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityAsync = ref.watch(householdActivityProvider);

    return activityAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Fehler: $e', textAlign: TextAlign.center),
      ),
      data: (entries) => entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Noch keine AktivitÃ¤ten',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: entries.take(20).length,
              itemBuilder: (_, i) {
                final entry = entries[i];
                final isInventory = entry.itemType == 'inventory';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isInventory
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      child: Text(
                        entry.displayName.isNotEmpty
                            ? entry.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isInventory
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      '${entry.displayName} hat â€ž${entry.itemName}" ${entry.actionLabel}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${entry.typeLabel} Â· ${entry.relativeTime}',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// â”€â”€â”€ Tab 3: Chat (inline) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _InlineChatTab extends ConsumerStatefulWidget {
  const _InlineChatTab();

  @override
  ConsumerState<_InlineChatTab> createState() => _InlineChatTabState();
}

class _InlineChatTabState extends ConsumerState<_InlineChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref
          .read(householdChatProvider.notifier)
          .sendMessage(content);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    } on ProfanityException catch (e) {
      if (mounted) {
        _controller.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nachricht konnte nicht gesendet werden')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(householdChatProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text('Chat nicht verfügbar: $e',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(householdChatProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
            data: (messages) => messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Nachrichten.\nSchreib die erste!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg.userId == currentUserId;
                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                        onDelete: isMe
                            ? () => ref
                                .read(householdChatProvider.notifier)
                                .deleteMessage(msg.id)
                            : null,
                      );
                    },
                  ),
          ),
        ),
        // Eingabezeile
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            12, 8, 12,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Nachricht…',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  minimumSize: Size.zero,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Haushalt-Wochenplan Sektion
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HouseholdMealPlanSection extends ConsumerWidget {
  final Household household;
  const _HouseholdMealPlanSection({required this.household});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefAsync = ref.watch(householdMealPlanPreferenceProvider);
    final isUsing = prefAsync.valueOrNull ?? false;
    final isLoading = prefAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gemeinsamer Wochenplan',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: isUsing
              // â”€â”€ AKTIV: Beigetreten â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grüner Header-Streifen
                    Container(
                      width: double.infinity,
                      color: Colors.green.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded,
                                color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Du bist im Haushalt-Plan',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  'Gemeinsamer Plan mit ${household.name}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.edit_calendar_rounded,
                            text:
                                'Alle Mitglieder kÃ¶nnen Mahlzeiten hinzufügen und bearbeiten.',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.sync_rounded,
                            text:
                                'Ã„nderungen sind sofort für alle sichtbar.',
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _confirmLeave(context, ref),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Haushalt-Plan verlassen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.5)),
                              minimumSize: const Size.fromHeight(40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              // â”€â”€ INAKTIV: Nicht beigetreten â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Eigener Wochenplan',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Nur du siehst und bearbeitest diesen Plan.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tritt dem Haushalt-Plan bei, um mit '
                                '${household.name} gemeinsam zu planen.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _confirmJoin(context, ref),
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.group_add_rounded, size: 18),
                        label: const Text('Haushalt-Plan beitreten'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmJoin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.groups_rounded, size: 40),
        title: const Text('Haushalt-Plan beitreten?'),
        content: const Text(
          'Du wechselst auf den gemeinsamen Wochenplan.\n\n'
          'Dein persÃ¶nlicher Plan wird pausiert â€“ '
          'du kannst jederzeit wieder wechseln.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(householdMealPlanPreferenceProvider.notifier)
          .setUseHouseholdPlan(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ“ Du bist dem Haushalt-Plan beigetreten'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout_rounded,
            size: 40, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Haushalt-Plan verlassen?'),
        content: const Text(
          'Du wechselst zurück auf deinen persÃ¶nlichen Wochenplan.\n\n'
          'Der Haushalt-Plan bleibt für die anderen Mitglieder '
          'erhalten und du kannst jederzeit wieder beitreten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(householdMealPlanPreferenceProvider.notifier)
          .setUseHouseholdPlan(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eigener Wochenplan ist jetzt aktiv')),
        );
      }
    }
  }
}

// Kleine Hilfsklasse für Info-Zeilen
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
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
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

// â”€â”€ Haushalt-Chat Vollbild-Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HouseholdChatScreen extends ConsumerStatefulWidget {
  const _HouseholdChatScreen();

  @override
  ConsumerState<_HouseholdChatScreen> createState() =>
      _HouseholdChatScreenState();
}

class _HouseholdChatScreenState
    extends ConsumerState<_HouseholdChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showQuickMessages = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send({String? quickContent, String? quickEmoji}) async {
    final content = quickContent ?? _controller.text.trim();
    if (content.isEmpty) return;
    setState(() { _sending = true; _showQuickMessages = false; });
    _controller.clear();
    try {
      await ref.read(householdChatProvider.notifier)
          .sendMessage(content, emoji: quickEmoji);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    } on ProfanityException catch (e) {
      if (mounted) {
        _controller.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nachricht konnte nicht gesendet werden')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(householdChatProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      // Scaffold schrumpft automatisch wenn Tastatur auftaucht
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Haushalt-Chat'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bolt_rounded,
              color: _showQuickMessages
                  ? theme.colorScheme.primary
                  : null,
            ),
            tooltip: 'Schnellnachrichten',
            onPressed: () =>
                setState(() => _showQuickMessages = !_showQuickMessages),
          ),
        ],
      ),
      body: Column(
        children: [
          // â”€â”€ Quick-Messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_showQuickMessages)
            Container(
              height: 46,
              color: theme.colorScheme.surfaceContainerLow,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                children: kQuickMessages.map((q) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Text(q.$1,
                        style: const TextStyle(fontSize: 14)),
                    label: Text(q.$2,
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () =>
                        _send(quickContent: q.$2, quickEmoji: q.$1),
                  ),
                )).toList(),
              ),
            ),

          // â”€â”€ Nachrichten-Liste â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Chat nicht verfügbar: $e',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.invalidate(householdChatProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Noch keine Nachrichten.\nSchreib die erste!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        final isMe = msg.userId == currentUserId;
                        return _ChatBubble(
                          message: msg,
                          isMe: isMe,
                          onDelete: isMe
                              ? () => ref
                                  .read(householdChatProvider.notifier)
                                  .deleteMessage(msg.id)
                              : null,
                        );
                      },
                    ),
            ),
          ),

          // â”€â”€ Eingabe (bleibt immer über der Tastatur) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12, 8, 12,
              8 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Nachricht…',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    minimumSize: Size.zero,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Chat-Blase â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChatBubble extends StatelessWidget {
  final HouseholdMessage message;
  final bool isMe;
  final VoidCallback? onDelete;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.content,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete != null
                  ? () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Nachricht lÃ¶schen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onDelete!();
                              },
                              style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error),
                              child: const Text('LÃ¶schen'),
                            ),
                          ],
                        ),
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(message.senderName,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.emoji != null) ...[
                          Text(message.emoji!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.timeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? theme.colorScheme.onPrimary
                                .withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

