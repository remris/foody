import 'package:flutter/material.dart';
import 'package:kokomi/features/inventory/presentation/inventory_screen.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_screen.dart';

/// Globaler Notifier für den aktiven Pantry-Tab (0=Einkauf, 1=Vorrat).
/// Wird von PantryTabBar in Shopping- und InventoryScreen gelesen/geschrieben.
final pantryTabNotifier = ValueNotifier<int>(0);

/// Kombinierter Bildschirm: Einkauf & Vorrat.
/// Nutzt IndexedStack + ValueNotifier – kein GoRouter-Rebuild, kein Lag.
class PantryShoppingScreen extends StatefulWidget {
  final int initialTab;
  const PantryShoppingScreen({super.key, this.initialTab = 0});

  @override
  State<PantryShoppingScreen> createState() => _PantryShoppingScreenState();
}

class _PantryShoppingScreenState extends State<PantryShoppingScreen> {
  @override
  void initState() {
    super.initState();
    // initialTab aus GoRouter (z.B. /shopping → 0, /inventory → 1) setzen
    pantryTabNotifier.value = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pantryTabNotifier,
      builder: (_, tab, __) => IndexedStack(
        index: tab,
        children: const [
          ShoppingListScreen(),
          InventoryScreen(),
        ],
      ),
    );
  }
}

/// Tab-Bar für Shopping/Inventory – liest und schreibt pantryTabNotifier direkt.
class PantryTabBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentTab;
  final ValueChanged<int>? onTabChanged;

  const PantryTabBar({
    super.key,
    required this.currentTab,
    this.onTabChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _PantryTabItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart_rounded,
                label: 'Einkauf',
                isActive: currentTab == 0,
                onTap: () {
                  pantryTabNotifier.value = 0;
                  onTabChanged?.call(0);
                },
              ),
              _PantryTabItem(
                icon: Icons.kitchen_outlined,
                activeIcon: Icons.kitchen_rounded,
                label: 'Vorrat',
                isActive: currentTab == 1,
                onTap: () {
                  pantryTabNotifier.value = 1;
                  onTabChanged?.call(1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PantryTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PantryTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.tabBarTheme.labelColor ??
        theme.colorScheme.primary;
    final inactiveColor = theme.tabBarTheme.unselectedLabelColor ??
        theme.colorScheme.onSurfaceVariant;
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isActive ? activeIcon : icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Indicator-Linie wie beim Standard-TabBar
            Positioned(
              left: 24, right: 24, bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isActive ? 1.0 : 0.0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


