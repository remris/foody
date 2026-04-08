import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomi/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomi/features/meal_plan/presentation/new_meal_plan_screen.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/models/community_meal_plan.dart';
import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/models/user_profile.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _segment = 0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _segment = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isPro = ref.watch(isProProvider);
    final profileAsync = ref.watch(ownProfileProvider);

    final fallbackName = user?.email?.split('@').first ?? 'Kokomi';
    final profile = profileAsync.valueOrNull;
    final displayName = (profile?.displayName.isNotEmpty == true)
        ? profile!.displayName
        : fallbackName;
    final initials = displayName.substring(0, 1).toUpperCase();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            snap: false,
            forceElevated: innerBoxIsScrolled,
            title: AnimatedOpacity(
              opacity: innerBoxIsScrolled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(displayName),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Einstellungen',
                onPressed: () => context.push('/settings'),
              ),
              const AppBarMoreButton(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                bottom: false,
                child: Container(
                  color: theme.colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 58),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile/edit'),
                          child: Stack(
                            children: [
                              (profile?.avatarUrl?.isNotEmpty == true)
                                  ? CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(profile!.avatarUrl!),
                                    )
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundColor: isPro
                                          ? const Color(0xFFFFB700).withValues(alpha: 0.3)
                                          : theme.colorScheme.primaryContainer,
                                      child: Text(initials,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isPro
                                                ? const Color(0xFFFF6B00)
                                                : theme.colorScheme.onPrimaryContainer,
                                          )),
                                    ),
                              Positioned(
                                right: 0, bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.edit_rounded,
                                      size: 10, color: theme.colorScheme.onPrimary),
                                ),
                              ),
                            ],
                        ),
                      ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              if (isPro)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFFFFB700), Color(0xFFFF6B00)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('⭐ Pro',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () => context.push('/settings/paywall'),
                                  icon: const Icon(Icons.star_outline_rounded, size: 13),
                                  label: const Text('Auf Pro upgraden'),
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Profil bearbeiten',
                          onPressed: () => context.push('/profile/edit'),
                        ),
                      ],
                    ),
                    if (profile?.bio.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(profile!.bio,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    if (profile != null && !profile.socialLinks.isEmpty) ...[
                      const SizedBox(height: 6),
                      _SocialLinksRow(links: profile.socialLinks),
                    ],
                    if (profile != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatChip(label: 'Rezepte', value: profile.recipeCount),
                          const SizedBox(width: 6),
                          _StatChip(
                            label: 'Follower',
                            value: profile.followerCount,
                            onTap: () => context.push('/profile/${profile.id}/followers'),
                          ),
                          const SizedBox(width: 6),
                          _StatChip(
                            label: 'Folgt',
                            value: profile.followingCount,
                            onTap: () => context.push('/profile/${profile.id}/following'),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_outlined, size: 15),
                      SizedBox(width: 5),
                      Text('Rezepte'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 15),
                      SizedBox(width: 5),
                      Text('Pläne'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _MyRecipesSection(),
            _MyPlansSection(),
          ],
        ),
      ),
    );
  }
}


// ─── Meine veröffentlichten Rezepte ──────────────────────────────────────────

class _MyRecipesSection extends ConsumerWidget {
  const _MyRecipesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recipesAsync = ref.watch(myPublishedRecipesProvider);

