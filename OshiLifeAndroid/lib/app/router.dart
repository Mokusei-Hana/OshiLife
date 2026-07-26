import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/features/home/home_screen.dart';
import 'package:oshilife/features/live_detail/detail_screen.dart';
import 'package:oshilife/features/settings/settings_screen.dart';

/// Route map mirroring the iOS navigation graph (plan §2.2): one root stack,
/// detail pushes by event id, settings pushes as a screen.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'event/:id',
            builder: (context, state) =>
                DetailScreen(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
