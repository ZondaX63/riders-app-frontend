import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreate;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bar background
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.darkTheme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _NavItem(
                  icon: Icons.explore,
                  label: 'Explore',
                  selected: currentIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                const SizedBox(width: 64), // space for FAB
                _NavItem(
                  icon: Icons.chat_bubble,
                  label: 'Chat',
                  selected: currentIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  selected: currentIndex == 4,
                  onTap: () => onTabSelected(4),
                ),
              ],
            ),
          ),
          // Center create button
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: onCreate,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryOrange.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.add, color: Colors.black, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.grey;
    final weight = selected ? FontWeight.bold : FontWeight.w500;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: weight, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
