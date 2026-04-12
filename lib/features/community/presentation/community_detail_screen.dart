import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/community/presentation/community_local_provider.dart';
import 'package:kokomu/features/community/data/community_recipe_repository.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomu/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/models/community.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/models/community_meal_plan.dart';
import 'package:kokomu/models/recipe.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final Community community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late Community _community;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin =>
      ref.read(currentUserProvider)?.id == _community.adminId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_community.name),
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAdminAction(value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'members',
                    child: ListTile(
                        leading: Icon(Icons.people),
                        title: Text('Mitglieder verwalten'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                const PopupMenuItem(
                    value: 'code',
                    child: ListTile(
                        leading: Icon(Icons.vpn_key),
                        title: Text('Code kopieren'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                const PopupMenuItem(
                    value: 'regen',
                    child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Code neu generieren'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                const PopupMenuDivider(),
                const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Community auflösen',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
              ],
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) => _handleMemberAction(value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.red),
                        title: Text('Community verlassen',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.dynamic_feed_outlined), text: 'Feed'),
            Tab(icon: Icon(Icons.volunteer_activism_outlined), text: 'Teilen'),
            Tab(icon: Icon(Icons.people_outline), text: 'Mitglieder'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _FeedTab(community: _community),
          _ShareTab(community: _community),
          _MembersTab(community: _community, isAdmin: _isAdmin),
        ],
      ),
      floatingActionButton: _buildFab(theme),
    );
  }

  Widget? _buildFab(ThemeData theme) {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        if (_tabCtrl.index == 0) {
          return FloatingActionButton(
            onPressed: () => _showCreatePostSheet(),
            tooltip: 'Post erstellen',
            child: const Icon(Icons.add_comment_outlined),
          );
        }
        if (_tabCtrl.index == 1) {
          return FloatingActionButton(
            onPressed: () => _showOfferShareSheet(),
            tooltip: 'Angebot erstellen',
            child: const Icon(Icons.add_outlined),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _handleAdminAction(String value) async {
    switch (value) {
      case 'members':
        _tabCtrl.animateTo(2);
        break;
      case 'code':
        await Clipboard.setData(ClipboardData(text: _community.inviteCode));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Code „${_community.inviteCode}" kopiert!')),
          );
        }
        break;
      case 'regen':
        final code = await ref
            .read(communityActionsProvider.notifier)
            .regenerateCode(_community.id);
        if (mounted) {
          setState(() =>
              _community = _community.copyWith(inviteCode: code));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Neuer Code: $code')),
          );
        }
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _handleMemberAction(String value) {
    if (value == 'leave') _confirmLeave();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Community auflösen?'),
        content: const Text(
            'Alle Mitglieder, Posts und Angebote werden unwiderruflich gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(communityActionsProvider.notifier)
                  .deleteCommunity(_community.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Auflösen'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Community verlassen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(communityActionsProvider.notifier)
                  .leaveCommunity(_community.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreatePostSheet(communityId: _community.id),
    );
  }

  void _showOfferShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OfferShareSheet(communityId: _community.id),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Tab
// ─────────────────────────────────────────────────────────────────────────────
class _FeedTab extends ConsumerWidget {
  final Community community;
  const _FeedTab({required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider(community.id));
    final userId = ref.watch(currentUserProvider)?.id;

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dynamic_feed_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Noch keine Posts.',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Tippe auf + um den ersten Post zu erstellen.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(communityPostsProvider(community.id)),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final post = posts[i];
              return _PostCard(
                post: post,
                isOwn: post.userId == userId,
                onDelete: () async {
                  await ref
                      .read(communityActionsProvider.notifier)
                      .deletePost(post.id, community.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Card
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isOwn;
  final VoidCallback onDelete;
  const _PostCard(
      {required this.post, required this.isOwn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (post.authorName?.isNotEmpty == true)
                      ? post.authorName![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName ?? 'Unbekannt',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      _relativeTime(post.createdAt),
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isOwn)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: onDelete,
                ),
            ]),
            const SizedBox(height: 8),
            Text(post.content),
            // Rezept-Anhang
            if (post.recipeTitle != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (post.recipeId == null) return;
                  // Versuche das Rezept in der Community zu finden
                  _openAttachedRecipe(context, post.recipeId!, post.recipeTitle!);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.restaurant_menu_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(post.recipeTitle!,
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: theme.colorScheme.primary),
                  ]),
                ),
              ),
            ],
            // Wochenplan-Anhang
            if (post.mealPlanTitle != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (post.mealPlanId == null) return;
                  _openAttachedMealPlan(context, post.mealPlanId!, post.mealPlanTitle!);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(post.mealPlanTitle!,
                          style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: theme.colorScheme.secondary),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tag${diff.inDays == 1 ? '' : 'en'}';
    return 'vor ${diff.inDays ~/ 7} Woche${diff.inDays ~/ 7 == 1 ? '' : 'n'}';
  }

  void _openAttachedRecipe(BuildContext context, String recipeId, String title) async {
    try {
      // Versuche das Rezept aus community_recipes zu laden
      final repo = CommunityRecipeRepository();
      final data = await SupabaseService.client
          .from('community_recipes')
          .select()
          .eq('id', recipeId)
          .maybeSingle();
      if (data != null && context.mounted) {
        final recipe = CommunityRecipe.fromJson(data);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CommunityRecipeDetailScreen(recipe: recipe),
        ));
        return;
      }
    } catch (_) {}
    // Fallback: Snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rezept "$title" konnte nicht geladen werden.')),
      );
    }
  }

  void _openAttachedMealPlan(BuildContext context, String planId, String title) async {
    try {
      final data = await SupabaseService.client
          .from('community_meal_plans')
          .select()
          .eq('id', planId)
          .maybeSingle();
      if (data != null && context.mounted) {
        final plan = CommunityMealPlan.fromJson(data);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CommunityMealPlanDetailScreen(plan: plan),
        ));
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wochenplan "$title" konnte nicht geladen werden.')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share Tab (Reste / Vorrat verschenken + Suchanfragen)
// ─────────────────────────────────────────────────────────────────────────────
class _ShareTab extends ConsumerStatefulWidget {
  final Community community;
  const _ShareTab({required this.community});

  @override
  ConsumerState<_ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends ConsumerState<_ShareTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabCtrl;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Sub-Tab-Bar
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _subTabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.volunteer_activism_outlined, size: 18), text: 'Angebote'),
              Tab(icon: Icon(Icons.search_outlined, size: 18), text: 'Suche'),
            ],
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              _OffersSubTab(community: widget.community),
              _HelpSubTab(community: widget.community),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-Tab: Angebote (verschenken) ───────────────────────────────────────────
