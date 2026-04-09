import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/auth/presentation/login_screen.dart';
import 'package:kokomu/features/auth/presentation/register_screen.dart';
import 'package:kokomu/features/auth/presentation/forgot_password_screen.dart';
import 'package:kokomu/features/inventory/presentation/item_detail_screen.dart';
import 'package:kokomu/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kokomu/features/recipes/presentation/manual_recipe_screen.dart';
import 'package:kokomu/features/recipes/presentation/kitchen_screen.dart';
import 'package:kokomu/features/recipes/presentation/ai_recipes_screen.dart';
import 'package:kokomu/features/scanner/presentation/scanner_screen.dart';
import 'package:kokomu/features/scanner/presentation/receipt_scanner_screen.dart';
import 'package:kokomu/features/settings/presentation/settings_screen.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';
import 'package:kokomu/features/household/presentation/household_screen.dart';
import 'package:kokomu/features/nutrition/presentation/nutrition_screen.dart';
import 'package:kokomu/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:kokomu/features/meal_plan/presentation/new_meal_plan_screen.dart';
import 'package:kokomu/features/community/presentation/discover_screen.dart';
import 'package:kokomu/features/onboarding/presentation/onboarding_screen.dart';
import 'package:kokomu/features/onboarding/presentation/welcome_after_registration_screen.dart';
import 'package:kokomu/features/dashboard/presentation/dashboard_screen.dart';
import 'package:kokomu/features/profile/presentation/profile_screen.dart';
import 'package:kokomu/features/profile/presentation/public_profile_screen.dart';
import 'package:kokomu/features/profile/presentation/edit_profile_screen.dart';
import 'package:kokomu/features/profile/presentation/followers_screen.dart';
import 'package:kokomu/features/pantry/presentation/pantry_shopping_screen.dart';
import 'package:kokomu/main.dart' show onboardingCompleteProvider;
import 'package:kokomu/models/recipe.dart' show FoodRecipe;
import 'package:kokomu/models/inventory_item.dart' show InventoryItem;
import 'package:kokomu/widgets/main_shell.dart';

