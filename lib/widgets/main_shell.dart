import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/core/services/offline_sync_service.dart';
import 'package:kokomu/widgets/offline_banner.dart';
import 'package:kokomu/features/recipes/presentation/ai_recipes_screen.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  void _openAiRecipes(BuildContext context) {
    context.go('/ai-recipes');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoSyncProvider);
    final location = GoRouterState.of(context).matchedLocation;

    // Tab-Index bestimmen
    int current = 0;
    if (location.startsWith('/home')) current = 0;
    else if (location.startsWith('/inventory') || location.startsWith('/shopping')) current = 1;
    else if (location.startsWith('/kitchen') || location.startsWith('/recipes')) current = 2;
    else if (location.startsWith('/discover') || location.startsWith('/community')) current = 3;

    // FAB ausblenden wenn Tastatur offen ist
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    return Scaffold(
      body: OfflineBanner(child: child),
      floatingActionButton: keyboardOpen
          ? null
          : _AiFab(onTap: () => _openAiRecipes(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: keyboardOpen
          ? null
          : _BottomDockedBar(
        current: current,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/inventory');
              break;
            case 2:
              context.go('/kitchen');
              break;
            case 3:
              context.go('/discover');
              break;
          }
        },
      ),
    );
  }
}

/// Zentraler KI-FAB – rund, kein Schatten, dockt in BottomAppBar ein
class _AiFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AiFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        onPressed: onTap,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(
            color: theme.colorScheme.surface,
            width: 3,
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// BottomAppBar mit CircularNotchedRectangle
class _BottomDockedBar extends StatelessWidget {
  final int current;
  final void Function(int) onTap;

  const _BottomDockedBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      elevation: 8,
      padding: EdgeInsets.zero,
      height: 56,
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isActive: current == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
            label: 'Vorrat',
            isActive: current == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 60),
          _NavItem(
            icon: Icons.soup_kitchen_outlined,
            activeIcon: Icons.soup_kitchen_rounded,
            label: 'Küche',
            isActive: current == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Entdecken',
            isActive: current == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// Kompakter Mehr-Button für den AppBar – öffnet Popup mit Extras.
/// Einbinden: `actions: [const AppBarMoreButton()]`
class AppBarMoreButton extends ConsumerWidget {
  const AppBarMoreButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(ownProfileProvider).valueOrNull;
    final theme = Theme.of(context);

    // Displayname: erst Profil-Name, dann E-Mail-Prefix als Fallback
    final displayName = (profile?.displayName.isNotEmpty == true)
        ? profile!.displayName
        : (user?.email?.split('@').first ?? 'kokomu');
    final initials = displayName.substring(0, 1).toUpperCase();

    return PopupMenuButton<_MoreAction>(
      tooltip: 'Mehr',
      offset: const Offset(0, 48),
      onSelected: (action) {
        switch (action) {
          case _MoreAction.mealPlan:
            context.push('/kitchen/meal-plan');
          case _MoreAction.nutrition:
            context.push('/settings/nutrition');
          case _MoreAction.household:
            context.push('/settings/household');
          case _MoreAction.settings:
            context.push('/settings');
          case _MoreAction.paywall:
            context.push('/settings/paywall');
        }
      },
      itemBuilder: (_) => [
        // ── Header – anklickbar → Profil ──
        PopupMenuItem<_MoreAction>(
          enabled: true,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(); // Popup schließen
              context.go('/profile');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  (profile?.avatarUrl?.isNotEmpty == true)
                      ? CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(profile!.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: isPro
                              ? const Color(0xFFFFB700).withValues(alpha: 0.25)
                              : theme.colorScheme.primaryContainer,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPro
                                  ? const Color(0xFFFF6B00)
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFFFB700),
                                Color(0xFFFF6B00),
                              ]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('⭐ Pro',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        else
                          Text('Profil ansehen →',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const PopupMenuDivider(),
        // ── Planung ──
        const PopupMenuItem(
          value: _MoreAction.mealPlan,
          child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_month_outlined),
              title: Text('Wochenplaner')),
        ),
        const PopupMenuItem(
          value: _MoreAction.nutrition,
          child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.monitor_heart_outlined),
              title: Text('Ernährung & Tracking')),
        ),
        const PopupMenuDivider(),
        // ── Konto ──
        const PopupMenuItem(
          value: _MoreAction.household,
          child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.home_outlined),
              title: Text('Mein Haushalt')),
        ),
        const PopupMenuItem(
          value: _MoreAction.settings,
          child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.settings_outlined),
              title: Text('Einstellungen')),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Consumer(
          builder: (context, ref, child) {
            final household = ref.watch(householdProvider).valueOrNull;
            final pendingCount = household != null
                ? ref
                        .watch(pendingJoinRequestsProvider(household.id))
                        .valueOrNull
                        ?.length ??
                    0
                : 0;
            return Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              offset: const Offset(-2, 2),
              child: (profile?.avatarUrl?.isNotEmpty == true)
                  ? CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(profile!.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 16,
                      backgroundColor: isPro
                          ? const Color(0xFFFFB700).withValues(alpha: 0.2)
                          : theme.colorScheme.primaryContainer,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isPro
                              ? const Color(0xFFFF6B00)
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

enum _MoreAction { mealPlan, nutrition, household, settings, paywall }
