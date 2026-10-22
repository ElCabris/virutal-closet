import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/closet/closet_screen.dart';
import 'presentation/screens/closet/garment_detail_screen.dart';
import 'presentation/screens/closet/add_garment_screen.dart';
import 'presentation/screens/outfits/outfits_screen.dart';
import 'presentation/screens/outfits/outfit_builder_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/analytics/analytics_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Notifica a GoRouter cuando cambia el estado de auth, sin recrear el router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier();
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute && loc != '/') return '/closet';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Shell route for main navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/closet',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ClosetScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const AddGarmentScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) =>
                    GarmentDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/outfits',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: OutfitsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'builder',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const OutfitBuilderScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Redirect /home to /closet
      GoRoute(
        path: '/home',
        redirect: (_, __) => '/closet',
      ),
    ],
  );
});

class VirtualClosetApp extends ConsumerWidget {
  const VirtualClosetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Virtual Closet',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