/// Sicherer Cast: FoodRecipe direkt, Map → fromJson, sonst Fallback
FoodRecipe _extraToFoodRecipe(Object? extra) {
  if (extra is FoodRecipe) return extra;
  if (extra is Map<String, dynamic>) {
    try {
      return FoodRecipe.fromJson(extra);
    } catch (_) {
      return FoodRecipe(
        id: extra['id'] as String? ?? 'unknown',
        title: extra['title'] as String? ?? 'Unbekanntes Rezept',
        description: extra['description'] as String? ?? '',
        cookingTimeMinutes: extra['cookingTimeMinutes'] as int? ?? 0,
        difficulty: extra['difficulty'] as String? ?? 'Mittel',
        servings: extra['servings'] as int? ?? 2,
        ingredients: const [],
        steps: const [],
        imageUrl: extra['imageUrl'] as String? ?? extra['image_url'] as String?,
      );
    }
  }
  return const FoodRecipe(
    id: 'unknown',
    title: 'Unbekanntes Rezept',
    description: '',
    cookingTimeMinutes: 0,
    difficulty: 'Mittel',
    ingredients: [],
    steps: [],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRedirectNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';
      final isOnRegister = loc == '/register';
      final isOnForgotPassword = loc == '/forgot-password';
      final isOnWelcome = loc == '/welcome-registered';
      final isOnAuth = isOnLogin || isOnRegister || isOnForgotPassword || isOnWelcome;
      final isOnboarding = loc == '/onboarding';

      if (isOnboarding) return null;
      // Nicht eingeloggt → nur Login/Register erlaubt
      if (!isLoggedIn && !isOnAuth) return '/login';
      // Eingeloggt auf Login → Home (aber Register bleibt erreichbar für neuen Account)
      if (isLoggedIn && isOnLogin) return '/home';
      if (loc == '/') return isLoggedIn ? '/home' : '/login';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Seite nicht gefunden: ${state.uri}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => GoRouter.of(context).go('/home'),
              child: const Text('Zurück zur Startseite'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, _) => OnboardingScreen(
          onComplete: () => GoRouter.of(context).go('/login'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // Deep Link von Supabase E-Mail (Bestätigung / Passwort-Reset)
      GoRoute(
        path: '/auth/confirm',
        redirect: (context, state) {
          // Supabase verarbeitet den Token automatisch über den Deep Link.
          // Wir leiten einfach auf Home oder Login weiter.
          final user = ref.read(currentUserProvider);
          return user != null ? '/home' : '/login';
        },
      ),
      GoRoute(
        path: '/welcome-registered',
        builder: (_, state) => WelcomeAfterRegistrationScreen(
          displayName: state.extra as String?,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const DashboardScreen(),
          ),
          // ── Vorrat & Einkauf (kombinierter Tab) ──
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const PantryShoppingScreen(initialTab: 0),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, state) => ItemDetailScreen(
                  item: state.extra as InventoryItem,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/shopping',
            builder: (_, __) => const PantryShoppingScreen(initialTab: 1),
          ),
          GoRoute(
            path: '/scanner',
            builder: (_, __) => const ScannerScreen(),
            routes: [
              GoRoute(
                path: 'receipt',
                builder: (_, __) => const ReceiptScannerScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/recipes',
            redirect: (_, __) => '/kitchen',
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, state) => RecipeDetailScreen(
                  recipe: _extraToFoodRecipe(state.extra),
                ),
              ),
              GoRoute(
                path: 'create',
                builder: (_, __) => const ManualRecipeScreen(),
              ),
            ],
          ),
          // ── KI-Rezepte (via FAB erreichbar, auch direkt verlinkbar) ──
          GoRoute(
            path: '/ai-recipes',
            builder: (_, state) {
              final extra = state.extra;
              final ingredients = extra is List<String> ? extra : null;
              return AiRecipesScreen(preSelectedIngredients: ingredients);
            },
          ),
          // ── Neue Haupt-Route: Küche ──
          GoRoute(
            path: '/kitchen',
            builder: (_, __) => const KitchenScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, state) => RecipeDetailScreen(
                  recipe: _extraToFoodRecipe(state.extra),
                ),
              ),
              GoRoute(
                path: 'create',
                builder: (_, __) => const ManualRecipeScreen(),
              ),
              GoRoute(
                path: 'meal-plan',
                builder: (_, __) => const MealPlanScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => NewMealPlanScreen(),
                  ),
                ],
              ),
            ],
          ),
          // ── Neue Haupt-Route: Entdecken ──
          GoRoute(
            path: '/discover',
            builder: (_, __) => const DiscoverScreen(),
          ),
          // ── Legacy-Redirect: /community → /discover ──
          GoRoute(
            path: '/community',
            redirect: (_, __) => '/discover',
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'household',
                builder: (_, __) => const HouseholdScreen(),
              ),
              GoRoute(
                path: 'paywall',
                builder: (_, __) => const PaywallScreen(),
              ),
              GoRoute(
                path: 'nutrition',
                builder: (_, __) => const NutritionScreen(),
              ),
              GoRoute(
                path: 'meal-plan',
                redirect: (_, __) => '/kitchen/meal-plan',
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) => EditProfileScreen(),
              ),
              GoRoute(
                path: ':userId',
                builder: (_, state) => PublicProfileScreen(
                  userId: state.pathParameters['userId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'followers',
                    builder: (_, state) => FollowersScreen(
                      userId: state.pathParameters['userId']!,
                      showFollowers: true,
                    ),
                  ),
                  GoRoute(
                    path: 'following',
                    builder: (_, state) => FollowersScreen(
                      userId: state.pathParameters['userId']!,
                      showFollowers: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    initialLocation:
        ref.read(onboardingCompleteProvider) ? '/home' : '/onboarding',
  );
});

class _AuthRedirectNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthRedirectNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
