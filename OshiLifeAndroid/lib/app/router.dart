import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/features/home/home_screen.dart';
import 'package:oshilife/features/import/import_editor_args.dart';
import 'package:oshilife/features/import/manual_import_screen.dart';
import 'package:oshilife/features/import/share_import_progress_screen.dart';
import 'package:oshilife/features/live_detail/detail_screen.dart';
import 'package:oshilife/features/live_editor/editor_screen.dart';
import 'package:oshilife/features/settings/settings_screen.dart';

/// Route map mirroring the iOS navigation graph (plan §2.2): one root
/// stack; detail pushes by event id; settings pushes as a screen; the
/// editor presents as a fullscreen dialog (the iOS sheet) with an optional
/// [LiveEvent] extra — null creates, non-null edits. The import flow adds
/// three more dialogs: the manual X import sheet, the share progress
/// screen, and the import editor fed by [ImportEditorArgs].
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
          GoRoute(
            path: 'editor',
            pageBuilder: (context, state) => MaterialPage(
              fullscreenDialog: true,
              child: EditorScreen(event: state.extra as LiveEvent?),
            ),
          ),
          GoRoute(
            path: 'import/manual',
            pageBuilder: (context, state) => const MaterialPage(
              fullscreenDialog: true,
              child: ManualImportScreen(),
            ),
          ),
          GoRoute(
            path: 'import/receive',
            pageBuilder: (context, state) => const MaterialPage(
              fullscreenDialog: true,
              child: ShareImportProgressScreen(),
            ),
          ),
          GoRoute(
            path: 'import/editor',
            pageBuilder: (context, state) => MaterialPage(
              fullscreenDialog: true,
              child: EditorScreen(importArgs: state.extra as ImportEditorArgs?),
            ),
          ),
        ],
      ),
    ],
  );
});
