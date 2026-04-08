import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_rating_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_notes_provider.dart';
import 'package:kokomi/features/recipes/presentation/cooking_mode_screen.dart';
import 'package:kokomi/features/recipes/presentation/recipe_favorites_provider.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/widgets/meal_plan_picker_sheet.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:kokomi/widgets/cooking_spoon_rating.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/community/presentation/publish_recipe_sheet.dart';
import 'package:kokomi/models/community_recipe.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final FoodRecipe recipe;
  /// Wenn true: kein Placeholder-Header (für KI-generierte Rezepte)
  final bool isAiRecipe;
  /// true wenn dieses Rezept aus der Community gespeichert wurde (fremdes Rezept)
  final bool isFromCommunity;
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isAiRecipe = false,
    this.isFromCommunity = false,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int _servings;
  late double _multiplier;
  bool _imageLoadError = false;
  bool _isUploadingImage = false;
  String? _localImageUrl; // nach Upload aktualisiert

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
    _multiplier = 1.0;
    _localImageUrl = widget.recipe.imageUrl;
  }

  void _updateServings(int newServings) {
    if (newServings < 1) return;
    setState(() {
      _servings = newServings;
      _multiplier = newServings / widget.recipe.servings;
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_localImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Foto entfernen', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, null),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // Entfernen gewählt
    if (source == null && _localImageUrl != null) {
      // nur wenn explizit "Foto entfernen" gedrückt → source == null aber Sheet war offen
      // Wir prüfen ob der user überhaupt etwas ausgewählt hat
      return;
    }
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final currentUserId = SupabaseService.client.auth.currentUser?.id ?? 'unknown';
      final path = 'recipe_images/$currentUserId/${widget.recipe.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await SupabaseService.client.storage
          .from('recipe-images')
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

      final url = SupabaseService.client.storage.from('recipe-images').getPublicUrl(path);

      // In saved_recipes aktualisieren: recipe_json mit neuer imageUrl mergen
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final recipe = widget.recipe;
        final updatedJson = {...recipe.toJson(), 'imageUrl': url};
        await SupabaseService.client
            .from('saved_recipes')
            .update({'recipe_json': updatedJson})
            .eq('user_id', userId)
            .eq('title', recipe.title);
      }

      ref.invalidate(savedRecipesProvider);
      setState(() {
        _localImageUrl = url;
        _imageLoadError = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto gespeichert ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _shareRecipe() {
    final recipe = widget.recipe;
    final buffer = StringBuffer('🍽️ ${recipe.title}\n\n');
    buffer.writeln(recipe.description);
    buffer.writeln('\n⏱ ${recipe.cookingTimeMinutes} Min. | 👥 $_servings Portionen\n');
    buffer.writeln('📝 Zutaten:');
    for (final ing in recipe.ingredients) {
      buffer.writeln('• ${_scaleAmount(ing.amount)} ${ing.name}');
    }
    buffer.writeln('\n👨‍🍳 Zubereitung:');
    for (var i = 0; i < recipe.steps.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.steps[i]}');
    }
    buffer.writeln('\n— gesendet mit Kokomi');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final hasImage = _localImageUrl != null && _localImageUrl!.isNotEmpty && !_imageLoadError;
    // KI-Rezepte ohne Bild: schlichter Scaffold mit AppBar, kein Gradient-Placeholder
    final showHeader = hasImage || !widget.isAiRecipe;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Wenn kein Header: normale AppBar
      appBar: showHeader
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                ..._buildHeaderActions(recipe, withBackground: false),
              ],
            ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              if (showHeader)
              // ─── Header: Bild ODER Gradient-Placeholder (nicht bei AI ohne Bild) ───
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    if (hasImage)
                      Image.network(
                        _localImageUrl!,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderHeader(theme, primaryColor);
                        },
                        errorBuilder: (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _imageLoadError = true);
                          });
                          return _buildPlaceholderHeader(theme, primaryColor);
                        },
                      )
                    else
                      _buildPlaceholderHeader(theme, primaryColor),
                    // ─── AppBar Icons Overlay ───
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              _overlayButton(
                                icon: Icons.arrow_back,
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              ..._buildHeaderActions(recipe, withBackground: true),
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
                padding: EdgeInsets.fromLTRB(16, showHeader ? 20 : 12, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Titel ───
                    Text(
                      recipe.title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    // ─── Beschreibung ───
                    if (recipe.description.isNotEmpty)
                      Text(
                        recipe.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 10),
                    // ─── Meta-Info Zeile ───
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${recipe.cookingTimeMinutes} Min', style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.bar_chart_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(recipe.difficulty, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.people_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('$_servings Portionen', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ─── Rating ───
                    Consumer(
                      builder: (context, ref, _) {
                        final ratings = ref.watch(recipeRatingProvider);
                        final myRating = ratings[recipe.id] ?? 0;
                        return Row(
                          children: [
                            CookingSpoonRating(
                              myRating: myRating > 0 ? myRating : null,
                              rating: myRating > 0 ? myRating.toDouble() : null,
                              onRate: (stars) => ref.read(recipeRatingProvider.notifier).setRating(recipe.id, stars == myRating ? 0 : stars),
                              size: 20,
                              showCount: false,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              myRating > 0 ? myRating.toStringAsFixed(1) : '–',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // ─── Portionen-Regler (ohne Hintergrund) ───
                    Row(
                      children: [
                        Text('Portionen', style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove, color: theme.colorScheme.onSurface),
                                onPressed: _servings > 1 ? () => _updateServings(_servings - 1) : null,
                                visualDensity: VisualDensity.compact,
                                iconSize: 20,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$_servings',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () => _updateServings(_servings + 1),
                                visualDensity: VisualDensity.compact,
                                iconSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ─── Nährwerte (nur wenn vorhanden, ohne Hintergrund) ───
                    if (recipe.nutrition != null && recipe.nutrition!.calories > 0) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Nährwerte pro Portion', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NutrientValue(value: '${recipe.nutrition!.calories}', unit: 'kcal', label: 'Kalorien', color: Colors.orange),
                          _NutrientValue(value: '${recipe.nutrition!.protein.toInt()}', unit: 'g', label: 'Protein', color: Colors.purple),
                          _NutrientValue(value: '${recipe.nutrition!.carbs.toInt()}', unit: 'g', label: 'Carbs', color: Colors.blue),
                          _NutrientValue(value: '${recipe.nutrition!.fat.toInt()}', unit: 'g', label: 'Fett', color: Colors.amber),
                          _NutrientValue(value: '${recipe.nutrition!.fiber.toInt()}', unit: 'g', label: 'Ballast.', color: Colors.brown),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    // ─── Zutaten ───
                    Row(
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 20, color: primaryColor),
                        const SizedBox(width: 8),
                        Text('Zutaten', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, _) {
                        final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
                        final inventoryNames = inventory.map((i) => i.ingredientName.toLowerCase()).toSet();

                        return Column(
                          children: recipe.ingredients.map((ing) {
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
                        Icon(Icons.menu_book_outlined, size: 20, color: primaryColor),
                        const SizedBox(width: 8),
                        Text('Zubereitung', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recipe.steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: primaryColor,
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
                    const SizedBox(height: 16),
                    // ─── Notizen ───
                    _RecipeNotes(recipeId: recipe.id),
                  ]),
                ),
              ),
            ],
          ),
          // ─── FABs unten rechts ───
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Wochenplan
                FloatingActionButton.small(
                  heroTag: 'fab_mealplan',
                  onPressed: () => _showAddToMealPlanDialog(context),
                  tooltip: 'Zum Wochenplan',
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                  child: const Icon(Icons.calendar_today_outlined),
                ),
                const SizedBox(height: 10),
                // Einkaufsliste
                FloatingActionButton.small(
                  heroTag: 'fab_shopping',
                  onPressed: () => _showAddToShoppingList(context),
                  tooltip: 'Zur Einkaufsliste',
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                  child: const Icon(Icons.add_shopping_cart_outlined),
                ),
                const SizedBox(height: 10),
                // Kochen (groß)
                FloatingActionButton.extended(
                  heroTag: 'fab_cook',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: recipe)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Kochen'),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader(ThemeData theme, Color primaryColor) {
    // Tags aus Titel + Beschreibung ableiten (FoodRecipe hat kein tags-Feld)
    final tagStr = '${widget.recipe.title} ${widget.recipe.description}'.toLowerCase();
    final Color colorA;
    final Color colorB;
    final IconData icon;

    if (tagStr.contains('pasta') || tagStr.contains('italienisch')) {
      colorA = const Color(0xFF43A047); colorB = const Color(0xFF1B5E20);
      icon = Icons.dinner_dining_outlined;
    } else if (tagStr.contains('frühstück') || tagStr.contains('breakfast')) {
      colorA = const Color(0xFFF9A825); colorB = const Color(0xFFFF8F00);
      icon = Icons.wb_sunny_outlined;
    } else if (tagStr.contains('dessert') || tagStr.contains('kuchen') || tagStr.contains('schokolade')) {
      colorA = const Color(0xFFE91E63); colorB = const Color(0xFF880E4F);
      icon = Icons.cake_outlined;
    } else if (tagStr.contains('suppe') || tagStr.contains('eintopf')) {
      colorA = const Color(0xFFFF7043); colorB = const Color(0xFFBF360C);
      icon = Icons.soup_kitchen_outlined;
    } else if (tagStr.contains('salat') || tagStr.contains('vegan') || tagStr.contains('vegetarisch')) {
      colorA = const Color(0xFF26A69A); colorB = const Color(0xFF00695C);
      icon = Icons.eco_outlined;
    } else {
      colorA = primaryColor; colorB = theme.colorScheme.secondary;
      icon = Icons.restaurant_menu_outlined;
    }

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
          Positioned(left: -20, bottom: -30, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(height: 12),
                Text(
                  'Kein Foto vorhanden',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tippe auf 📷 um eins hinzuzufügen',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayButton({required IconData icon, required VoidCallback onPressed, String? tooltip}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  List<Widget> _buildHeaderActions(FoodRecipe recipe, {bool withBackground = false}) {
    Widget wrapIcon(Widget icon) {
      if (!withBackground) return icon;
      return Container(
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: icon,
      );
    }

    return [
      wrapIcon(IconButton(
        icon: Icon(Icons.share_outlined, color: withBackground ? Colors.white : null),
        onPressed: _shareRecipe,
      )),
      Consumer(
        builder: (context, ref, _) {
          final favorites = ref.watch(recipeFavoritesProvider);
          final isFav = favorites.contains(recipe.id);
          return wrapIcon(IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : (withBackground ? Colors.white : null),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(recipeFavoritesProvider.notifier).toggleFavorite(recipe.id);
            },
          ));
        },
      ),
      Consumer(
        builder: (context, ref, _) {
          final savedRecipes = ref.watch(savedRecipesProvider).valueOrNull ?? [];
          final isSaved = savedRecipes.any((r) => r.title == recipe.title);
          return wrapIcon(IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: withBackground ? Colors.white : null,
            ),
            onPressed: isSaved
                ? null
                : () async {
                    await ref.read(savedRecipesProvider.notifier).saveRecipe(recipe);
                    if (context.mounted) {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${recipe.title} gespeichert ✅')),
                      );
                    }
                  },
          ));
        },
      ),
      Consumer(
        builder: (context, ref, _) {
          final published = ref.watch(myPublishedRecipesProvider).valueOrNull ?? [];
          final isShared = published.any((r) => r.title == recipe.title);
          final sharedRecipe = isShared
              ? published.firstWhere((r) => r.title == recipe.title)
              : null;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cloud-Button: Veröffentlichen / Zurückziehen
              // Nicht bei Community-Rezepten (fremde gespeicherte)
              if (!widget.isFromCommunity)
                wrapIcon(IconButton(
                  icon: Icon(
                    isShared ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                    color: isShared ? Colors.greenAccent : (withBackground ? Colors.white : null),
                  ),
                  tooltip: isShared ? 'Veröffentlichung zurückziehen' : 'In Community teilen',
                  onPressed: () => isShared
                      ? _handleUnpublish(context, sharedRecipe!.id)
                      : _handlePublish(context, recipe),
                )),
              // Dots: Bearbeiten + Foto (nur bei nicht-AI, nicht bei Community-Rezepten)
              if (!widget.isAiRecipe && !widget.isFromCommunity)
                wrapIcon(PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: withBackground ? Colors.white : null),
                  onSelected: (v) {
                    if (v == 'edit') _showEditRecipeSheet(context, recipe);
                    if (v == 'photo') _pickAndUploadImage();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Bearbeiten'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'photo',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.photo_camera_outlined),
                        title: Text('Foto bearbeiten'),
                        dense: true,
                      ),
                    ),
                  ],
                )),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _handlePublish(BuildContext context, FoodRecipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In Community teilen?'),
        content: Text(
          '"${recipe.title}" wird in der Community veröffentlicht und ist für alle sichtbar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Veröffentlichen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final user = SupabaseService.client.auth.currentUser;
    final authorName = user?.email?.split('@').first ?? 'Kokomi-User';

    final communityRecipe = CommunityRecipe.fromFoodRecipe(
      recipe,
      userId: user?.id ?? '',
      authorName: authorName,
    );

    final errorMsg =
        await ref.read(publishRecipeProvider.notifier).publish(communityRecipe);

    if (!context.mounted) return;

    if (errorMsg != null) {
      final isFreeLimit = errorMsg.contains('FREE_LIMIT_REACHED');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFreeLimit
              ? '⭐ Free-Plan: max. 3 Rezepte teilen. Upgrade auf Pro!'
              : 'Fehler: $errorMsg'),
          backgroundColor:
              isFreeLimit ? Colors.orange.shade700 : Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    ref.invalidate(myPublishedRecipesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Rezept in Community veröffentlicht!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleUnpublish(BuildContext context, String recipeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veröffentlichung zurückziehen?'),
        content: const Text(
            'Das Rezept wird aus der Community entfernt. Deine gespeicherte Version bleibt erhalten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Zurückziehen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final errorMsg = await ref
          .read(publishRecipeProvider.notifier)
          .unpublish(recipeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg == null
                ? '✅ Rezept aus Community entfernt'
                : '❌ Fehler: $errorMsg'),
          ),
        );
      }
    }
  }

  Future<void> _showEditRecipeSheet(BuildContext context, FoodRecipe recipe) async {
    final updated = await showModalBottomSheet<FoodRecipe>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditRecipeSheet(recipe: recipe),
    );
    if (updated != null && context.mounted) {
      // Gespeichertes Rezept in Supabase updaten
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client
            .from('saved_recipes')
            .update({'recipe_json': updated.toJson()})
            .eq('user_id', userId)
            .eq('title', recipe.title);
        ref.invalidate(savedRecipesProvider);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rezept aktualisiert')),
        );
        Navigator.pop(context); // Detail-Screen schließen → neu öffnen
      }
    }
  }

  void _showAddToMealPlanDialog(BuildContext context) {
    showMealPlanPickerSheet(context, ref, widget.recipe);
  }

  void _showAddToShoppingList(BuildContext context) {
    final recipe = widget.recipe;
    final inventoryItems = ref.read(inventoryProvider).valueOrNull ?? [];
    final inventoryNames = inventoryItems.map((e) => e.ingredientName.toLowerCase()).toSet();

    final preSelected = <String>{};
    for (final ing in recipe.ingredients) {
      if (!inventoryNames.contains(ing.name.toLowerCase())) {
        preSelected.add(ing.name);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddIngredientsToShoppingSheet(
        ingredients: recipe.ingredients,
        preSelected: preSelected,
        scaledAmounts: {for (final ing in recipe.ingredients) ing.name: _scaleAmount(ing.amount)},
        servings: _servings,
        originalServings: recipe.servings,
        onConfirm: (selected) {
          for (final name in selected) {
            final ing = recipe.ingredients.firstWhere((i) => i.name == name);
            ref.read(shoppingListProvider.notifier).addItem(ing.name, quantity: _scaleAmount(ing.amount));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selected.length} Zutaten auf die Einkaufsliste gesetzt')),
          );
        },
      ),
    );
  }
}

// ─── Nutrient Value ───
class _NutrientValue extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _NutrientValue({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: value, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Add Ingredients Sheet ───
class _AddIngredientsToShoppingSheet extends StatefulWidget {
  final List<RecipeIngredient> ingredients;
  final Set<String> preSelected;
  final Map<String, String> scaledAmounts;
  final int servings;
  final int originalServings;
  final ValueChanged<List<String>> onConfirm;

  const _AddIngredientsToShoppingSheet({
    required this.ingredients,
    required this.preSelected,
    required this.onConfirm,
    this.scaledAmounts = const {},
    this.servings = 2,
    this.originalServings = 2,
  });

  @override
  State<_AddIngredientsToShoppingSheet> createState() => _AddIngredientsToShoppingSheetState();
}

class _AddIngredientsToShoppingSheetState extends State<_AddIngredientsToShoppingSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.preSelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Zutaten einkaufen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selected.length == widget.ingredients.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(widget.ingredients.map((i) => i.name));
                    }
                  }),
                  child: Text(_selected.length == widget.ingredients.length ? 'Keine' : 'Alle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.ingredients.map((ing) {
                  final isSelected = _selected.contains(ing.name);
                  final displayAmount = widget.scaledAmounts[ing.name] ?? ing.amount;
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(ing.name),
                    subtitle: displayAmount.isNotEmpty ? Text(displayAmount) : null,
                    dense: true,
                    onChanged: (val) => setState(() {
                      val == true ? _selected.add(ing.name) : _selected.remove(ing.name);
                    }),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : () {
                widget.onConfirm(_selected.toList());
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('${_selected.length} Zutaten hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recipe Notes ───
class _RecipeNotes extends ConsumerStatefulWidget {
  final String recipeId;
  const _RecipeNotes({required this.recipeId});

  @override
  ConsumerState<_RecipeNotes> createState() => _RecipeNotesState();
}

class _RecipeNotesState extends ConsumerState<_RecipeNotes> {
  late final TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = ref.watch(recipeNotesProvider);
    final currentNote = notes[widget.recipeId] ?? '';

    if (!_isEditing) {
      _notesController.text = currentNote;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_alt_outlined, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Meine Notizen', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isEditing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'z.B. "Mehr Knoblauch nächstes Mal"',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Abbrechen')),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            ref.read(recipeNotesProvider.notifier).setNote(widget.recipeId, _notesController.text.trim());
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Speichern'),
                        ),
                      ],
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => setState(() => _isEditing = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: currentNote.isEmpty
                        ? Row(
                            children: [
                              Icon(Icons.add, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text('Notiz hinzufügen...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                            ],
                          )
                        : Text(currentNote, style: theme.textTheme.bodyMedium),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Edit Recipe Sheet ───────────────────────────────────────────────────────

class _EditRecipeSheet extends StatefulWidget {
  final FoodRecipe recipe;
  const _EditRecipeSheet({required this.recipe});

  @override
  State<_EditRecipeSheet> createState() => _EditRecipeSheetState();
}

class _EditRecipeSheetState extends State<_EditRecipeSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _cookTimeCtrl;
  late String _difficulty;
  late int _servings;
  late List<RecipeIngredient> _ingredients;
  late List<String> _steps;

  static const _difficulties = ['Einfach', 'Mittel', 'Schwer'];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r.title);
    _descCtrl = TextEditingController(text: r.description);
    _cookTimeCtrl = TextEditingController(text: '${r.cookingTimeMinutes}');
    _difficulty = r.difficulty;
    _servings = r.servings;
    _ingredients = List.from(r.ingredients);
    _steps = List.from(r.steps);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cookTimeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final updated = widget.recipe.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      cookingTimeMinutes: int.tryParse(_cookTimeCtrl.text) ?? widget.recipe.cookingTimeMinutes,
      difficulty: _difficulty,
      servings: _servings,
      ingredients: _ingredients,
      steps: _steps,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Rezept bearbeiten',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              children: [
                // Titel
                Text('Titel', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(hintText: 'Rezepttitel...'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                // Beschreibung
                Text('Beschreibung', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Kurze Beschreibung...'),
                ),
                const SizedBox(height: 16),
                // Kochzeit + Schwierigkeit + Portionen
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kochzeit (Min)', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cookTimeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '30'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Schwierigkeit', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: const InputDecoration(),
                            items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Portionen
                Row(
                  children: [
                    Text('Portionen', style: theme.textTheme.labelLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                    ),
                    Text('$_servings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _servings++),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Zutaten
                Row(
                  children: [
                    Text('Zutaten', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _ingredients.add(const RecipeIngredient(name: '', amount: ''))),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Hinzufügen'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._ingredients.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ing = entry.value;
                  final nameCtrl = TextEditingController(text: ing.name);
                  final amtCtrl = TextEditingController(text: ing.amount);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(hintText: 'Zutat', isDense: true),
                            onChanged: (v) => _ingredients[i] = RecipeIngredient(name: v, amount: _ingredients[i].amount),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amtCtrl,
                            decoration: const InputDecoration(hintText: 'Menge', isDense: true),
                            onChanged: (v) => _ingredients[i] = RecipeIngredient(name: _ingredients[i].name, amount: v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => setState(() => _ingredients.removeAt(i)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                // Zubereitungsschritte
                Row(
                  children: [
                    Text('Zubereitung', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _steps.add('')),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Schritt'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ctrl = TextEditingController(text: entry.value);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(hintText: 'Schritt ${i + 1}...', isDense: true),
                            onChanged: (v) => _steps[i] = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => setState(() => _steps.removeAt(i)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

