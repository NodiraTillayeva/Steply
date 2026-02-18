import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:steply/core/constants/app_constants.dart';

class ShellPage extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final ValueChanged<int> onTabChanged;

  const ShellPage({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  static const _items = [
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    _NavItem(icon: Icons.route_outlined, activeIcon: Icons.route, label: 'Journey'),
    _NavItem(icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Insights'),
    _NavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Wishlist'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppConstants.mediumAnimation,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: child,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.92),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withOpacity(0.04),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: AppConstants.mediumAnimation,
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: AppConstants.mediumAnimation,
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSelected ? 16 : 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: AnimatedSwitcher(
                                  duration: AppConstants.shortAnimation,
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    key: ValueKey(isSelected),
                                    size: isSelected ? 24 : 22,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: AppConstants.shortAnimation,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  letterSpacing: 0.1,
                                ),
                                child: Text(item.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
