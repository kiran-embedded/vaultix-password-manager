// lib/shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';

/// Clean Google-style bottom navigation bar with filled/outlined icon states.
class VaultixBottomNav extends StatelessWidget {
  const VaultixBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavItem(
      activeIcon: Icons.shield_rounded,
      inactiveIcon: Icons.shield_outlined,
      label: 'Vault',
    ),
    _NavItem(
      activeIcon: Icons.auto_awesome_rounded,
      inactiveIcon: Icons.auto_awesome_outlined,
      label: 'Generator',
    ),
    _NavItem(
      activeIcon: Icons.settings_rounded,
      inactiveIcon: Icons.settings_outlined,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderSide = BorderSide(
      color: theme.dividerColor,
      width: 0.8,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: borderSide),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isSelected = currentIndex == i;
              return _NavButton(
                item: _items[i],
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppColors.primary;
    final inactiveColor = theme.brightness == Brightness.dark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticHelper.medium();
          onTap();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(0.0, 0.2), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutBack)),
                  ),
                  child: ScaleTransition(
                    scale: animation.drive(Tween(begin: 0.8, end: 1.0)
                        .chain(CurveTween(curve: Curves.elasticOut))),
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? item.activeIcon : item.inactiveIcon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}
