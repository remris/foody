import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kokomu/features/community/presentation/community_provider.dart';
import 'package:kokomu/features/recipes/presentation/cooking_mode_screen.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/models/recipe.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/widgets/cooking_spoon_rating.dart';
import 'package:kokomu/widgets/meal_plan_picker_sheet.dart';

class CommunityRecipeDetailScreen extends ConsumerStatefulWidget {
  final CommunityRecipe recipe;
  /// Wenn true: kein eigener Scaffold/AppBar – wird vom PageView-Wrapper geliefert
  final bool embedded;
  const CommunityRecipeDetailScreen({
    super.key,
    required this.recipe,
    this.embedded = false,
  });

  @override
  ConsumerState<CommunityRecipeDetailScreen> createState() =>
      _CommunityRecipeDetailScreenState();
}

class _CommunityRecipeDetailScreenState
    extends ConsumerState<CommunityRecipeDetailScreen> {
  late CommunityRecipe _recipe;
  final _commentController = TextEditingController();
  bool _isPostingComment = false;
  int _servings = 0;
  double _multiplier = 1.0;
  bool _imageLoadError = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _servings = _recipe.servings;
    ref.read(communityRepositoryProvider).incrementViewCount(_recipe.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updateServings(int newServings) {
    if (newServings < 1) return;
    setState(() {
      _servings = newServings;
      _multiplier = newServings / _recipe.servings;
    });
    HapticFeedback.selectionClick();
  }

  String _scaleAmount(String amount) {
    if (_multiplier == 1.0) return amount;
    final match = RegExp(r'^([\d.,/]+)\s*(.*)$').firstMatch(amount.trim());
    if (match == null) return amount;
    final numStr = match.group(1)!;
    final unit = match.group(2) ?? '';
    double? value;
    if (numStr.contains('/')) {
      final parts = numStr.split('/');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0]);
        final b = double.tryParse(parts[1]);
        if (a != null && b != null && b != 0) value = a / b;
      }
    } else {
      value = double.tryParse(numStr.replaceAll(',', '.'));
    }
    if (value == null) return amount;
    final scaled = value * _multiplier;
    final display = scaled == scaled.roundToDouble()
        ? scaled.toInt().toString()
        : scaled.toStringAsFixed(1);
    return '$display${unit.isNotEmpty ? ' $unit' : ''}'.trim();
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  Future<void> _addToMealPlan() async {
    await showMealPlanPickerSheet(context, ref, _recipe.toFoodRecipe());
  }

  Widget _overlayButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    setState(() => _recipe = _recipe.copyWith(
      isLikedByMe: !_recipe.isLikedByMe,
      likeCount: _recipe.isLikedByMe ? _recipe.likeCount - 1 : _recipe.likeCount + 1,
    ));
    await ref.read(communityFeedProvider.notifier).toggleLike(_recipe.id);
  }

  Widget _buildSaveButton(ThemeData theme, {required bool overlayStyle}) {
    final savedRecipes = ref.watch(savedRecipesProvider).valueOrNull ?? [];
    final isSaved = savedRecipes.any((r) => r.title == _recipe.title);

    Future<void> onSave() async {
      if (isSaved) return;
      final foodRecipe = _recipe.toFoodRecipe();
      await ref.read(savedRecipesProvider.notifier).saveRecipe(foodRecipe, source: 'community');
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_recipe.title} gespeichert ✅')),
        );
      }
    }

    final icon = Icon(
      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      color: overlayStyle ? Colors.white : null,
    );

    if (overlayStyle) {
      return _overlayButton(
        icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: Colors.white,
        onTap: onSave,
      );
    }
    return IconButton(icon: icon, onPressed: onSave);
  }

  Future<void> _handleUnpublish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veröffentlichung zurückziehen?'),
        content: Text(
            '"${_recipe.title}" wird aus der Community entfernt.\nDeine gespeicherte Version bleibt erhalten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Zurückziehen')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final err =
        await ref.read(publishRecipeProvider.notifier).unpublish(_recipe.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          err == null ? '✅ Aus Community entfernt' : '❌ Fehler: $err'),
    ));
    if (err == null) Navigator.pop(context);
  }

  void _shareRecipe() {
    final foodRecipe = _recipe.toFoodRecipe();
    final sb = StringBuffer();
    sb.writeln('🍽️ ${_recipe.title}');
    sb.writeln('von ${_recipe.authorName} – geteilt über kokomu');
    sb.writeln();
    sb.writeln('⏱ ${_recipe.cookingTimeMinutes} Min. · 👤 ${_recipe.servings} Portionen · ${_recipe.difficulty}');
    sb.writeln();
    sb.writeln('📋 Zutaten:');
    for (final ing in foodRecipe.ingredients) {
      sb.writeln('  • ${ing.amount} ${ing.name}');
    }
    sb.writeln();
    sb.writeln('👨‍🍳 Zubereitung:');
    for (int i = 0; i < foodRecipe.steps.length; i++) {
      sb.writeln('${i + 1}. ${foodRecipe.steps[i]}');
    }
    SharePlus.instance.share(ShareParams(text: sb.toString(), subject: _recipe.title));
  }

  Future<void> _addIngredientsToShoppingList() async {
    final foodRecipe = _recipe.toFoodRecipe();
    if (foodRecipe.ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Zutaten vorhanden.')),
      );
      return;
    }

    final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
    final inventoryNames = inventory
        .map((i) => i.ingredientName.toLowerCase())
        .toSet();

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _IngredientSelectionDialog(
        ingredients: foodRecipe.ingredients
            .map((i) => '${_scaleAmount(i.amount)} ${i.name}')
            .toList(),
        alreadyOwned: foodRecipe.ingredients
            .where((i) => inventoryNames.contains(i.name.toLowerCase()))
            .map((i) => '${_scaleAmount(i.amount)} ${i.name}')
            .toSet(),
      ),
    );

    if (selected == null || selected.isEmpty || !mounted) return;

    final notifier = ref.read(shoppingListProvider.notifier);
    for (final item in selected) {
      final parts = item.split(' ');
      final quantity = parts.length > 1 ? parts.first : null;
      final name = parts.length > 1 ? parts.skip(1).join(' ') : item;
      await notifier.addItem(name, quantity: quantity);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selected.length} Zutat(en) zur Einkaufsliste hinzugefügt ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isPostingComment = true);
    try {
      await ref.read(recipeCommentsProvider(_recipe.id).notifier).addComment(text);
      _commentController.clear();
      HapticFeedback.lightImpact();
      setState(() => _recipe = _recipe.copyWith(commentCount: _recipe.commentCount + 1));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodRecipe = _recipe.toFoodRecipe();
    final commentsAsync = ref.watch(recipeCommentsProvider(_recipe.id));
    final currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';
    final isOwner = _recipe.userId == currentUserId;

    final body = _buildBody(context, theme, foodRecipe, commentsAsync, currentUserId, isOwner);

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      body: body,
    );
  }

  Widget _buildPlaceholderHeader(ThemeData theme) {
    final str = '${_recipe.title} ${_recipe.category ?? ''} ${_recipe.tags.join(' ')}'.toLowerCase();
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
    } else if (str.contains('pasta') || str.contains('italienisch')) {
      a = const Color(0xFF43A047); b = const Color(0xFF2E7D32); icon = Icons.dinner_dining_outlined;
    } else {
      a = theme.colorScheme.primary; b = theme.colorScheme.secondary; icon = Icons.restaurant_menu_outlined;
    }
    return Container(
      height: 280, width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
          Positioned(left: -20, bottom: -30, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
          Center(child: Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, FoodRecipe foodRecipe,
      AsyncValue<List<RecipeComment>> commentsAsync, String currentUserId, bool isOwner) {
    final hasImage = _recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty && !_imageLoadError;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ─── Header: Bild ODER Gradient-Placeholder ───
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  if (hasImage)
                    Image.network(
                      _recipe.imageUrl!,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildPlaceholderHeader(theme);
                      },
                      errorBuilder: (_, __, ___) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _imageLoadError = true);
                        });
                        return _buildPlaceholderHeader(theme);
                      },
                    )
                  else
                    _buildPlaceholderHeader(theme),
                  // Icons über dem Header (Back nur wenn nicht embedded)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            if (!widget.embedded)
                              _overlayButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                            const Spacer(),
                            _overlayButton(icon: Icons.share_outlined, onTap: _shareRecipe),
                            // Eigenes Rezept: kein Like, kein Save – nur Zurückziehen
                            if (isOwner)
                              _overlayButton(
                                icon: Icons.cloud_off_outlined,
                                color: Colors.redAccent,
                                onTap: () => _handleUnpublish(context),
                              )
                            else ...[
                              _overlayButton(
                                icon: _recipe.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _recipe.isLikedByMe ? Colors.redAccent : Colors.white,
                                onTap: _toggleLike,
                              ),
                              _buildSaveButton(theme, overlayStyle: true),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ─── Content ───
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Titel groß ───
                  Text(
                    _recipe.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ─── Meta-Zeile: Rating + Stats ───
                  Row(
                    children: [
                      CookingSpoonRating(
                        rating: _recipe.avgRating,
                        ratingCount: _recipe.ratingCount,
                        size: 18,
                        compact: true,
                        showCount: true,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite_rounded, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text('${_recipe.likeCount}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.comment_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${_recipe.commentCount}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ─── Autor-Zeile (klickbar) ───
                  GestureDetector(
                    onTap: () => context.push('/profile/${_recipe.userId}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            _recipe.authorName.isNotEmpty
                                ? _recipe.authorName[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recipe.authorName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                _formatDate(_recipe.createdAt),
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
                  const SizedBox(height: 16),
                  // ─── Beschreibung ───
                  if (_recipe.description.isNotEmpty) ...[
                    Text(
                      _recipe.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ─── Info-Karten ───
                  Row(
                    children: [
                      Expanded(child: _InfoCard(
                        icon: Icons.timer_outlined,
                        label: 'Zeit',
                        value: '${_recipe.cookingTimeMinutes} Min.',
                        theme: theme,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _InfoCard(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: 'Level',
                        value: _recipe.difficulty,
                        theme: theme,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _InfoCard(
                        icon: Icons.restaurant_outlined,
                        label: 'Portionen',
                        value: '$_servings',
                        theme: theme,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ─── Portionen-Regler ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Portionen', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _servings > 1 ? () => _updateServings(_servings - 1) : null,
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            '$_servings',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _updateServings(_servings + 1),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ─── Tags ───
                  if (_recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _recipe.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$t',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const Divider(height: 32),
                  // ─── Bewertung (nur für fremde Rezepte) ───
                  if (!isOwner) ...[
                    _buildRatingSection(theme),
                    const Divider(height: 32),
                  ],
                  // ─── Zutaten ───
                  Row(
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Zutaten', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addIngredientsToShoppingList,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Einkaufen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
                      final inventoryNames = inventory.map((i) => i.ingredientName.toLowerCase()).toSet();
                      return Column(
                        children: foodRecipe.ingredients.map((ing) {
                          final inStock = inventoryNames.contains(ing.name.toLowerCase());
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(child: Text(ing.name, style: theme.textTheme.bodyMedium)),
                                Text(
                                  _scaleAmount(ing.amount),
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: inStock
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    inStock ? '✓Vorrat' : 'Fehlt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: inStock ? Colors.green.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // ─── Zubereitung ───
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Zubereitung', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...foodRecipe.steps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entry.value, style: theme.textTheme.bodyMedium),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 32),
                  // ─── Kommentare ───
                  _buildCommentsSection(theme, commentsAsync, currentUserId),
                ]),
              ),
            ),
          ],
        ),
        // ─── FABs ───
        Positioned(
          right: 16,
          bottom: widget.embedded ? 60 : 24,
          child: _buildFabs(context),
        ),
      ],
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    return Row(
      children: [
        CookingSpoonRating(
          rating: _recipe.avgRating,
          ratingCount: _recipe.ratingCount,
          myRating: _recipe.myRating,
          size: 22,
          showCount: true,
        ),
        const Spacer(),
        TextButton.icon(
          icon: Icon(
            _recipe.myRating != null
                ? Icons.soup_kitchen_rounded
                : Icons.soup_kitchen_outlined,
            size: 18,
            color: _recipe.myRating != null ? Colors.orange.shade600 : null,
          ),
          label: Text(_recipe.myRating != null ? 'Bewertung ändern' : 'Bewerten'),
          onPressed: () async {
            final stars = await showRatingDialog(
              context,
              title: _recipe.title,
              currentRating: _recipe.myRating,
            );
            if (stars != null && mounted) {
              final wasRated = _recipe.myRating != null;
              final oldStars = _recipe.myRating ?? 0;
              final newCount = wasRated ? _recipe.ratingCount : _recipe.ratingCount + 1;
              final newAvg = wasRated
                  ? ((_recipe.avgRating ?? 0) * _recipe.ratingCount - oldStars + stars) / newCount
                  : ((_recipe.avgRating ?? 0) * _recipe.ratingCount + stars) / newCount;
              setState(() => _recipe = _recipe.copyWith(
                    myRating: stars,
                    avgRating: newAvg,
                    ratingCount: newCount,
                  ));
              await ref.read(communityRepositoryProvider).rateRecipe(_recipe.id, stars);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme, AsyncValue<List<RecipeComment>> commentsAsync, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kommentare',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            commentsAsync.when(
              data: (c) => Text(
                '(${c.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Kommentar-Eingabe
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Kommentar schreiben...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isPostingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: _postComment,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
          ],
        ),
        const SizedBox(height: 16),
        // Kommentarliste
        commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Fehler: $e'),
          data: (comments) => comments.isEmpty
              ? Text(
                  'Noch keine Kommentare. Sei der Erste!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: comments
                      .map((c) => _CommentTile(
                            comment: c,
                            currentUserId: currentUserId,
                            onDelete: () => ref
                                .read(recipeCommentsProvider(_recipe.id).notifier)
                                .deleteComment(c.id),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildFabs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'mealplan',
          onPressed: _addToMealPlan,
          tooltip: 'Zum Wochenplan',
          child: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'shopping',
          onPressed: _addIngredientsToShoppingList,
          tooltip: 'Zur Einkaufsliste',
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          child: const Icon(Icons.add_shopping_cart_rounded, size: 18),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'cook',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CookingModeScreen(recipe: _recipe.toFoodRecipe()),
            ),
          ),
          tooltip: 'Jetzt kochen',
          child: const Icon(Icons.play_arrow_rounded),
        ),
      ],
    );
  }
}

// ─── Info Card Widget ───
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comment Tile Widget ───
class _CommentTile extends StatelessWidget {
  final RecipeComment comment;
  final String currentUserId;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tagen';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwn = comment.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'F',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (isOwn)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              visualDensity: VisualDensity.compact,
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Kommentar löschen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: const Text('Löschen'),
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

// ─── Ingredient Selection Dialog ───
class _IngredientSelectionDialog extends StatefulWidget {
  final List<String> ingredients;
  final Set<String> alreadyOwned;

  const _IngredientSelectionDialog({
    required this.ingredients,
    required this.alreadyOwned,
  });

  @override
  State<_IngredientSelectionDialog> createState() => _IngredientSelectionDialogState();
}

class _IngredientSelectionDialogState extends State<_IngredientSelectionDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.ingredients
        .where((i) => !widget.alreadyOwned.contains(i))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Zutaten auf Einkaufsliste'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selected.addAll(widget.ingredients)),
                  child: const Text('Alle'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Keine'),
                ),
              ],
            ),
            const Divider(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.ingredients.map((ing) {
                  final owned = widget.alreadyOwned.contains(ing);
                  return CheckboxListTile(
                    dense: true,
                    value: _selected.contains(ing),
                    onChanged: (v) => setState(() {
                      v == true ? _selected.add(ing) : _selected.remove(ing);
                    }),
                    title: Text(
                      ing,
                      style: TextStyle(
                        color: owned ? theme.colorScheme.onSurfaceVariant : null,
                        decoration: owned ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    secondary: owned
                        ? Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    subtitle: owned
                        ? Text(
                            'Im Vorrat vorhanden',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: Text('${_selected.length} hinzufügen'),
        ),
      ],
    );
  }
}
