import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class RootShellPage extends StatelessWidget {
  const RootShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Home (index 0)
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                isSelected: currentIndex == 0,
                onTap: () => _onDestinationSelected(0),
              ),
              
              // 2. + Add Drink (index 1)
              _NavItem(
                icon: Icons.add,
                selectedIcon: Icons.add,
                isSelected: currentIndex == 1,
                onTap: () => _onDestinationSelected(1),
              ),
              
              // 3. Center FAB - Drink icon 🍺 (index 1)
              GestureDetector(
                onTap: () => _onDestinationSelected(1),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_bar,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              
              // 4. Leaderboard (index 2)
              _NavItem(
                icon: Icons.emoji_events_outlined,
                selectedIcon: Icons.emoji_events,
                isSelected: currentIndex == 2,
                onTap: () => _onDestinationSelected(2),
              ),
              
              // 5. Profile (index 3)
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                isSelected: currentIndex == 3,
                onTap: () => _onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade400,
          size: 26,
        ),
      ),
    );
  }
}