    return recipesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (recipes) => recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Noch keine Rezepte geteilt',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.go('/discover'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Rezept teilen'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: recipes.length,
              itemBuilder: (ctx, i) {
                final r = recipes[i];
                final hasImage = r.imageUrl != null && r.imageUrl!.isNotEmpty;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => _MyPublishedRecipeDetail(recipe: r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        hasImage
                            ? Image.network(r.imageUrl!, height: 120,
                                width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _RecipeColorHeader(category: r.category))
                            : _RecipeColorHeader(category: r.category),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text('${r.cookingTimeMinutes} Min.', style: theme.textTheme.labelSmall),
                                  const SizedBox(width: 10),
                                  Icon(Icons.favorite_rounded, size: 12, color: Colors.redAccent),
                                  const SizedBox(width: 3),
                                  Text('${r.likeCount}', style: theme.textTheme.labelSmall),
                                  const SizedBox(width: 10),
                                  Icon(Icons.remove_red_eye_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text('${r.viewCount}', style: theme.textTheme.labelSmall),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.public_rounded, size: 11, color: Colors.green.shade700),
                                        const SizedBox(width: 3),
                                        Text('Veröffentlicht',
                                            style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Detail-Screen für eigene veröffentlichte Rezepte ────────────────────────

class _MyPublishedRecipeDetail extends ConsumerWidget {
  final CommunityRecipe recipe;
  const _MyPublishedRecipeDetail({required this.recipe});

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veröffentlichung zurückziehen?'),
        content: Text('"${recipe.title}" wird aus der Community entfernt.\nDeine gespeicherte Version bleibt erhalten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Zurückziehen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final err = await ref.read(publishRecipeProvider.notifier).unpublish(recipe.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? '✅ Aus Community entfernt' : '❌ Fehler: $err'),
    ));
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Bearbeiten öffnet den Community-Detail-Screen im "eigener"-Modus
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Als Community-User ansehen',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CommunityRecipeDetailScreen(recipe: recipe))),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_off_outlined),
            tooltip: 'Veröffentlichung zurückziehen',
            color: theme.colorScheme.error,
            onPressed: () => _unpublish(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild / Farbiger Header
            if (hasImage)
              Image.network(recipe.imageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _RecipeColorHeader(category: recipe.category, height: 180))
            else
              _RecipeColorHeader(category: recipe.category, height: 180),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats-Zeile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(icon: Icons.favorite_rounded, color: Colors.redAccent, label: '${recipe.likeCount}', sub: 'Likes'),
                        _StatItem(icon: Icons.comment_outlined, color: theme.colorScheme.primary, label: '${recipe.commentCount}', sub: 'Kommentare'),
                        _StatItem(icon: Icons.remove_red_eye_outlined, color: Colors.blueAccent, label: '${recipe.viewCount}', sub: 'Aufrufe'),
                        if (recipe.avgRating != null && recipe.avgRating! > 0)
                          _StatItem(icon: Icons.star_rounded, color: Colors.amber, label: recipe.avgRating!.toStringAsFixed(1), sub: 'Bewertung'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta
                  Wrap(
                    spacing: 8,
                    children: [
                      _Chip(Icons.timer_outlined, '${recipe.cookingTimeMinutes} Min.'),
                      _Chip(Icons.bar_chart_rounded, recipe.difficulty),
                      if (recipe.category != null) _Chip(Icons.category_outlined, recipe.category!),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Beschreibung
                  if (recipe.description.isNotEmpty) ...[
                    Text(recipe.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (recipe.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: recipe.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('#$t', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer)),
                      )).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Aktions-Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CommunityRecipeDetailScreen(recipe: recipe))),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Ansehen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _unpublish(context, ref),
                          icon: const Icon(Icons.cloud_off_outlined, size: 18),
                          label: const Text('Zurückziehen'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _StatItem({required this.icon, required this.color, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ─── Meine Wochenpläne ────────────────────────────────────────────────────────

class _MyPlansSection extends ConsumerWidget {
  const _MyPlansSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Alle eigenen Pläne inkl. Entwürfe
    final plansAsync = ref.watch(myAllMealPlansProvider);

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (plans) => plans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Noch keine Pläne erstellt',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.go('/meal-plan'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Plan erstellen'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: plans.length,
              itemBuilder: (ctx, i) {
                final p = plans[i];
                final isPublished = p.isPublished;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => _MyOwnPlanDetailScreen(plan: p),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Farbiger Header mit Kalender-Icon
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                  right: -20, top: -20,
                                  child: Container(
                                      width: 100, height: 100,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.08)))),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_month_rounded,
                                        size: 32, color: Colors.white.withValues(alpha: 0.9)),
                                    const SizedBox(height: 4),
                                    Text('Wochenplan',
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(p.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 15)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPublished
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPublished
                                              ? Icons.public_rounded
                                              : Icons.drafts_outlined,
                                          size: 10,
                                          color: isPublished
                                              ? Colors.green.shade700
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isPublished ? 'Öffentlich' : 'Entwurf',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isPublished
                                                  ? Colors.green.shade700
                                                  : theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isPublished) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.favorite_border_rounded,
                                        size: 13, color: Colors.redAccent),
                                    const SizedBox(width: 3),
                                    Text('${p.likeCount}',
                                        style: theme.textTheme.bodySmall),
                                    const SizedBox(width: 10),
                                    Icon(Icons.remove_red_eye_outlined,
                                        size: 13,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 3),
                                    Text('${p.viewCount}',
                                        style: theme.textTheme.bodySmall),
                                    if (p.avgRating != null && p.avgRating! > 0) ...[
                                      const SizedBox(width: 10),
                                      const Icon(Icons.star_rounded,
                                          size: 13, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(p.avgRating!.toStringAsFixed(1),
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ],
                                ),
                              ],
                              if (p.tags.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  children: p.tags.take(4).map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('#$t',
                                        style: TextStyle(
                                            fontSize: 10,
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
              },
            ),
    );
  }
}

// ─── Detail-Screen für eigene Pläne (MeinBereich) ────────────────────────────

class _MyOwnPlanDetailScreen extends ConsumerStatefulWidget {
  final CommunityMealPlan plan;
  const _MyOwnPlanDetailScreen({required this.plan});

  @override
  ConsumerState<_MyOwnPlanDetailScreen> createState() =>
      _MyOwnPlanDetailScreenState();
}

class _MyOwnPlanDetailScreenState
    extends ConsumerState<_MyOwnPlanDetailScreen> {
  late CommunityMealPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  Future<void> _publish() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PublishMealPlanSheet(
        entries: _plan.entries,
        planId: _plan.id,
        initialTitle: _plan.title,
        initialDescription: _plan.description,
        initialTags: _plan.tags,
      ),
    );
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _unpublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Veröffentlichung zurückziehen?'),
        content: Text(
            '"${_plan.title}" wird aus der Community entfernt.\nDein Plan bleibt als Entwurf erhalten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(c).colorScheme.error),
              child: const Text('Zurückziehen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(communityMealPlanRepositoryProvider)
        .unpublishPlan(_plan.id);
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Aus Community entfernt')));
      Navigator.pop(context);
    }
  }

  Future<void> _editPlan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewMealPlanScreen(plan: _plan),
      ),
    );
    if (result == true && mounted) {
      ref.invalidate(myAllMealPlansProvider);
      ref.invalidate(myPublishedMealPlansProvider);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = _plan.isPublished;
    final entries = _plan.entries;
    final uniqueRecipes =
        entries.map((e) => e.recipe.title).toSet().length;

    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const dayOrder = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final preview = <String, List<String>>{};
    for (final e in entries) {
      final day = dayNames[e.dayIndex.clamp(0, 6)];
      preview.putIfAbsent(day, () => []).add(e.recipe.title);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Plan bearbeiten',
            onPressed: _editPlan,
          ),
          if (isPublished)
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'In Community ansehen',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CommunityMealPlanDetailScreen(plan: _plan)),
              ),
            ),
          IconButton(
            icon: Icon(
              isPublished
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_upload_outlined,
              color: isPublished
                  ? theme.colorScheme.error
                  : Colors.green,
            ),
            tooltip: isPublished
                ? 'Veröffentlichung zurückziehen'
                : 'In Community teilen',
            onPressed: isPublished ? _unpublish : _publish,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farbiger Header
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                      right: -30, top: -30,
                      child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07)))),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 48, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(height: 6),
                        Text('Wochenplan',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
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
                  // Status-Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? Colors.green.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPublished
                                  ? Icons.public_rounded
                                  : Icons.drafts_outlined,
                              size: 13,
                              color: isPublished
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPublished ? 'Veröffentlicht' : 'Entwurf',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPublished
                                      ? Colors.green.shade700
                                      : theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    '$uniqueRecipes Rezepte · ${entries.length} Mahlzeiten',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),

                  // Stats-Box (nur bei veröffentlichten) – zeigt Reaktionen anderer User
                  if (isPublished) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reaktionen der Community',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _OwnPlanStat(
                                icon: Icons.favorite_rounded,
                                color: Colors.redAccent,
                                label: '${_plan.likeCount}',
                                sub: 'Likes',
                              ),
                              _OwnPlanStat(
                                icon: Icons.remove_red_eye_outlined,
                                color: Colors.blueAccent,
                                label: '${_plan.viewCount}',
                                sub: 'Aufrufe',
                              ),
                              if (_plan.avgRating != null &&
                                  _plan.avgRating! > 0)
                                _OwnPlanStat(
                                  icon: Icons.star_rounded,
                                  color: Colors.amber,
                                  label:
                                      _plan.avgRating!.toStringAsFixed(1),
                                  sub: 'Ø-Bewertung\n(${_plan.ratingCount}x)',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tags
                  if (_plan.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: _plan.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('#$t',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onPrimaryContainer)),
                      )).toList(),
                    ),
                  ],

                  // Wochentage-Vorschau
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('Wochenübersicht',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...dayOrder
                        .where((d) => preview.containsKey(d))
                        .map((day) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(day,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.primary)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      preview[day]!.join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],

                  // Aktions-Buttons
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _editPlan,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Plan bearbeiten'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44)),
                  ),
                  const SizedBox(height: 10),
                  if (!isPublished)
                    FilledButton.icon(
                      onPressed: _publish,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('In Community teilen'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityMealPlanDetailScreen(plan: _plan)),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Community-Ansicht öffnen'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _unpublish,
                      icon: Icon(Icons.cloud_off_outlined,
                          size: 18, color: theme.colorScheme.error),
                      label: Text('Veröffentlichung zurückziehen',
                          style:
                              TextStyle(color: theme.colorScheme.error)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.5))),
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
}

