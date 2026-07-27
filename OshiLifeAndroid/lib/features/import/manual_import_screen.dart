import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/features/import/import_error_messages.dart';
import 'package:oshilife/features/import/import_providers.dart';
import 'package:oshilife/features/import/manual_import_view_model.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `ManualXImportView.swift`: paste an X post URL (with a one-shot
/// clipboard suggestion) and pop with the built `PendingShareImport` — the
/// caller hands it to the coordinator, mirroring the iOS sheet handoff.
class ManualImportScreen extends ConsumerStatefulWidget {
  const ManualImportScreen({super.key});

  @override
  ConsumerState<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends ConsumerState<ManualImportScreen> {
  late final ManualImportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ManualImportViewModel(
      draftBuilder: ref.read(importDraftBuilderProvider),
      // Read at error time so the message follows the active language.
      errorFormatter: (error) =>
          describeImportError(ref.read(l10nProvider), error),
    );
    Clipboard.getData(Clipboard.kTextPlain).then((data) {
      if (mounted) _viewModel.checkClipboard(data?.text);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final draft = await _viewModel.importDraft();
    if (draft != null && mounted) context.pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.commonCancel,
              onPressed: () => context.pop(),
            ),
            title: Text(l10n.manualImportTitle),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Icon(Icons.add_link, size: 34, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                l10n.manualImportMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (vm.clipboardSuggestion != null) ...[
                const SizedBox(height: 20),
                _clipboardSuggestionCard(vm, l10n, theme),
              ],
              const SizedBox(height: 24),
              TextField(
                key: const Key('manualImportUrlField'),
                controller: vm.urlText,
                keyboardType: TextInputType.url,
                autocorrect: false,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.manualImportUrlLabel,
                  hintText: l10n.manualImportUrlPlaceholder,
                  border: const OutlineInputBorder(),
                  errorText: vm.errorMessage,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('manualXImportButton'),
                onPressed: vm.canImport ? _import : null,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt, size: 18),
                label: Text(l10n.manualImportAction),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _clipboardSuggestionCard(
    ManualImportViewModel vm,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignRadius.large),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignRadius.large),
        onTap: vm.useClipboardSuggestion,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.content_paste,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.manualImportClipboardTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vm.clipboardSuggestion.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.manualImportClipboardAction,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
