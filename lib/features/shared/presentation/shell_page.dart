import 'package:flutter/material.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/core/design_system/components/steply_bottom_nav.dart';

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
    SteplyNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    SteplyNavItem(
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
      label: 'My Trip',
    ),
    SteplyNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    SteplyNavItem(
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      label: 'Saved',
    ),
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
      bottomNavigationBar: SteplyBottomNav(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        items: _items,
      ),
    );
  }
}
