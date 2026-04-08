import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/features/profile/presentation/profile_recipe_page_view.dart';
import 'package:kokomi/features/profile/presentation/followers_screen.dart';
import 'package:kokomi/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/user_profile.dart';
import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/features/profile/presentation/following_feed_screen.dart' show PostFeedCard;

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  int _segment = 0; // 0 = Rezepte, 1 = Wochenpläne, 2 = Posts

  @override
  void initState() {
    super.initState();
    // Follow-State initialisieren sobald Profil geladen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile =
          ref.read(userProfileProvider(widget.userId)).valueOrNull;
      if (profile != null) {
        ref
            .read(followProvider(widget.userId).notifier)
            .setInitial(profile.isFollowedByMe);
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(
        url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _instagramUrl(String handle) {
    final h = handle.startsWith('@') ? handle.substring(1) : handle;
    return 'https://instagram.com/$h';
  }

  String _tiktokUrl(String handle) {
    final h = handle.startsWith('@') ? handle.substring(1) : handle;
    return 'https://tiktok.com/@$h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final isFollowing = ref.watch(followProvider(widget.userId));
    final currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (profile) {
          return CustomScrollView(
            slivers: [
              // ── AppBar mit Avatar ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _AvatarWidget(profile: profile, radius: 40),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.displayName.isNotEmpty
                                      ? profile.displayName
                                      : 'Kokomi-User',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile.bio.isNotEmpty)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width - 130,
                                    child: Text(
                                      profile.bio,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                actions: [
                  if (!isOwnProfile)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.tonal(
                        onPressed: () => ref
                            .read(followProvider(widget.userId).notifier)
                            .toggle(widget.userId),
                        style: FilledButton.styleFrom(
                          backgroundColor: isFollowing
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.primary,
                          foregroundColor: isFollowing
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isFollowing ? 'Gefolgt ✓' : 'Folgen',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Statistiken ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _StatBox(
                          label: 'Rezepte', value: profile.recipeCount),
                      const SizedBox(width: 1),
                      _StatBox(
                          label: 'Follower',
                          value: profile.followerCount,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersScreen(
                                  userId: widget.userId, showFollowers: true),
                            ),
                          )),
                      const SizedBox(width: 1),
                      _StatBox(
                          label: 'Folgt',
                          value: profile.followingCount,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersScreen(
                                  userId: widget.userId, showFollowers: false),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // ── Social Media Links ────────────────────────────────────
              if (!profile.socialLinks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _SocialLinksRow(
                      links: profile.socialLinks,
                      onLaunch: _launchUrl,
                      instagramUrl: _instagramUrl,
                      tiktokUrl: _tiktokUrl,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Divider(),
                ),
              ),

              // ── Tab-Auswahl ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                          value: 0,
                          label: Text('Rezepte'),
                          icon: Icon(Icons.restaurant_outlined, size: 15)),
                      ButtonSegment(
                          value: 1,
                          label: Text('Pläne'),
                          icon: Icon(Icons.calendar_month_outlined, size: 15)),
                      ButtonSegment(
                          value: 2,
                          label: Text('Posts'),
                          icon: Icon(Icons.article_outlined, size: 15)),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (s) =>
                        setState(() => _segment = s.first),
                  ),
                ),
              ),

              // ── Rezepte ───────────────────────────────────────────────
              if (_segment == 0)
                ref.watch(userPublicRecipesProvider(widget.userId)).when(
                  loading: () => const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) =>
                      SliverToBoxAdapter(child: Center(child: Text('$e'))),
                  data: (recipes) {
                    if (recipes.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: Icons.restaurant_menu_outlined,
                          text: 'Noch keine Rezepte geteilt',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final r = recipes[i];
                            final hasImage = r.imageUrl != null && r.imageUrl!.isNotEmpty;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                                  builder: (_) => ProfileRecipePageView(recipes: recipes, initialIndex: i),
                                )),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ─── Bild oder Gradient-Placeholder ───
                                    Stack(
                                      children: [
                                        if (hasImage)
                                          Image.network(r.imageUrl!,
                                            height: 140, width: double.infinity, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildRecipePlaceholder(theme, r),
                                            loadingBuilder: (_, child, p) => p == null ? child : Container(
                                              height: 140, color: theme.colorScheme.surfaceContainerHighest,
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2))))
                                        else
                                          _buildRecipePlaceholder(theme, r),
                                        // Like + Rating Overlay
                                        Positioned(top: 8, right: 8, child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            Icon(r.avgRating != null && r.avgRating! > 0
                                              ? Icons.soup_kitchen_rounded : Icons.soup_kitchen_outlined,
                                              size: 12, color: Colors.orange.shade300),
                                            const SizedBox(width: 4),
                                            Text(
                                              r.avgRating != null && r.ratingCount > 0
                                                ? '${r.avgRating!.toStringAsFixed(1)} (${r.ratingCount})'
                                                : '(0)',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ]),
                                        )),
                                      ],
                                    ),
                                    // ─── Info ───
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(child: Text(r.title,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(8)),
                                              child: Text(r.difficulty,
                                                style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                                            ),
                                          ]),
                                          if (r.description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text('${r.cookingTimeMinutes} Min.', style: theme.textTheme.bodySmall),
                                            const Spacer(),
                                            Icon(Icons.favorite_border_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text('${r.likeCount}', style: theme.textTheme.bodySmall),
                                            const SizedBox(width: 8),
                                            Icon(Icons.comment_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text('${r.commentCount}', style: theme.textTheme.bodySmall),
                                          ]),
                                          if (r.tags.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Wrap(spacing: 4, children: r.tags.take(3).map((t) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(8)),
                                              child: Text('#$t', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                            )).toList()),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: recipes.length,
                        ),
                      ),
                    );
                  },
                ),

              // ── Wochenpläne ───────────────────────────────────────────
              if (_segment == 1)
                ref.watch(userPublicMealPlansProvider(widget.userId)).when(
                  loading: () => const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) =>
                      SliverToBoxAdapter(child: Center(child: Text('$e'))),
                  data: (plans) {
                    if (plans.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: Icons.calendar_month_outlined,
                          text: 'Noch keine Wochenpläne geteilt',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final p = plans[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.calendar_month_rounded,
                                      size: 20,
                                      color: theme.colorScheme.onSecondaryContainer),
                                ),
                                title: Text(p.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: p.tags.isNotEmpty
                                    ? Text(p.tags.take(3).join(' · '),
                                        style: theme.textTheme.bodySmall)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.favorite_border_rounded,
                                        size: 14,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text('${p.likeCount}',
                                        style: theme.textTheme.bodySmall),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CommunityMealPlanDetailScreen(plan: p),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: plans.length,
                        ),
                      ),
                    );
                  },
                ),

              // ── Posts ─────────────────────────────────────────────────
              if (_segment == 2)
                ref.watch(userPublicPostsProvider(widget.userId)).when(
                  loading: () => const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) =>
                      SliverToBoxAdapter(child: Center(child: Text('$e'))),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: Icons.article_outlined,
                          text: 'Noch keine Posts',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => PostFeedCard(post: posts[i]),
                          childCount: posts.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final UserProfile profile;
  final double radius;
  const _AvatarWidget({required this.profile, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profile.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        profile.initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;
  const _StatBox({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: box)
          : box,
    );
  }
}

