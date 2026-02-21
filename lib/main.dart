import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/core/di/injection.dart';
import 'package:steply/core/router/app_router.dart';
import 'package:steply/core/services/sharing_intent_service.dart';
import 'package:steply/core/theme/app_theme.dart';
import 'package:steply/features/analysis/presentation/bloc/comfort_bloc.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/map_view/presentation/bloc/map_bloc.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SteplyApp());
}

class SteplyApp extends StatefulWidget {
  const SteplyApp({super.key});

  @override
  State<SteplyApp> createState() => _SteplyAppState();
}

class _SteplyAppState extends State<SteplyApp> {
  final SharingIntentService _sharingService = getIt<SharingIntentService>();
  String? _pendingSharedUrl;

  @override
  void initState() {
    super.initState();
    _initSharing();
  }

  Future<void> _initSharing() async {
    // Handle cold start - check if app was opened via share
    final initialUrl = await _sharingService.getInitialSharedURL();
    if (initialUrl != null) {
      setState(() => _pendingSharedUrl = initialUrl);
    }

    // Handle warm start - listen for shares while app is running
    _sharingService.onUrlReceived = (url) {
      // Navigate to wishlist
      appRouter.go('/saved');
      // Wait for navigation to complete, then trigger extraction
      Future.delayed(const Duration(milliseconds: 300), () {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          context.read<WishlistBloc>().add(ExtractFromUrl(url: url));
        }
      });
    };

    _sharingService.initialize();
  }

  @override
  void dispose() {
    _sharingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapBloc>(
          create: (_) => getIt<MapBloc>(),
        ),
        BlocProvider<ItineraryBloc>(
          create: (_) => getIt<ItineraryBloc>(),
        ),
        BlocProvider<ComfortBloc>(
          create: (_) => getIt<ComfortBloc>(),
        ),
        BlocProvider<WishlistBloc>(
          create: (_) => getIt<WishlistBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Steply',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        builder: (context, child) {
          // Handle pending shared URL after router is ready
          if (_pendingSharedUrl != null) {
            final url = _pendingSharedUrl!;
            _pendingSharedUrl = null;

            // Navigate to wishlist tab and trigger extraction
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appRouter.go('/saved');
              Future.delayed(const Duration(milliseconds: 300), () {
                context.read<WishlistBloc>().add(ExtractFromUrl(url: url));
              });
            });
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
