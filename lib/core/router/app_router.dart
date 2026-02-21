import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:steply/features/analysis/presentation/pages/analysis_page.dart';
import 'package:steply/features/analysis/presentation/pages/itinerary_page.dart';
import 'package:steply/features/map_view/presentation/pages/map_page.dart';
import 'package:steply/features/shared/presentation/shell_page.dart';
import 'package:steply/features/wishlist/presentation/pages/wishlist_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
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
        // Tab 0: Home (Map/Explore)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),
        // Tab 1: My Trip (Itinerary)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trip',
              builder: (context, state) => const ItineraryPage(),
            ),
          ],
        ),
        // Tab 2: Discover (Insights/Analysis)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const AnalysisPage(),
            ),
          ],
        ),
        // Tab 3: Saved (Wishlist)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const WishlistPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