class _OffersSubTab extends ConsumerWidget {
  final Community community;
  const _OffersSubTab({required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesAsync = ref.watch(communitySharesProvider(community.id));
    final userId = ref.watch(currentUserProvider)?.id;
    final theme = Theme.of(context);

    return sharesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (shares) {
        final ownShares = shares.where((s) => s.offeredBy == userId).toList();
        final otherShares = shares.where((s) => s.offeredBy != userId).toList();

        if (shares.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volunteer_activism_outlined,
                      size: 56,
                      color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Noch keine Angebote', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Biete Reste oder überschüssige Lebensmittel an – andere können eine Abholung anfragen.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showOfferSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Etwas anbieten'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(communitySharesProvider(community.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              // ── Angebote von anderen ────────────────────────────────────
              if (otherShares.isNotEmpty) ...[
                _SectionBadge(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Von der Community (${otherShares.length})',
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                ...otherShares.map((share) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ShareOfferCard(
                        share: share,
                        communityId: community.id,
                        isOwn: false,
                        currentUserId: userId ?? '',
                      ),
                    )),
              ],

              // ── Eigene Angebote ─────────────────────────────────────────
              if (ownShares.isNotEmpty) ...[
                if (otherShares.isNotEmpty) const SizedBox(height: 8),
                _SectionBadge(
                  icon: Icons.inventory_2_outlined,
                  label: 'Meine Angebote (${ownShares.length})',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                ...ownShares.map((share) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ShareOfferCard(
                        share: share,
                        communityId: community.id,
                        isOwn: true,
                        currentUserId: userId ?? '',
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showOfferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OfferShareSheet(communityId: community.id),
    );
  }
}

// ── Sub-Tab: Suchanfragen ─────────────────────────────────────────────────────
class _HelpSubTab extends ConsumerWidget {
  final Community community;
  const _HelpSubTab({required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpAsync = ref.watch(helpRequestsProvider(community.id));
    final userId = ref.watch(currentUserProvider)?.id;
    final theme = Theme.of(context);

    return helpAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (requests) {
        final ownReqs = requests.where((r) => r.userId == userId).toList();
        final otherReqs = requests.where((r) => r.userId != userId).toList();

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_outlined,
                      size: 56,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Keine offenen Anfragen', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Suche etwas Bestimmtes? Stell eine Anfrage – Nachbarn können aushelfen.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showHelpSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Etwas suchen'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(helpRequestsProvider(community.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              // ── Anfragen von anderen ────────────────────────────────────
              if (otherReqs.isNotEmpty) ...[
                _SectionBadge(
                  icon: Icons.help_outline,
                  label: 'Anfragen (${otherReqs.length})',
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                ...otherReqs.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HelpRequestCard(
                        request: req,
                        communityId: community.id,
                        isOwn: false,
                        currentUserId: userId ?? '',
                      ),
                    )),
              ],

              // ── Eigene Anfragen ─────────────────────────────────────────
              if (ownReqs.isNotEmpty) ...[
                if (otherReqs.isNotEmpty) const SizedBox(height: 8),
                _SectionBadge(
                  icon: Icons.person_search_outlined,
                  label: 'Meine Anfragen (${ownReqs.length})',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                ...ownReqs.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HelpRequestCard(
                        request: req,
                        communityId: community.id,
                        isOwn: true,
                        currentUserId: userId ?? '',
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateHelpRequestSheet(communityId: community.id),
    );
  }
}

// ── Share Offer Card (Angebot mit Anfragen-Flow) ──────────────────────────────
class _ShareOfferCard extends ConsumerWidget {
  final CommunityShare share;
  final String communityId;
  final bool isOwn;
  final String currentUserId;

  const _ShareOfferCard({
    required this.share,
    required this.communityId,
    required this.isOwn,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync =
        isOwn ? ref.watch(shareRequestsProvider(share.id)) : null;

    final pendingCount = requestsAsync?.valueOrNull
            ?.where((r) => r.isPending)
            .length ??
        0;
    final acceptedRequest = requestsAsync?.valueOrNull
        ?.where((r) => r.isAccepted)
        .firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOwn
                        ? Icons.inventory_2_outlined
                        : Icons.volunteer_activism_outlined,
                    color: isOwn
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            share.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (isOwn && pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                        if (isOwn && pendingCount == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Mein Angebot',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ]),
                      if (share.quantity != null)
                        Text(share.quantity!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13)),
                      if (share.note != null)
                        Text(share.note!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Text(
                        isOwn
                            ? 'Du bietest das an'
                            : 'von ${share.offeredByName ?? 'Unbekannt'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Löschen für eigene
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Angebot zurückziehen',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
              ],
            ),

            // ── Abgeholt-Button (nur wenn Anfrage angenommen) ────────────
            if (isOwn && acceptedRequest != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${acceptedRequest.displayName ?? 'Jemand'} holt ab',
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openChat(context, acceptedRequest,
                              'share', acceptedRequest.id),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Schreiben'),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _confirmPickedUp(context, ref),
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('Abgeholt ✓'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],

            // ── Anfragen-Liste für eigene Angebote ───────────────────────
            if (isOwn && acceptedRequest == null && pendingCount > 0) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Anfragen ($pendingCount)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ...(requestsAsync?.valueOrNull
                          ?.where((r) => r.isPending)
                          .map((req) => _ShareRequestTile(
                                request: req,
                                share: share,
                                communityId: communityId,
                              ))
                          .toList() ??
                      []),
            ],

            // ── Anfrage stellen Button für fremde Angebote ────────────────
            if (!isOwn) ...[
              const SizedBox(height: 10),
              _PickupRequestButton(
                share: share,
                communityId: communityId,
                currentUserId: currentUserId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openChat(
      BuildContext context, CommunityShareRequest req, String type, String ctxId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChatSheet(
        contextType: type,
        contextId: ctxId,
        communityId: communityId,
        otherUserId: req.userId,
        otherUserName: req.displayName ?? 'Unbekannt',
        title: 'Chat: ${share.itemName}',
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('„${share.itemName}" zurückziehen?'),
        content: const Text('Das Angebot wird aus der Liste entfernt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(communityActionsProvider.notifier)
                  .deleteShare(share.id, communityId);
            },
            child: const Text('Zurückziehen'),
          ),
        ],
      ),
    );
  }

  void _confirmPickedUp(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.done_all, color: Colors.green, size: 32),
        title: Text('„${share.itemName}" abgeholt?'),
        content: const Text('Das Angebot wird aus der Liste entfernt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(communityActionsProvider.notifier)
                  .markSharePickedUp(
                    shareId: share.id,
                    communityId: communityId,
                  );
            },
            child: const Text('Ja, abgeholt!'),
          ),
        ],
      ),
    );
  }
}

// ── Anfrage-Kachel (für Angebots-Ersteller) ───────────────────────────────────
class _ShareRequestTile extends ConsumerWidget {
  final CommunityShareRequest request;
  final CommunityShare share;
  final String communityId;
  const _ShareRequestTile(
      {required this.request, required this.share, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserProvider)?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            (request.displayName?.isNotEmpty == true)
                ? request.displayName![0].toUpperCase()
                : '?',
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.displayName ?? 'Unbekannt',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (request.message != null)
                Text(request.message!,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        // Chat-Button
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          color: theme.colorScheme.primary,
          tooltip: 'Schreiben',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _ChatSheet(
              contextType: 'share',
              contextId: request.id,
              communityId: communityId,
              otherUserId: request.userId,
              otherUserName: request.displayName ?? 'Unbekannt',
              title: 'Chat: ${share.itemName}',
            ),
          ),
        ),
        // Annehmen
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 18),
          color: Colors.green,
          tooltip: 'Bestätigen',
          onPressed: () async {
            await ref
                .read(communityActionsProvider.notifier)
                .acceptShareRequest(
                  requestId: request.id,
                  shareId: share.id,
                  communityId: communityId,
                );
          },
        ),
        // Ablehnen
        IconButton(
          icon: const Icon(Icons.cancel_outlined, size: 18),
          color: Colors.red,
          tooltip: 'Ablehnen',
          onPressed: () async {
            await ref
                .read(communityActionsProvider.notifier)
                .rejectShareRequest(
                  requestId: request.id,
                  shareId: share.id,
                );
          },
        ),
      ]),
    );
  }
}

// ── Anfrage stellen Button (für nicht-eigene Angebote) ────────────────────────
class _PickupRequestButton extends ConsumerStatefulWidget {
  final CommunityShare share;
  final String communityId;
  final String currentUserId;
  const _PickupRequestButton(
      {required this.share,
      required this.communityId,
      required this.currentUserId});

  @override
  ConsumerState<_PickupRequestButton> createState() =>
      _PickupRequestButtonState();
}

class _PickupRequestButtonState extends ConsumerState<_PickupRequestButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final reqsAsync = ref.watch(shareRequestsProvider(widget.share.id));
    final myReq = reqsAsync.valueOrNull
        ?.where((r) => r.userId == widget.currentUserId)
        .firstOrNull;

    if (myReq != null) {
      if (myReq.isAccepted) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _ChatSheet(
                contextType: 'share',
                contextId: myReq.id,
                communityId: widget.communityId,
                otherUserId: widget.share.offeredBy,
                otherUserName: widget.share.offeredByName ?? 'Anbieter',
                title: 'Chat: ${widget.share.itemName}',
              ),
            ),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Bestätigt – Schreiben'),
          ),
        );
      }
      if (myReq.isRejected) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Deine Anfrage wurde abgelehnt',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13),
          ),
        );
      }
      // pending
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            setState(() => _loading = true);
            await ref
                .read(communityActionsProvider.notifier)
                .deleteShareRequest(
                  requestId: myReq.id,
                  shareId: widget.share.id,
                );
            if (mounted) setState(() => _loading = false);
          },
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.hourglass_empty, size: 16),
          label: const Text('Anfrage ausstehend – zurückziehen?'),
        ),
      );
    }

    // Noch keine Anfrage
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: _loading
            ? null
            : () => _showRequestSheet(context),
        icon: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.back_hand_outlined, size: 16),
        label: const Text('Abholen anfragen'),
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10)),
      ),
    );
  }

  void _showRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PickupRequestSheet(
        share: widget.share,
        communityId: widget.communityId,
      ),
    );
  }
}