class _OwnPlanStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _OwnPlanStat(
      {required this.icon,
      required this.color,
      required this.label,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(sub,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SocialLinksRow extends StatelessWidget {
  final SocialLinks links;
  const _SocialLinksRow({required this.links});

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({Object icon, String label, String url, Color color})>[];
    if (links.instagram?.isNotEmpty == true)
      items.add((icon: FontAwesomeIcons.instagram, label: links.instagram!, url: 'https://instagram.com/${links.instagram!.replaceAll("@","")}', color: const Color(0xFFE1306C)));
    if (links.tiktok?.isNotEmpty == true)
      items.add((icon: FontAwesomeIcons.tiktok, label: links.tiktok!, url: 'https://tiktok.com/@${links.tiktok!.replaceAll("@","")}', color: const Color(0xFF010101)));
    if (links.youtube?.isNotEmpty == true)
      items.add((icon: FontAwesomeIcons.youtube, label: 'YouTube', url: links.youtube!, color: const Color(0xFFFF0000)));
    if (links.website?.isNotEmpty == true)
      items.add((icon: Icons.language_rounded, label: 'Website', url: links.website!, color: theme.colorScheme.primary));

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.map((item) {
        final iconW = item.icon is IconData
            ? Icon(item.icon as IconData, size: 14, color: item.color)
            : FaIcon(item.icon as dynamic, size: 13, color: item.color);
        return GestureDetector(
          onTap: () => _launch(item.url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: item.color.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              iconW,
              const SizedBox(width: 5),
              Text(item.label, style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;
  const _StatChip({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: onTap != null
            ? Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$value', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

/// Farbiger Gradient-Header für Rezept-Cards ohne Bild
class _RecipeColorHeader extends StatelessWidget {
  final String? category;
  final double height;
  const _RecipeColorHeader({this.category, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = (category ?? '').toLowerCase();
    final Color colorA;
    final Color colorB;
    final IconData icon;

    if (cat.contains('frühstück')) {
      colorA = const Color(0xFFF9A825); colorB = const Color(0xFFFF8F00);
      icon = Icons.wb_sunny_outlined;
    } else if (cat.contains('mittag')) {
      colorA = const Color(0xFF43A047); colorB = const Color(0xFF2E7D32);
      icon = Icons.lunch_dining_outlined;
    } else if (cat.contains('abend')) {
      colorA = const Color(0xFF1565C0); colorB = const Color(0xFF0D47A1);
      icon = Icons.dinner_dining_outlined;
    } else if (cat.contains('dessert') || cat.contains('snack')) {
      colorA = const Color(0xFFE91E63); colorB = const Color(0xFF880E4F);
      icon = Icons.cake_outlined;
    } else {
      colorA = theme.colorScheme.primary;
      colorB = theme.colorScheme.secondary;
      icon = Icons.restaurant_menu_outlined;
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}

