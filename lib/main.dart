import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/core/di/injection.dart';
import 'package:steply/core/router/app_router.dart';
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

class SteplyApp extends StatelessWidget {
  const SteplyApp({super.key});

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
      ),
    );
  }
}