// ── Help Request Card (Suchanfragen) ──────────────────────────────────────────
class _HelpRequestCard extends ConsumerWidget {
  final CommunityHelpRequest request;
  final String communityId;
  final bool isOwn;
  final String currentUserId;

  const _HelpRequestCard({
    required this.request,
    required this.communityId,
    required this.isOwn,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offersAsync =
        isOwn ? ref.watch(helpOffersProvider(request.id)) : null;
    final pendingOffers =
        offersAsync?.valueOrNull?.where((o) => o.isPending).toList() ?? [];
    final acceptedOffer =
        offersAsync?.valueOrNull?.where((o) => o.isAccepted).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.search_outlined,
                      color: theme.colorScheme.secondary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            request.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (isOwn && pendingOffers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${pendingOffers.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                      ]),
                      if (request.quantity != null)
                        Text(request.quantity!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13)),
                      if (request.note != null)
                        Text(request.note!,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Text(
                        isOwn
                            ? 'Deine Anfrage'
                            : 'von ${request.displayName ?? 'Unbekannt'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Schließen für eigene
                if (isOwn)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (v) async {
                      if (v == 'close') {
                        await ref
                            .read(communityActionsProvider.notifier)
                            .closeHelpRequest(request.id, communityId);
                      } else if (v == 'delete') {
                        await ref
                            .read(communityActionsProvider.notifier)
                            .deleteHelpRequest(request.id, communityId);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'close',
                          child: ListTile(
                              leading: Icon(Icons.check_circle_outline),
                              title: Text('Anfrage schließen'),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                      const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Löschen',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                    ],
                  ),
              ],
            ),

            // ── Akzeptiertes Angebot ──────────────────────────────────────
            if (isOwn && acceptedOffer != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${acceptedOffer.displayName ?? 'Jemand'} hilft dir',
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _ChatSheet(
                            contextType: 'help',
                            contextId: request.id,
                            communityId: communityId,
                            otherUserId: acceptedOffer.userId,
                            otherUserName:
                                acceptedOffer.displayName ?? 'Unbekannt',
                            title: 'Chat: ${request.itemName}',
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Schreiben'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Aushelfer-Angebote Liste ──────────────────────────────────
            if (isOwn && acceptedOffer == null && pendingOffers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Aushelfer (${pendingOffers.length})',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ...pendingOffers.map((offer) => _HelpOfferTile(
                    offer: offer,
                    request: request,
                    communityId: communityId,
                  )),
            ],

            // ── Aushelfen-Button für andere ───────────────────────────────
            if (!isOwn) ...[
              const SizedBox(height: 10),
              _HelpOfferButton(
                request: request,
                communityId: communityId,
                currentUserId: currentUserId,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Aushelfer-Kachel ──────────────────────────────────────────────────────────
class _HelpOfferTile extends ConsumerWidget {
  final CommunityHelpOffer offer;
  final CommunityHelpRequest request;
  final String communityId;
  const _HelpOfferTile(
      {required this.offer,
      required this.request,
      required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            (offer.displayName?.isNotEmpty == true)
                ? offer.displayName![0].toUpperCase()
                : '?',
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSecondaryContainer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.displayName ?? 'Unbekannt',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (offer.message != null)
                Text(offer.message!,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        // Chat
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          color: theme.colorScheme.primary,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _ChatSheet(
              contextType: 'help',
              contextId: request.id,
              communityId: communityId,
              otherUserId: offer.userId,
              otherUserName: offer.displayName ?? 'Unbekannt',
              title: 'Chat: ${request.itemName}',
            ),
          ),
        ),
        // Annehmen
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 18),
          color: Colors.green,
          tooltip: 'Annehmen',
          onPressed: () async {
            await ref
                .read(communityActionsProvider.notifier)
                .acceptHelpOffer(
                  offerId: offer.id,
                  requestId: request.id,
                );
          },
        ),
        // Ablehnen
        IconButton(
          icon: const Icon(Icons.cancel_outlined, size: 18),
          color: Colors.red,
          onPressed: () async {
            await ref
                .read(communityActionsProvider.notifier)
                .deleteHelpOffer(
                  offerId: offer.id,
                  requestId: request.id,
                );
          },
        ),
      ]),
    );
  }
}

// ── Aushelfen-Button ──────────────────────────────────────────────────────────
class _HelpOfferButton extends ConsumerStatefulWidget {
  final CommunityHelpRequest request;
  final String communityId;
  final String currentUserId;
  const _HelpOfferButton(
      {required this.request,
      required this.communityId,
      required this.currentUserId});

