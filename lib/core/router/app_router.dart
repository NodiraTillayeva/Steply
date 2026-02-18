import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:steply/features/analysis/presentation/pages/analysis_page.dart';
import 'package:steply/features/analysis/presentation/pages/itinerary_page.dart';
import 'package:steply/features/map_view/presentation/pages/map_page.dart';
import 'package:steply/features/shared/presentation/shell_page.dart';
import 'package:steply/features/wishlist/presentation/pages/wishlist_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/map',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellPage(
          currentIndex: navigationShell.currentIndex,
          onTabChanged: (index) => navigationShell.goBranch(index),
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/itinerary',
              builder: (context, state) => const ItineraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analysis',
              builder: (context, state) => const AnalysisPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (context, state) => const WishlistPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
