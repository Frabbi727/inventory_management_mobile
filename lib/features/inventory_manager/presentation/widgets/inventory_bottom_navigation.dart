import 'package:flutter/material.dart';

class InventoryBottomNavigation extends StatelessWidget {
  const InventoryBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 72,
        padding: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(
              child: _InventoryNavItem(
                label: 'Products',
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2,
                selected: selectedIndex == 0,
                onTap: () => onTabSelected(0),
              ),
            ),
            Expanded(
              child: _InventoryNavItem(
                label: 'Purchases',
                icon: Icons.local_shipping_outlined,
                selectedIcon: Icons.local_shipping,
                selected: selectedIndex == 1,
                onTap: () => onTabSelected(1),
              ),
            ),
            Expanded(
              child: _InventoryNavItem(
                label: 'Profile',
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                selected: selectedIndex == 2,
                onTap: () => onTabSelected(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryScanButton extends StatelessWidget {
  const InventoryScanButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 62,
      height: 62,
      child: FloatingActionButton(
        heroTag: 'inventory-scan-action',
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.qr_code_scanner_rounded, size: 24),
          ),
        ),
      ),
    );
  }
}

class _InventoryNavItem extends StatelessWidget {
  const _InventoryNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 6),
            Icon(selected ? selectedIcon : icon, color: baseColor, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: baseColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