  @override
  ConsumerState<_HelpOfferButton> createState() => _HelpOfferButtonState();
}

class _HelpOfferButtonState extends ConsumerState<_HelpOfferButton> {
  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(helpOffersProvider(widget.request.id));
    final myOffer = offersAsync.valueOrNull
        ?.where((o) => o.userId == widget.currentUserId)
        .firstOrNull;

    if (myOffer != null) {
      if (myOffer.isAccepted) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _ChatSheet(
                contextType: 'help',
                contextId: widget.request.id,
                communityId: widget.communityId,
                otherUserId: widget.request.userId,
                otherUserName: widget.request.displayName ?? 'Anfragesteller',
                title: 'Chat: ${widget.request.itemName}',
              ),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Bestätigt – Schreiben'),
          ),
        );
      }
      // pending
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref
                .read(communityActionsProvider.notifier)
                .deleteHelpOffer(
                  offerId: myOffer.id,
                  requestId: widget.request.id,
                );
          },
          icon: const Icon(Icons.hourglass_empty, size: 16),
          label: const Text('Aushelfen angeboten – zurückziehen?'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => _showHelpOfferSheet(context),
        icon: const Icon(Icons.volunteer_activism_outlined, size: 16),
        label: const Text('Aushelfen'),
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10)),
      ),
    );
  }

  void _showHelpOfferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _HelpOfferSheet(
        request: widget.request,
        communityId: widget.communityId,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Badge
// ─────────────────────────────────────────────────────────────────────────────
class _SectionBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share Card
// ─────────────────────────────────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final CommunityShare share;
  final bool isOwn;
  final VoidCallback? onClaim;
  final VoidCallback? onDelete;

  const _ShareCard({
    required this.share,
    required this.isOwn,
    this.onClaim,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOwn
                        ? Icons.inventory_2_outlined
                        : Icons.volunteer_activism_outlined,
                    color: isOwn
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            share.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (isOwn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Mein Angebot',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ]),
                      if (share.quantity != null)
                        Text(
                          share.quantity!,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13),
                        ),
                      if (share.note != null)
                        Text(
                          share.note!,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        isOwn
                            ? 'Du bietest das an'
                            : 'von ${share.offeredByName ?? 'Unbekannt'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Löschen für eigene
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Angebot zurückziehen',
                    onPressed: onDelete,
                  ),
              ],
            ),
            // Abholen-Button für fremde – volle Breite
            if (onClaim != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onClaim,
                  icon: const Icon(Icons.back_hand_outlined, size: 16),
                  label: const Text('Abholen'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

// ─────────────────────────────────────────────────────────────────────────────
// Members Tab
// ─────────────────────────────────────────────────────────────────────────────
class _MembersTab extends ConsumerWidget {
  final Community community;
  final bool isAdmin;
  const _MembersTab({required this.community, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(communityMembersProvider(community.id));
    final theme = Theme.of(context);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (members) {
        final active = members.where((m) => m.status == 'active').toList();
        final pending = members.where((m) => m.status == 'pending').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Code-Anzeige für Admin
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: ListTile(
                    leading: Icon(Icons.vpn_key,
                        color: theme.colorScheme.primary),
                    title: Text('Einladungscode: ${community.inviteCode}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        const Text('Teile diesen Code um Mitglieder einzuladen'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: community.inviteCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code kopiert!')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),

            // Ausstehende Anfragen
            if (pending.isNotEmpty && isAdmin) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Beitrittsanfragen (${pending.length})',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ...pending.map((m) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.tertiaryContainer,
                      child: Text(
                        (m.displayName?.isNotEmpty == true)
                            ? m.displayName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer),
                      ),
                    ),
                    title: Text(m.displayName ?? 'Unbekannt'),
                    subtitle: const Text('Wartet auf Genehmigung'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          tooltip: 'Annehmen',
                          onPressed: () async {
                            await ref
                                .read(communityActionsProvider.notifier)
                                .acceptMember(m.id, community.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red),
                          tooltip: 'Ablehnen',
                          onPressed: () async {
                            await ref
                                .read(communityActionsProvider.notifier)
                                .rejectMember(m.id, community.id);
                          },
                        ),
                      ],
                    ),
                  )),
            ],

            // Aktive Mitglieder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Mitglieder (${active.length}/${community.maxMembers})',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ...active.map((m) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (m.displayName?.isNotEmpty == true)
                          ? m.displayName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(m.displayName ?? 'Unbekannt'),
                  subtitle: Text(m.userId == community.adminId
                      ? 'Admin'
                      : 'Mitglied'),
                  trailing: isAdmin && m.userId != community.adminId
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red, size: 20),
                          tooltip: 'Entfernen',
                          onPressed: () async {
                            await ref
                                .read(communityActionsProvider.notifier)
                                .removeMember(m.id, community.id);
                          },
                        )
                      : null,
                )),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Post erstellen
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePostSheet extends ConsumerStatefulWidget {
  final String communityId;
  const _CreatePostSheet({required this.communityId});

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _attachedRecipeId;
  String? _attachedRecipeTitle;
  String? _attachedMealPlanId;
  String? _attachedMealPlanTitle;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Text darf nicht leer sein');
      return;
    }
    if (content.length > 1000) {
      setState(() => _error = 'Maximal 1000 Zeichen');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(communityActionsProvider.notifier).createPost(
            communityId: widget.communityId,
            content: content,
            recipeId: _attachedRecipeId,
            recipeTitle: _attachedRecipeTitle,
            mealPlanId: _attachedMealPlanId,
            mealPlanTitle: _attachedMealPlanTitle,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  void _pickRecipe() async {
    final userId = ref.read(userProfileRepositoryProvider).currentUserId ?? '';
    List<CommunityRecipe> ownRecipes = [];
    try {
      ownRecipes = await CommunityRecipeRepository().getMyAllRecipes(userId);
    } catch (_) {}
    final List<FoodRecipe> savedFallback;
    if (ownRecipes.isEmpty) {
      final all = ref.read(savedRecipesProvider).valueOrNull ?? [];
      savedFallback = all
          .where((r) => r.source == 'own' || r.source == 'ai' || r.source == 'manual')
          .toList();
    } else {
      savedFallback = [];
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          child: Column(
            children: [
              Center(child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(children: [
                  Icon(Icons.restaurant_menu_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Mein Rezept anhängen',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Nur eigene und KI-Rezepte.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const Divider(height: 1),
              if (ownRecipes.isEmpty && savedFallback.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Keine eigenen Rezepte vorhanden.', textAlign: TextAlign.center),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      ...ownRecipes.map((r) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: r.imageUrl?.isNotEmpty == true ? NetworkImage(r.imageUrl!) : null,
                              child: r.imageUrl?.isNotEmpty != true
                                  ? Icon(Icons.restaurant_menu_outlined, size: 18,
                                      color: theme.colorScheme.onPrimaryContainer)
                                  : null,
                            ),
                            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${r.cookingTimeMinutes} Min.', style: theme.textTheme.labelSmall),
                            trailing: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                _attachedRecipeId = r.id;
                                _attachedRecipeTitle = r.title;
                                _attachedMealPlanId = null;
                                _attachedMealPlanTitle = null;
                              });
                            },
                          )),
                      ...savedFallback.map((r) {
                        final isAi = r.source == 'ai';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAi
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              isAi ? Icons.auto_awesome_rounded : Icons.restaurant_menu_outlined,
                              size: 18,
                              color: isAi
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${r.cookingTimeMinutes} Min.', style: theme.textTheme.labelSmall),
                          trailing: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _attachedRecipeId = r.savedRecipeId ?? '';
                              _attachedRecipeTitle = r.title;
                              _attachedMealPlanId = null;
                              _attachedMealPlanTitle = null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _pickPlan() async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    final userId = ref.read(userProfileRepositoryProvider).currentUserId ?? '';
    final plans = await repo.getMyAllPlans(userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          child: Column(
            children: [
              Center(child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(children: [
                  Icon(Icons.calendar_month_outlined, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Meinen Wochenplan anhängen',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
              ),
              const Divider(height: 1),
              if (plans.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Keine eigenen Wochenpläne vorhanden.', textAlign: TextAlign.center),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: plans.map((p) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(Icons.calendar_month_outlined, size: 18,
                                color: theme.colorScheme.onSecondaryContainer),
                          ),
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.secondary),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _attachedMealPlanId = p.id;
                              _attachedMealPlanTitle = p.title;
                              _attachedRecipeId = null;
                              _attachedRecipeTitle = null;
                            });
                          },
                        )).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = 1000 - _contentCtrl.text.length;
    final hasAttachment = _attachedRecipeTitle != null || _attachedMealPlanTitle != null;

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
            Icon(Icons.add_comment_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Post erstellen',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Was möchtest du teilen?',
              alignLabelWithHint: true,
              counterText: '$remaining Zeichen übrig',
            ),
          ),
          // Anhang-Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickRecipe,
                icon: const Icon(Icons.restaurant_menu_outlined, size: 16),
                label: const Text('Rezept', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickPlan,
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Plan', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          // Anhang-Vorschau
          if (hasAttachment) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachedRecipeTitle != null
                        ? Icons.restaurant_menu_outlined
                        : Icons.calendar_month_outlined,
                    size: 16,
                    color: _attachedRecipeTitle != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedRecipeTitle ?? _attachedMealPlanTitle ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _attachedRecipeTitle != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      _attachedRecipeId = null;
                      _attachedRecipeTitle = null;
                      _attachedMealPlanId = null;
                      _attachedMealPlanTitle = null;
                    }),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: Text(_isLoading ? 'Wird gepostet...' : 'Posten'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Angebot erstellen
// ─────────────────────────────────────────────────────────────────────────────
class _OfferShareSheet extends ConsumerStatefulWidget {
  final String communityId;
  const _OfferShareSheet({required this.communityId});

  @override
  ConsumerState<_OfferShareSheet> createState() => _OfferShareSheetState();
}

class _OfferShareSheetState extends ConsumerState<_OfferShareSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bezeichnung darf nicht leer sein');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(communityActionsProvider.notifier).offerShare(
            communityId: widget.communityId,
            itemName: name,
            quantity: _qtyCtrl.text.trim().isEmpty ? null : _qtyCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
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
            Icon(Icons.volunteer_activism_outlined,
                color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text('Angebot erstellen',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Biete Reste oder Lebensmittel kostenlos an. '
            'Sobald jemand „Abholen" klickt, verschwindet das Angebot automatisch.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Was bietest du an? *',
              hintText: 'z.B. „Äpfel vom Baum", „Reste Lasagne"',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(
              labelText: 'Menge (optional)',
              hintText: 'z.B. „ca. 1 kg", „2 Portionen"',
              prefixIcon: Icon(Icons.straighten_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Hinweis (optional)',
              hintText: 'z.B. Abholung bis morgen, Eingang links',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Wird gespeichert...' : 'Anbieten'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Suchanfrage erstellen
// ─────────────────────────────────────────────────────────────────────────────
class _CreateHelpRequestSheet extends ConsumerStatefulWidget {
  final String communityId;
  const _CreateHelpRequestSheet({required this.communityId});
  @override
  ConsumerState<_CreateHelpRequestSheet> createState() => _CreateHelpRequestSheetState();
}

class _CreateHelpRequestSheetState extends ConsumerState<_CreateHelpRequestSheet> {
  final _itemCtrl = TextEditingController();
  final _qtyCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() { _itemCtrl.dispose(); _qtyCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final item = _itemCtrl.text.trim();
    if (item.isEmpty) { setState(() => _error = 'Bezeichnung darf nicht leer sein'); return; }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(communityActionsProvider.notifier).createHelpRequest(
        communityId: widget.communityId, itemName: item,
        quantity: _qtyCtrl.text.trim().isEmpty ? null : _qtyCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) { setState(() { _error = 'Fehler: $e'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left:20,right:20,top:20,bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.search_outlined, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text('Etwas suchen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _itemCtrl, autofocus: true,
          decoration: const InputDecoration(labelText: 'Was suchst du? *', hintText: 'z.B. „5 Eier"', prefixIcon: Icon(Icons.help_outline))),
        const SizedBox(height: 12),
        TextField(controller: _qtyCtrl,
          decoration: const InputDecoration(labelText: 'Menge (optional)', prefixIcon: Icon(Icons.straighten_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _noteCtrl,
          decoration: const InputDecoration(labelText: 'Hinweis (optional)', prefixIcon: Icon(Icons.notes_outlined))),
        if (_error != null) ...[const SizedBox(height:8), Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize:13))],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.send_outlined),
          label: Text(_isLoading ? 'Wird gespeichert...' : 'Anfrage stellen'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Abholungsanfrage stellen
// ─────────────────────────────────────────────────────────────────────────────
class _PickupRequestSheet extends ConsumerStatefulWidget {
  final CommunityShare share;
  final String communityId;
  const _PickupRequestSheet({required this.share, required this.communityId});
  @override
  ConsumerState<_PickupRequestSheet> createState() => _PickupRequestSheetState();
}

class _PickupRequestSheetState extends ConsumerState<_PickupRequestSheet> {
  final _msgCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(communityActionsProvider.notifier).requestPickup(
        shareId: widget.share.id, communityId: widget.communityId,
        message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'))); setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left:20,right:20,top:20,bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.back_hand_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Abholen anfragen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text('${widget.share.itemName}${widget.share.quantity != null ? ' · ${widget.share.quantity}' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(controller: _msgCtrl, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Nachricht (optional)', hintText: 'z.B. „Wann kann ich vorbeikommen?"', prefixIcon: Icon(Icons.chat_bubble_outline))),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.send_outlined),
          label: Text(_isLoading ? 'Wird gesendet...' : 'Anfrage senden'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Aushelfen anbieten
// ─────────────────────────────────────────────────────────────────────────────
class _HelpOfferSheet extends ConsumerStatefulWidget {
  final CommunityHelpRequest request;
  final String communityId;
  const _HelpOfferSheet({required this.request, required this.communityId});
  @override
  ConsumerState<_HelpOfferSheet> createState() => _HelpOfferSheetState();
}

class _HelpOfferSheetState extends ConsumerState<_HelpOfferSheet> {
  final _msgCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(communityActionsProvider.notifier).offerHelp(
        requestId: widget.request.id, communityId: widget.communityId,
        message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'))); setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left:20,right:20,top:20,bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.volunteer_activism_outlined, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text('Aushelfen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text('${widget.request.itemName}${widget.request.quantity != null ? ' · ${widget.request.quantity}' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(controller: _msgCtrl, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Nachricht (optional)', hintText: 'z.B. „Ich hätte das noch da!"', prefixIcon: Icon(Icons.chat_bubble_outline))),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.volunteer_activism_outlined),
          label: Text(_isLoading ? 'Wird gesendet...' : 'Aushelfen anbieten'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Mini-Chat
// ─────────────────────────────────────────────────────────────────────────────
class _ChatSheet extends ConsumerStatefulWidget {
  final String contextType;
  final String contextId;
  final String communityId;
  final String otherUserId;
  final String otherUserName;
  final String title;

  const _ChatSheet({
    required this.contextType,
    required this.contextId,
    required this.communityId,
    required this.otherUserId,
    required this.otherUserName,
    required this.title,
  });

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final _msgCtrl  = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ref.read(communityActionsProvider.notifier).sendMessage(
        contextType: widget.contextType,
        contextId: widget.contextId,
        communityId: widget.communityId,
        recipientId: widget.otherUserId,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = ref.watch(currentUserProvider)?.id;
    final msgsAsync = ref.watch(
        communityMessagesProvider(msgParams(widget.contextType, widget.contextId)));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
            Text(widget.otherUserName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: msgsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (msgs) {
              if (msgs.isEmpty) {
                return Center(child: Text('Noch keine Nachrichten.\nSchreib die erste!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
              }
              return ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final msg = msgs[i];
                  final isMe = msg.senderId == myId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg.text, style: TextStyle(color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left:12, right:12, top:8, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: InputDecoration(
                  hintText: 'Nachricht…',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                  : const Icon(Icons.send),
            ),
          ]),
        ),
      ]),
    );
  }
}
