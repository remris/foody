import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/features/community/data/community_meal_plan_repository.dart';
import 'package:kokomu/features/community/data/community_recipe_repository.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/models/community_meal_plan.dart';
import 'package:kokomu/models/feed_item.dart';
import 'package:kokomu/models/recipe.dart';
import 'package:kokomu/widgets/cooking_spoon_rating.dart';

// ─── Feed Screen ──────────────────────────────────────────────────────────────

class FollowingFeedScreen extends ConsumerWidget {
  const FollowingFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(filteredFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (items) {
          if (items.isEmpty) {
            final rawAsync = ref.watch(followingFeedProvider);
            if (rawAsync.valueOrNull?.isEmpty ?? true) {
              return _EmptyFeed(theme: theme);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_off_rounded, size: 48,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Keine Beiträge für diesen Filter',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Passe den Filter über das Icon oben an.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          final recipes = items
              .where((i) => i.type == FeedItemType.recipe)
              .map((i) => i.recipe!)
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(followingFeedProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                switch (item.type) {
                  case FeedItemType.recipe:
                    final idx = recipes.indexWhere((r) => r.id == item.recipe!.id);
                    return _RecipeFeedCard(
                      recipe: item.recipe!,
                      onTap: () => Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => FeedRecipePageView(
                          recipes: recipes, initialIndex: idx))),
                    );
                  case FeedItemType.plan:
                    return _PlanFeedCard(plan: item.plan!);
                  case FeedItemType.post:
                    return PostFeedCard(post: item.post!);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_post',
        onPressed: () => _showCreatePost(context, ref),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Posten'),
      ),
    );
  }

  void _showCreatePost(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreatePostSheet(),
    );
  }
}

// ─── Filter Sheet (aufgerufen vom DashboardScreen) ───────────────────────────

class FeedFilterSheet extends ConsumerWidget {
  const FeedFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(feedFilterProvider);

