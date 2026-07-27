import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/features/import/import_error_messages.dart';
import 'package:oshilife/features/import/import_providers.dart';
import 'package:oshilife/features/import/share_receive_coordinator.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// The share landing screen — the iOS `ShareViewController` UI running
/// inside the app (plan §7.2): a spinner with `share.processing` while the
/// import runs (the coordinator then swaps this screen for the import
/// editor), or the failure with a close button.
class ShareImportProgressScreen extends ConsumerWidget {
  const ShareImportProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final coordinator = ref.watch(shareReceiveCoordinatorProvider);
    final error = coordinator.shareError;

    return PopScope(
      // Not dismissible mid-import, like the iOS extension modal.
      canPop: error != null,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.shareTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: error == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 18),
                      Text(l10n.shareProcessing),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _describe(l10n, error),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: () => context.pop(),
                        child: Text(l10n.commonClose),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _describe(AppLocalizations l10n, Object error) {
    if (error is SharedTextHasNoPostUrl) return l10n.shareInvalidUrl;
    return describeImportError(l10n, error);
  }
}