Widget _buildRecipePlaceholder(ThemeData theme, CommunityRecipe r) {
  final str = '${r.title} ${r.category ?? ''} ${r.tags.join(' ')}'.toLowerCase();
  final Color a, b;
  final IconData icon;
  if (str.contains('frühstück') || str.contains('breakfast')) {
    a = const Color(0xFFF9A825); b = const Color(0xFFFF8F00); icon = Icons.wb_sunny_outlined;
  } else if (str.contains('dessert') || str.contains('kuchen') || str.contains('tiramisu')) {
    a = const Color(0xFFE91E63); b = const Color(0xFF880E4F); icon = Icons.cake_outlined;
  } else if (str.contains('salat') || str.contains('vegan') || str.contains('vegetarisch')) {
    a = const Color(0xFF26A69A); b = const Color(0xFF00695C); icon = Icons.eco_outlined;
  } else if (str.contains('suppe') || str.contains('eintopf')) {
    a = const Color(0xFFFF7043); b = const Color(0xFFBF360C); icon = Icons.soup_kitchen_outlined;
  } else if (str.contains('pasta') || str.contains('spaghetti') || str.contains('italienisch')) {
    a = const Color(0xFF43A047); b = const Color(0xFF2E7D32); icon = Icons.dinner_dining_outlined;
  } else {
    a = theme.colorScheme.primary; b = theme.colorScheme.secondary; icon = Icons.restaurant_menu_outlined;
  }
  return Container(
    height: 140, width: double.infinity,
    decoration: BoxDecoration(gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Stack(children: [
      Positioned(right: -20, top: -20, child: Container(width: 90, height: 90,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
      Center(child: Icon(icon, size: 38, color: Colors.white.withValues(alpha: 0.8))),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SocialItem {
  final Object icon; // IconData oder FaIconData
  final String label;
  final String url;
  final Color color;
  const _SocialItem({required this.icon, required this.label, required this.url, required this.color});
}

class _SocialLinksRow extends StatelessWidget {
  final SocialLinks links;
  final Future<void> Function(String) onLaunch;
  final String Function(String) instagramUrl;
  final String Function(String) tiktokUrl;

  const _SocialLinksRow({
    required this.links,
    required this.onLaunch,
    required this.instagramUrl,
    required this.tiktokUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_SocialItem>[
      if (links.instagram != null && links.instagram!.isNotEmpty)
        _SocialItem(
          icon: FontAwesomeIcons.instagram,
          label: links.instagram!.startsWith('@') ? links.instagram! : '@${links.instagram!}',
          url: instagramUrl(links.instagram!),
          color: const Color(0xFFE1306C),
        ),
      if (links.tiktok != null && links.tiktok!.isNotEmpty)
        _SocialItem(
          icon: FontAwesomeIcons.tiktok,
          label: links.tiktok!.startsWith('@') ? links.tiktok! : '@${links.tiktok!}',
          url: tiktokUrl(links.tiktok!),
          color: const Color(0xFF010101),
        ),
      if (links.youtube != null && links.youtube!.isNotEmpty)
        _SocialItem(
          icon: FontAwesomeIcons.youtube,
          label: 'YouTube',
          url: links.youtube!,
          color: const Color(0xFFFF0000),
        ),
      if (links.website != null && links.website!.isNotEmpty)
        _SocialItem(
          icon: Icons.language_rounded,
          label: 'Website',
          url: links.website!,
          color: theme.colorScheme.primary,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final iconWidget = item.icon is IconData
            ? Icon(item.icon as IconData, size: 16, color: item.color)
            : FaIcon(item.icon as dynamic, size: 15, color: item.color);

        return GestureDetector(
          onTap: () => onLaunch(item.url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 7),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