    final options = [
      (FeedItemType.post, Icons.article_outlined, 'Beiträge'),
      (FeedItemType.recipe, Icons.restaurant_menu_outlined, 'Rezepte'),
      (FeedItemType.plan, Icons.calendar_month_outlined, 'Wochenpläne'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Feed-Filter', style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Wähle was du im Feed sehen möchtest.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          ...options.map((o) {
            final isSelected = filter.contains(o.$1);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (val) {
                final current = Set<FeedItemType>.from(filter);
                if (val == true) {
                  current.add(o.$1);
                } else {
                  if (current.length > 1) current.remove(o.$1);
                }
                ref.read(feedFilterProvider.notifier).state = current;
              },
              secondary: Icon(o.$2, color: theme.colorScheme.primary),
              title: Text(o.$3),
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.read(feedFilterProvider.notifier).state =
                      {FeedItemType.post, FeedItemType.recipe, FeedItemType.plan};
                },
                child: const Text('Alle auswählen'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fertig'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Post erstellen ───────────────────────────────────────────────────────────

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _textCtrl = TextEditingController();
  String? _attachedRecipeId;
  String? _attachedPlanId;
  String? _attachedRecipeTitle;
  String? _attachedPlanTitle;
  bool _posting = false;

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schreib etwas für deinen Beitrag.')),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      await ref.read(userProfileRepositoryProvider).createPost(
        text: text,
        attachedRecipeId: _attachedRecipeId,
        attachedPlanId: _attachedPlanId,
      );
      ref.invalidate(followingFeedProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Beitrag veröffentlicht!'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  void _pickRecipe() async {
    // Eigene Rezepte aus community_recipes – inkl. Entwürfe, keine fremden
    final userId = ref.read(userProfileRepositoryProvider).currentUserId ?? '';

    List<CommunityRecipe> ownCommunityRecipes = [];
    try {
      ownCommunityRecipes = await CommunityRecipeRepository().getMyAllRecipes(userId);
    } catch (_) {}

    // Fallback: saved_recipes mit source=own/ai wenn noch nichts in community_recipes
    final List<FoodRecipe> savedFallback;
    if (ownCommunityRecipes.isEmpty) {
      final all = ref.read(savedRecipesProvider).valueOrNull ?? [];
      savedFallback = all
          .where((r) => r.source == 'own' || r.source == 'ai' || r.source == 'manual')
          .toList();
    } else {
      savedFallback = [];
    }

    if (!mounted) return;
    final hasRecipes = ownCommunityRecipes.isNotEmpty || savedFallback.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
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
                child: Text('Nur deine eigenen und KI-erstellten Rezepte.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const Divider(height: 1),
              if (!hasRecipes)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.restaurant_menu_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Keine eigenen Rezepte vorhanden.',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Erstelle ein Rezept in der Küche\noder lass dir eines von der KI generieren.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      // Eigene community_recipes (mit echter UUID)
                      ...ownCommunityRecipes.map((r) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: r.imageUrl != null && r.imageUrl!.isNotEmpty
                              ? NetworkImage(r.imageUrl!) : null,
                          child: r.imageUrl == null || r.imageUrl!.isEmpty
                              ? Icon(Icons.restaurant_menu_outlined,
                                  color: theme.colorScheme.onPrimaryContainer, size: 18) : null,
                        ),
                        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${r.cookingTimeMinutes} Min. · ${r.difficulty}'
                          '${r.isPublished ? '' : ' · Entwurf'}',
                          style: theme.textTheme.labelSmall,
                        ),
                        trailing: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _attachedRecipeId = r.id;
                            _attachedRecipeTitle = r.title;
                            _attachedPlanId = null;
                            _attachedPlanTitle = null;
                          });
                        },
                      )),
                      // Fallback: gespeicherte KI/eigene Rezepte die noch nicht veröffentlicht
                      ...savedFallback.map((r) {
                        final isAi = r.source == 'ai';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAi
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              isAi ? Icons.auto_awesome_rounded : Icons.restaurant_menu_outlined,
                              color: isAi ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onPrimaryContainer,
                              size: 18,
                            ),
                          ),
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${r.cookingTimeMinutes} Min. · ${isAi ? 'KI-Rezept' : 'Eigenes Rezept'}',
                            style: theme.textTheme.labelSmall,
                          ),
                          trailing: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _attachedRecipeId = r.savedRecipeId ?? '';
                              _attachedRecipeTitle = r.title;
                              _attachedPlanId = null;
                              _attachedPlanTitle = null;
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
    // Nur eigene Pläne – getMyAllPlans filtert bereits nach user_id
    final plans = await repo.getMyAllPlans(userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        color: theme.colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text('Meinen Wochenplan anhängen',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Nur deine eigenen Wochenpläne.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const Divider(height: 1),
              if (plans.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 40, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Keine eigenen Wochenpläne vorhanden.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Erstelle einen Wochenplan unter Küche.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: plans.length,
                    itemBuilder: (ctx, i) {
                      final p = plans[i];
                      final mealCount = p.entries.length;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Icon(Icons.calendar_month_rounded,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: 18),
                        ),
                        title: Text(p.title,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$mealCount Mahlzeiten'
                          '${p.isPublished ? ' · Veröffentlicht' : ' · Entwurf'}',
                          style: theme.textTheme.labelSmall,
                        ),
                        trailing: Icon(Icons.add_circle_outline_rounded,
                            color: theme.colorScheme.secondary),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _attachedPlanId = p.id;
                            _attachedPlanTitle = p.title;
                            _attachedRecipeId = null;
                            _attachedRecipeTitle = null;
                          });
                        },
                      );
                    },
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
    final hasAttachment = _attachedRecipeId != null || _attachedPlanId != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Neuer Beitrag',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Textfeld
          TextField(
            controller: _textCtrl,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            maxLength: _maxChars,
            buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) {
              final remaining = _maxChars - currentLength;
              final isWarning = remaining <= 50;
              final isError = remaining <= 10;
              return Text(
                '$currentLength / $maxLength',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isError
                          ? Theme.of(context).colorScheme.error
                          : isWarning
                              ? Colors.orange
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isWarning ? FontWeight.bold : FontWeight.normal,
                    ),
              );
            },
            decoration: InputDecoration(
              hintText:
                  'Was möchtest du teilen?\n\nz.B. "Heute startet der Frühling – wie wäre es mit einer Fitness-Bowl? 🥗"',
              hintStyle: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 12),
          // Anhang-Vorschau
          if (hasAttachment)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachedRecipeId != null
                        ? Icons.restaurant_menu_outlined
                        : Icons.calendar_month_outlined,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedRecipeTitle ?? _attachedPlanTitle ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      _attachedRecipeId = null;
                      _attachedPlanId = null;
                      _attachedRecipeTitle = null;
                      _attachedPlanTitle = null;
                    }),
                  ),
                ],
              ),
            ),
          // Anhang-Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickRecipe,
                icon: const Icon(Icons.restaurant_menu_outlined, size: 16),
                label: const Text('Rezept'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickPlan,
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Wochenplan'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (_posting || _textCtrl.text.length > _maxChars)
                    ? null
                    : _post,
                child: _posting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Posten'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Post-Card ────────────────────────────────────────────────────────────────

class PostFeedCard extends ConsumerStatefulWidget {
  final SocialPost post;
  const PostFeedCard({super.key, required this.post});

  @override
  ConsumerState<PostFeedCard> createState() => _PostFeedCardState();
}

class _PostFeedCardState extends ConsumerState<PostFeedCard> {
  late SocialPost _post;
  bool _expanded = false;

  // Ab dieser Zeilenzahl wird der Text kollabiert
  static const int _collapseAfterLines = 3;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  Future<void> _toggleLike() async {
    try {
      final updated = await ref
          .read(userProfileRepositoryProvider)
          .togglePostLike(_post);
      setState(() => _post = updated);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.read(userProfileRepositoryProvider);
    final isOwn = repo.currentUserId == _post.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author-Header ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile/${_post.userId}'),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: _post.avatarUrl != null
                        ? NetworkImage(_post.avatarUrl!) : null,
                    child: _post.avatarUrl == null
                        ? Text(
                            _post.authorName.isNotEmpty
                                ? _post.authorName[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${_post.userId}'),
                        child: Text(_post.authorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline)),
                      ),
                      Text(_fmt(_post.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (isOwn)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await ref
                            .read(userProfileRepositoryProvider)
                            .deletePost(_post.id);
                        ref.invalidate(followingFeedProvider);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          title: Text('Löschen',
                              style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Post-Text mit "mehr anzeigen" ──
            _CollapsibleText(
              text: _post.text,
              maxLines: _collapseAfterLines,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),

            // ── Attachment ──
            if (_post.attachedRecipe != null) ...[
              const SizedBox(height: 10),
              _RecipeAttachment(recipe: _post.attachedRecipe!),
            ],
            if (_post.attachedPlan != null) ...[
              const SizedBox(height: 10),
              _PlanAttachment(plan: _post.attachedPlan!),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Like + Kommentar ──
            Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _post.isLikedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: _post.isLikedByMe
                              ? Colors.redAccent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('${_post.likeCount}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        PostCommentsScreen(post: _post))),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${_post.commentCount}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attachment-Vorschau: Rezept ──────────────────────────────────────────────

class _RecipeAttachment extends StatelessWidget {
  final CommunityRecipe recipe;
  const _RecipeAttachment({required this.recipe});

  Color get _placeholderA {
    final s = '${recipe.title} ${recipe.category ?? ''}'.toLowerCase();
    if (s.contains('frühstück') || s.contains('breakfast')) return const Color(0xFFF9A825);
    if (s.contains('dessert') || s.contains('kuchen')) return const Color(0xFFE91E63);
    if (s.contains('salat') || s.contains('vegan')) return const Color(0xFF26A69A);
    if (s.contains('suppe')) return const Color(0xFFFF7043);
    if (s.contains('pasta') || s.contains('italienisch')) return const Color(0xFF43A047);
    return const Color(0xFF3960A0);
  }

  Color get _placeholderB {
    final s = '${recipe.title} ${recipe.category ?? ''}'.toLowerCase();
    if (s.contains('frühstück') || s.contains('breakfast')) return const Color(0xFFFF8F00);
    if (s.contains('dessert') || s.contains('kuchen')) return const Color(0xFF880E4F);
    if (s.contains('salat') || s.contains('vegan')) return const Color(0xFF00695C);
    if (s.contains('suppe')) return const Color(0xFFBF360C);
    if (s.contains('pasta') || s.contains('italienisch')) return const Color(0xFF2E7D32);
    return const Color(0xFF5E8FAF);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              CommunityRecipeDetailScreen(recipe: recipe))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bild / Gradient-Placeholder ──
            Stack(
              children: [
                if (hasImage)
                  Image.network(
                    recipe.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildGradient(),
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Container(
                            height: 160,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                  )
                else
                  _buildGradient(),
                // Badge oben links
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.restaurant_menu_rounded, size: 11, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Rezept', style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                // Schwierigkeit oben rechts
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(recipe.difficulty,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            // ── Info-Bereich ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.timer_outlined, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 3),
                    Text('${recipe.cookingTimeMinutes} Min.',
                        style: theme.textTheme.labelSmall),
                    if (recipe.category != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.restaurant_outlined, size: 13,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(recipe.category!, style: theme.textTheme.labelSmall),
                    ],
                    const Spacer(),
                    if (recipe.avgRating != null && recipe.ratingCount > 0) ...[
                      Icon(Icons.soup_kitchen_rounded,
                          size: 13, color: Colors.orange.shade600),
                      const SizedBox(width: 2),
                      Text(recipe.avgRating!.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ]),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: recipe.tags.take(3).map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('#$t',
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Spacer(),
                    Text('Zum Rezept',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 13,
                        color: theme.colorScheme.primary),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradient() => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_placeholderA, _placeholderB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07)))),
          Center(child: Icon(Icons.restaurant_menu_rounded,
              size: 44, color: Colors.white.withValues(alpha: 0.8))),
        ]),
      );
}

// ─── Attachment-Vorschau: Wochenplan ─────────────────────────────────────────

class _PlanAttachment extends StatelessWidget {
  final CommunityMealPlan plan;
  const _PlanAttachment({required this.plan});

  static const _dayOrder = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  List<Color> get _gradientColors {
    final s = '${plan.title} ${plan.tags.join(' ')}'.toLowerCase();
    if (s.contains('mediterran') || s.contains('mittelmeer'))
      return [const Color(0xFF1E88E5), const Color(0xFF0D47A1)];
    if (s.contains('vegan') || s.contains('vegetarisch'))
      return [const Color(0xFF26A69A), const Color(0xFF00695C)];
    if (s.contains('asiatisch') || s.contains('thai'))
      return [const Color(0xFFFF8F00), const Color(0xFFE65100)];
    if (s.contains('fitness') || s.contains('protein'))
      return [const Color(0xFF7B1FA2), const Color(0xFF4A148C)];
    if (s.contains('herbst') || s.contains('winter'))
      return [const Color(0xFFBF360C), const Color(0xFF7F0000)];
    if (s.contains('sommer') || s.contains('leicht'))
      return [const Color(0xFFFF7043), const Color(0xFFE64A19)];
    return [const Color(0xFF3960A0), const Color(0xFF1A237E)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = plan.weekPreview;
    final mealCount = plan.entries.length;
    final colors = _gradientColors;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              CommunityMealPlanDetailScreen(plan: plan))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient-Header ──
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Stack(children: [
                // Deko-Kreis
                Positioned(right: -20, bottom: -20,
                    child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07)))),
                // Badge oben links
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_month_outlined, size: 11, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Wochenplan', style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                // Like-Count oben rechts
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.favorite_border_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${plan.likeCount}', style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                // Titel zentriert
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      plan.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black26)]),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Tagesvorschau + Meta ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tagesvorschau
                  if (preview.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: _dayOrder
                            .where((d) => preview.containsKey(d))
                            .take(4)
                            .map((day) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Row(children: [
                            SizedBox(width: 22,
                              child: Text(day,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colors[0]))),
                            Expanded(
                              child: Text(
                                preview[day]!.join(', '),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Meta-Zeile
                  Row(children: [
                    Icon(Icons.restaurant_menu_outlined, size: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text('$mealCount Mahlzeiten',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (plan.tags.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.tags.take(2).map((t) => '#$t').join(' '),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Text('Zum Plan',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 13,
                        color: theme.colorScheme.primary),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kommentar-Screen ────────────────────────────────────────────────────────

class PostCommentsScreen extends ConsumerStatefulWidget {
  final SocialPost post;
  const PostCommentsScreen({super.key, required this.post});

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(userProfileRepositoryProvider)
          .addPostComment(widget.post.id, text);
      _ctrl.clear();
      ref.invalidate(postCommentsProvider(widget.post.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kommentare'),
      ),
      body: Column(
        children: [
          // ── Post-Preview ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : 'F',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.authorName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.post.text,
                          style: theme.textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Kommentar-Liste ──
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Noch keine Kommentare',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text('Sei der Erste!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final c = comments[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Text(
                            c.authorName.isNotEmpty
                                ? c.authorName[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c.authorName,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(_fmt(c.createdAt),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(c.text, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // ── Eingabe ──
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12, right: 12, top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Kommentar schreiben…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PageView für Rezepte ─────────────────────────────────────────────────────

class FeedRecipePageView extends StatefulWidget {
  final List<CommunityRecipe> recipes;
  final int initialIndex;
  const FeedRecipePageView(
      {super.key, required this.recipes, required this.initialIndex});

  @override
  State<FeedRecipePageView> createState() => _FeedRecipePageViewState();
}

class _FeedRecipePageViewState extends State<FeedRecipePageView> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.recipes.length;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: total + 1,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) {
              if (i == total) {
                return _EndPage(onDiscover: () => context.go('/discover'));
              }
              return CommunityRecipeDetailScreen(
                recipe: widget.recipes[i],
                embedded: true,
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          if (_currentIndex < total)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text('${_currentIndex + 1} / $total',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                  ),
                ),
              ),
            ),
          if (total > 1 && total <= 10 && _currentIndex < total)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Rezept-Karte ─────────────────────────────────────────────────────────────

class _RecipeFeedCard extends ConsumerStatefulWidget {
  final CommunityRecipe recipe;
  final VoidCallback? onTap;
  const _RecipeFeedCard({required this.recipe, this.onTap});

  @override
  ConsumerState<_RecipeFeedCard> createState() => _RecipeFeedCardState();
}

class _RecipeFeedCardState extends ConsumerState<_RecipeFeedCard> {
  late CommunityRecipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty;
    final saved = ref.watch(savedRecipesProvider).valueOrNull ?? [];
    final isSaved = saved.any((r) => r.title == _recipe.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (hasImage)
                  Image.network(
                    _recipe.imageUrl!,
                    height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                    loadingBuilder: (_, child, p) => p == null ? child : Container(
                      height: 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                else
                  _buildPlaceholder(theme),
                Positioned(
                  top: 8, right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _overlayButton(
                        icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        iconColor: isSaved ? Colors.amber : Colors.white,
                        onTap: isSaved ? null : () async {
                          await ref.read(savedRecipesProvider.notifier)
                              .saveRecipe(_recipe.toFoodRecipe());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${_recipe.title} gespeichert ✅'),
                                  duration: const Duration(seconds: 2)),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      _overlayButton(
                        icon: _recipe.isLikedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: _recipe.isLikedByMe ? Colors.redAccent : Colors.white,
                        label: '${_recipe.likeCount}',
                        onTap: () => setState(() => _recipe = _recipe.copyWith(
                          isLikedByMe: !_recipe.isLikedByMe,
                          likeCount: _recipe.isLikedByMe
                              ? _recipe.likeCount - 1
                              : _recipe.likeCount + 1,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_recipe.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold))),
                      _RatingBadge(rating: _recipe.avgRating,
                          count: _recipe.ratingCount),
                      const SizedBox(width: 6),
                      _DifficultyChip(difficulty: _recipe.difficulty),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.push('/profile/${_recipe.userId}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            _recipe.authorName.isNotEmpty
                                ? _recipe.authorName[0].toUpperCase()
                                : 'F',
                            style: TextStyle(fontSize: 10,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_recipe.authorName,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                  if (_recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_recipe.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${_recipe.cookingTimeMinutes} Min.',
                          style: theme.textTheme.bodySmall),
                      if (_recipe.category != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.restaurant_outlined, size: 14,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(_recipe.category!, style: theme.textTheme.bodySmall),
                      ],
                      const Spacer(),
                      Icon(Icons.comment_outlined, size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('${_recipe.commentCount}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Icon(
                        _recipe.isLikedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 14,
                        color: _recipe.isLikedByMe
                            ? Colors.redAccent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text('${_recipe.likeCount}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (_recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _recipe.tags.take(4).map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$t',
                            style: TextStyle(fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    final str = '${_recipe.title} ${_recipe.category ?? ''}'.toLowerCase();
    final Color a, b;
    final IconData icon;
    if (str.contains('frühstück') || str.contains('breakfast')) {
      a = const Color(0xFFF9A825); b = const Color(0xFFFF8F00);
      icon = Icons.wb_sunny_outlined;
    } else if (str.contains('dessert') || str.contains('kuchen')) {
      a = const Color(0xFFE91E63); b = const Color(0xFF880E4F);
      icon = Icons.cake_outlined;
    } else if (str.contains('salat') || str.contains('vegan')) {
      a = const Color(0xFF26A69A); b = const Color(0xFF00695C);
      icon = Icons.eco_outlined;
    } else {
      a = theme.colorScheme.primary; b = theme.colorScheme.secondary;
      icon = Icons.restaurant_menu_outlined;
    }
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(icon, size: 42,
          color: Colors.white.withValues(alpha: 0.8))),
    );
  }

  Widget _overlayButton({required IconData icon, Color? iconColor,
      String? label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor ?? Colors.white),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Wochenplan-Karte ─────────────────────────────────────────────────────────

class _PlanFeedCard extends StatelessWidget {
  final CommunityMealPlan plan;
  const _PlanFeedCard({required this.plan});

  static const _dayOrder = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealCount = plan.entries.length;
    final preview = plan.weekPreview;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
                CommunityMealPlanDetailScreen(plan: plan))),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildPlanHeader(theme),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.favorite_border_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${plan.likeCount}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Wochenplan',
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(plan.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold))),
                    if (plan.avgRating != null && plan.ratingCount > 0)
                      _RatingBadge(rating: plan.avgRating, count: plan.ratingCount),
                  ]),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.push('/profile/${plan.userId}'),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          plan.authorName.isNotEmpty
                              ? plan.authorName[0].toUpperCase()
                              : 'F',
                          style: TextStyle(fontSize: 10,
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(plan.authorName,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              decoration: TextDecoration.underline)),
                    ]),
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(plan.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: _dayOrder
                            .where((d) => preview.containsKey(d))
                            .take(4)
                            .map((day) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Row(children: [
                            SizedBox(width: 22,
                              child: Text(day,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 10)),
                            ),
                            Expanded(
                              child: Text(
                                preview[day]!.join(', '),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.restaurant_menu_outlined, size: 14,
                        color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text('$mealCount Mahlzeiten',
                        style: theme.textTheme.labelSmall),
                    const Spacer(),
                    Icon(Icons.favorite_border_rounded, size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text('${plan.likeCount}', style: theme.textTheme.labelSmall),
                    const SizedBox(width: 8),
                    Text(_fmt(plan.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                  if (plan.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 4, children: plan.tags.take(4).map((t) =>
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('#$t', style: TextStyle(fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant)),
                        )).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(ThemeData theme) {
    final str = '${plan.title} ${plan.tags.join(' ')}'.toLowerCase();
    final Color a, b;
    if (str.contains('mediterran')) {
      a = const Color(0xFF1E88E5); b = const Color(0xFF0D47A1);
    } else if (str.contains('vegan') || str.contains('vegetarisch')) {
      a = const Color(0xFF26A69A); b = const Color(0xFF00695C);
    } else if (str.contains('fitness') || str.contains('protein')) {
      a = const Color(0xFF7B1FA2); b = const Color(0xFF4A148C);
    } else {
      a = theme.colorScheme.secondary; b = theme.colorScheme.primary;
    }
    return Container(
      height: 110, width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(Icons.calendar_month_rounded, size: 40,
          color: Colors.white.withValues(alpha: 0.8))),
    );
  }
}

// ─── Kollabierbarerer Text (LinkedIn-Stil) ────────────────────────────────────

class _CollapsibleText extends StatelessWidget {
  final String text;
  final int maxLines;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleText({
    required this.text,
    required this.maxLines,
    required this.expanded,
    required this.onToggle,
  });

  /// Prüft per TextPainter ob der Text tatsächlich mehr als [maxLines] Zeilen
  /// füllt – nur dann wird der "mehr anzeigen" Button gezeigt.
  bool _needsCollapse(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 60);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsCollapse = _needsCollapse(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: expanded || !needsCollapse
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            style: theme.textTheme.bodyMedium,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (needsCollapse) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Weniger anzeigen' : '... mehr anzeigen',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final ThemeData theme;
  const _EmptyFeed({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Noch niemanden gefolgt',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Entdecke Köche und folge ihnen –\nihre Beiträge, Rezepte und Pläne erscheinen hier.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Köche entdecken'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndPage extends StatelessWidget {
  final VoidCallback onDiscover;
  const _EndPage({required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Du hast alles gesehen!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Folge mehr Köchen um deinen Feed zu füllen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onDiscover,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Köche entdecken'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Zurück zum Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double? rating;
  final int count;
  const _RatingBadge({this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    if (rating == null || count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.soup_kitchen_rounded,
            size: 13, color: Colors.orange.shade600),
        const SizedBox(width: 2),
        Text(rating!.toStringAsFixed(1),
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(' ($count)',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (difficulty.toLowerCase()) {
      'einfach' => Colors.green,
      'mittel'  => Colors.orange,
      'schwer'  => Colors.red,
      _         => theme.colorScheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(difficulty,
          style: TextStyle(fontSize: 10, color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

