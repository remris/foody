import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/community/presentation/community_local_provider.dart';
import 'package:kokomu/features/community/presentation/community_detail_screen.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/models/community.dart';

class CommunityListScreen extends ConsumerWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(myCommunitiesProvider);
    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Community erstellen',
            onPressed: () => _showCreateSheet(context, ref, isPro),
          ),
        ],
      ),
      body: communitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (communities) {
          final active = communities.where((c) => c.myStatus == 'active').toList();
          final pending = communities.where((c) => c.myStatus == 'pending').toList();

          if (communities.isEmpty) {
            return _EmptyView(isPro: isPro, onJoin: () => _showJoinSheet(context, ref));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(title: 'Meine Communities (${active.length})'),
                ...active.map((c) => _CommunityTile(
                      community: c,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityDetailScreen(community: c),
                        ),
                      ).then((_) => ref.invalidate(myCommunitiesProvider)),
                    )),
              ],
              if (pending.isNotEmpty) ...[
                _SectionHeader(title: 'Ausstehende Anfragen'),
                ...pending.map((c) => _CommunityTile(
                      community: c,
                      isPending: true,
                      onTap: null,
                    )),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinSheet(context, ref),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Community beitreten'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCreateButton(context, ref, isPro, theme),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateButton(
      BuildContext context, WidgetRef ref, bool isPro, ThemeData theme) {
    if (!isPro) {
      return OutlinedButton.icon(
        onPressed: () => _showProGate(context),
        icon: const Icon(Icons.lock_outline, size: 18),
        label: const Text('Community erstellen (Pro)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: () => _showCreateSheet(context, ref, isPro),
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Eigene Community erstellen'),
    );
  }

  void _showProGate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Communities erstellen ist nur mit Pro verfügbar.'),
        action: SnackBarAction(label: 'Pro holen', onPressed: _noop),
      ),
    );
  }

  static void _noop() {}

  void _showCreateSheet(BuildContext context, WidgetRef ref, bool isPro) {
    if (!isPro) {
      _showProGate(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateCommunitySheet(parentRef: ref),
    );
  }

  void _showJoinSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JoinCommunitySheet(parentRef: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leerer Zustand
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final bool isPro;
  final VoidCallback onJoin;
  const _EmptyView({required this.isPro, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Icon(Icons.groups_outlined,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Keine Communities', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tritt einer lokalen Community bei oder erstelle deine eigene (Pro). '
              'Tausche Reste, teile Rezepte und vernetze dich mit Nachbarn.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_add),
              label: const Text('Community beitreten'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Community Tile
// ─────────────────────────────────────────────────────────────────────────────
class _CommunityTile extends StatelessWidget {
  final Community community;
  final bool isPending;
  final VoidCallback? onTap;

  const _CommunityTile({
    required this.community,
    this.isPending = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          community.name.isNotEmpty ? community.name[0].toUpperCase() : '?',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(community.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          if (community.city != null) community.city!,
          if (community.plz != null) community.plz!,
          if (community.memberCount != null)
            '${community.memberCount} Mitglieder',
        ].join(' · '),
      ),
      trailing: isPending
          ? Chip(
              label: const Text('Ausstehend'),
              backgroundColor:
                  theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              labelStyle: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onTertiaryContainer),
              padding: EdgeInsets.zero,
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Community erstellen
// ─────────────────────────────────────────────────────────────────────────────
class _CreateCommunitySheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _CreateCommunitySheet({required this.parentRef});

  @override
  ConsumerState<_CreateCommunitySheet> createState() =>
      _CreateCommunitySheetState();
}

class _CreateCommunitySheetState
    extends ConsumerState<_CreateCommunitySheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _plzCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _plzCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name darf nicht leer sein');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final community = await ref
          .read(communityActionsProvider.notifier)
          .createCommunity(
            name: name,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            plz: _plzCtrl.text.trim().isEmpty ? null : _plzCtrl.text.trim(),
            city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        widget.parentRef.invalidate(myCommunitiesProvider);
        if (community != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(community: community),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.groups, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Community erstellen',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'z.B. „Nachbarn Schillerstraße"',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Beschreibung (optional)',
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _plzCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 5,
                decoration: const InputDecoration(
                  labelText: 'PLZ (optional)',
                  counterText: '',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stadt (optional)',
                ),
              ),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isLoading ? null : _create,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Wird erstellt...' : 'Erstellen'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Community beitreten (Code oder PLZ-Suche)
// ─────────────────────────────────────────────────────────────────────────────
class _JoinCommunitySheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _JoinCommunitySheet({required this.parentRef});

  @override
  ConsumerState<_JoinCommunitySheet> createState() =>
      _JoinCommunitySheetState();
}

class _JoinCommunitySheetState
    extends ConsumerState<_JoinCommunitySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _codeCtrl = TextEditingController();
  final _plzCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Community> _plzResults = [];
  bool _plzSearched = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Vorausfüllen mit Profil-Displayname
    final displayName = ref.read(currentUserProvider)?.email?.split('@').first ?? '';
    _nameCtrl.text = displayName;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _codeCtrl.dispose();
    _plzCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code muss 6 Zeichen lang sein');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(communityLocalRepoProvider);
      final community = await repo.findByInviteCode(code);
      if (community == null) {
        setState(() {
          _error = 'Kein Code gefunden';
          _isLoading = false;
        });
        return;
      }
      await _sendRequest(community);
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByPlz() async {
    final plz = _plzCtrl.text.trim();
    if (plz.length != 5) {
      setState(() => _error = 'PLZ muss 5 Stellen haben');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _plzSearched = false;
    });
    try {
      final results =
          await ref.read(communityLocalRepoProvider).searchByPlz(plz);
      setState(() {
        _plzResults = results;
        _plzSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRequest(Community community) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bitte Namen eingeben');
      _isLoading = false;
      return;
    }
    final error = await ref
        .read(communityActionsProvider.notifier)
        .requestToJoin(community, name);
    if (mounted) {
      if (error != null) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      } else {
        Navigator.pop(context);
        widget.parentRef.invalidate(myCommunitiesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Anfrage an „${community.name}" gesendet. Du wirst benachrichtigt sobald der Admin zustimmt.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.group_add, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Community beitreten',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'Per Code'),
              Tab(text: 'Per PLZ suchen'),
            ],
          ),
          const SizedBox(height: 16),
          // Name-Feld gemeinsam
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Dein Name in der Community',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Tab 1: Per Code ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Einladungscode (6 Stellen)',
                          hintText: 'z.B. AB12CD',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 13)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _joinByCode,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isLoading ? 'Suche...' : 'Anfrage senden'),
                      ),
                    ],
                  ),
                ),
                // ── Tab 2: Per PLZ ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _plzCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            maxLength: 5,
                            decoration: const InputDecoration(
                              labelText: 'PLZ eingeben',
                              counterText: '',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isLoading ? null : _searchByPlz,
                          child: const Text('Suchen'),
                        ),
                      ]),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 13)),
                      if (_plzSearched && _plzResults.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('Keine Communities in dieser PLZ gefunden.'),
                        ),
                      if (_plzResults.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: _plzResults.length,
                            itemBuilder: (context, i) {
                              final c = _plzResults[i];
                              return ListTile(
                                title: Text(c.name),
                                subtitle: Text(
                                    '${c.city ?? ''} · ${c.memberCount ?? '?'} Mitglieder'),
                                trailing: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() => _isLoading = true);
                                          _sendRequest(c);
                                        },
                                  child: const Text('Anfrage'),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

