import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/status_visuals.dart';
import 'package:oshilife/core/design/widgets/cover_image.dart';
import 'package:oshilife/core/design/widgets/section_card.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/features/import/import_editor_args.dart';
import 'package:oshilife/features/import/import_error_messages.dart';
import 'package:oshilife/features/import/import_providers.dart';
import 'package:oshilife/features/live_editor/live_editor_view_model.dart';
import 'package:oshilife/features/live_editor/ticket_entry_sheet.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `LiveEditorView.swift` as a fullscreen dialog. Section order,
/// the optional-date pattern, toggle-gated times, inline URL validation,
/// and the validation summary mirror iOS. The venue section is manual
/// entry (plan §7.5 Option A — no MapKit autocomplete on Android v1).
///
/// With [importArgs] this is the iOS `ImportEditorHost`: prefilled from
/// the pending share, duplicate banner on top, and closing asks for the
/// discard confirmation instead of popping.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.event, this.importArgs});

  final LiveEvent? event;
  final ImportEditorArgs? importArgs;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final LiveEditorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Route-scoped view model — the Flutter analogue of the iOS
    // host-owns-the-view-model sheet pattern.
    final importArgs = widget.importArgs;
    _viewModel = LiveEditorViewModel(
      store: ref.read(liveStoreProvider),
      event: widget.event,
      pendingImport: importArgs?.pending,
      pendingImageBytes: importArgs?.imageBytes,
      draftBuilder: importArgs == null
          ? null
          : ref.read(importDraftBuilderProvider),
      // iOS wraps retry failures in `share.metadata_warning` too.
      warningFormatter: importArgs == null ? null : _retryWarning,
    );
  }

  String _retryWarning(Object error) {
    final l10n = ref.read(l10nProvider);
    return l10n.shareMetadataWarning(describeImportError(l10n, error));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _validationText(AppLocalizations l10n, String key) {
    return switch (key) {
      'validation.artist_required' => l10n.validationArtistRequired,
      'validation.title_required' => l10n.validationTitleRequired,
      'validation.date_required' => l10n.validationDateRequired,
      'validation.ticket_url' => l10n.validationTicketUrl,
      _ => l10n.validationSourceUrl,
    };
  }

  Future<void> _save() async {
    final imageStore = await ref.read(imageStoreProvider.future);
    final saved = await _viewModel.save(imageStore: imageStore);
    if (saved != null && mounted) context.pop();
  }

  /// Import mode intercepts every close path (button and system back) with
  /// the iOS discard confirmation dialog.
  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importDiscardTitle),
        content: Text(l10n.importDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonContinueEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.importDiscardAction),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _handleClose() {
    if (widget.importArgs != null) {
      _confirmDiscard();
    } else {
      context.pop();
    }
  }

  /// iOS `onOpenDuplicate`: dismiss the import editor and show the saved
  /// event instead — one route swap here.
  void _openDuplicate(LiveEvent duplicate) {
    context.pushReplacement('/event/${duplicate.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return PopScope(
          // The iOS import sheet has interactive dismiss disabled; back
          // must go through the discard confirmation.
          canPop: widget.importArgs == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: _buildScaffold(context, vm, l10n),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    LiveEditorViewModel vm,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.commonCancel,
          onPressed: _handleClose,
        ),
        title: Text(vm.isEditing ? l10n.editorEditTitle : l10n.editorNewTitle),
        actions: [
          TextButton(
            key: const Key('editorSaveButton'),
            onPressed: vm.canSave ? _save : null,
            child: vm.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (widget.importArgs?.duplicate != null) ...[
            _duplicateBanner(widget.importArgs!.duplicate!, l10n),
            const SizedBox(height: 16),
          ],
          if (vm.importWarning != null) ...[
            _importWarningBanner(vm, l10n),
            const SizedBox(height: 16),
          ],
          if (vm.errorMessage != null) ...[
            _errorBanner(vm.errorMessage!),
            const SizedBox(height: 16),
          ],
          _coverSection(vm, l10n),
          const SizedBox(height: 16),
          _basicSection(vm, l10n),
          const SizedBox(height: 16),
          _scheduleSection(vm, l10n),
          const SizedBox(height: 16),
          _locationSection(vm, l10n),
          const SizedBox(height: 16),
          _ticketsSection(vm, l10n),
          const SizedBox(height: 16),
          _linksSection(vm, l10n),
          const SizedBox(height: 16),
          SectionCard(
            header: l10n.fieldNotes,
            child: TextField(
              controller: vm.notes,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          if (vm.validationMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _validationSummary(vm, l10n),
          ],
        ],
      ),
    );
  }

  /// Port of the iOS duplicate section: same source URL already saved,
  /// with a jump to the existing event.
  Widget _duplicateBanner(LiveEvent duplicate, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DesignRadius.medium),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_copy, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.importDuplicateTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.importDuplicateMessage(duplicate.title),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openDuplicate(duplicate),
              child: Text(l10n.importDuplicateOpen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _importWarningBanner(LiveEditorViewModel vm, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignRadius.medium),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.importWarning!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (vm.pendingImport != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: vm.isRetryingMetadata
                    ? null
                    : vm.retryImportMetadata,
                icon: vm.isRetryingMetadata
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(l10n.importRetry),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(DesignRadius.medium),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _coverSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    final imageStore = ref.watch(imageStoreProvider).value;
    File? existingFile;
    if (vm.coverImageBytes == null && !vm.removesExistingCover) {
      existingFile = imageStore?.imageFile(vm.existingCoverPath);
    }
    final hasCover = vm.coverImageBytes != null || existingFile != null;
    return SectionCard(
      header: l10n.fieldCover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCover) ...[
            CoverImage(
              bytes: vm.coverImageBytes,
              file: existingFile,
              height: 180,
              borderRadius: BorderRadius.circular(DesignRadius.medium),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickCover(vm),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(l10n.coverChoose),
              ),
              const SizedBox(width: 10),
              if (hasCover)
                TextButton.icon(
                  onPressed: () {
                    vm.coverImageBytes = null;
                    vm.removesExistingCover = true;
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.coverRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCover(LiveEditorViewModel vm) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    vm.coverImageBytes = bytes;
    vm.removesExistingCover = false;
  }

  Widget _basicSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    return SectionCard(
      header: l10n.editorBasic,
      child: Column(
        children: [
          TextField(
            key: const Key('editorArtistField'),
            controller: vm.artistName,
            decoration: InputDecoration(
              labelText: l10n.fieldArtist,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('editorPerformersField'),
            controller: vm.performersText,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.fieldPerformers,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('editorTitleField'),
            controller: vm.title,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.fieldTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.fieldStatus,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<LiveStatus>(
            segments: [
              for (final status in LiveStatus.values)
                ButtonSegment(
                  value: status,
                  icon: Icon(status.icon, size: 16),
                  label: Text(status.localizedName(l10n)),
                ),
            ],
            selected: {vm.status},
            onSelectionChanged: (selection) => vm.status = selection.first,
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final eventDate = vm.eventDate;
    final timeFormat = DateFormat.Hm(locale);
    return SectionCard(
      header: l10n.editorSchedule,
      child: Column(
        children: [
          // iOS optional-date pattern: a "choose" button until a date is
          // set, then the value with a destructive clear.
          Row(
            children: [
              Expanded(
                child: Text(
                  eventDate == null
                      ? l10n.fieldDate
                      : DateFormat.yMMMEd(locale).format(eventDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (eventDate != null)
                TextButton(
                  onPressed: () => vm.eventDate = null,
                  child: Text(l10n.fieldDateClear),
                ),
              FilledButton.tonal(
                key: const Key('editorDateChoose'),
                onPressed: () => _pickDate(vm),
                child: Text(l10n.fieldDateChoose),
              ),
            ],
          ),
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.fieldOpenTimeEnabled),
            value: vm.hasOpenTime,
            onChanged: (value) => vm.hasOpenTime = value,
          ),
          if (vm.hasOpenTime)
            _timeRow(
              label: l10n.fieldOpenTime,
              value: timeFormat.format(vm.openTime),
              onTap: () => _pickTime(
                initial: vm.openTime,
                onPicked: (value) => vm.openTime = value,
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.fieldStartTimeEnabled),
            value: vm.hasStartTime,
            onChanged: (value) => vm.hasStartTime = value,
          ),
          if (vm.hasStartTime)
            _timeRow(
              label: l10n.fieldStartTime,
              value: timeFormat.format(vm.startTime),
              onTap: () => _pickTime(
                initial: vm.startTime,
                onPicked: (value) => vm.startTime = value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: FilledButton.tonal(onPressed: onTap, child: Text(value)),
    );
  }

  Future<void> _pickDate(LiveEditorViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.eventDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) vm.eventDate = picked;
  }

  Future<void> _pickTime({
    required DateTime initial,
    required void Function(DateTime value) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked == null) return;
    // Like the iOS hour-and-minute picker, only the wall time changes;
    // the underlying day component is left as-is (plan §4.3).
    onPicked(
      DateTime(
        initial.year,
        initial.month,
        initial.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Widget _locationSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    return SectionCard(
      header: l10n.editorLocation,
      child: Column(
        children: [
          TextField(
            controller: vm.venue,
            decoration: InputDecoration(
              labelText: l10n.venuePickerTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.address,
            decoration: InputDecoration(
              labelText: l10n.venueSearchPlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          if (vm.venue.text.isNotEmpty || vm.address.text.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: vm.clearVenue,
                child: Text(l10n.venueClear),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ticketsSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final options = vm.ticketOptions;
    return SectionCard(
      header: l10n.editorTickets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (options.isEmpty)
            Text(
              l10n.ticketEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            DropdownButtonFormField<String?>(
              initialValue: vm.selectedTicketId,
              decoration: InputDecoration(
                labelText: l10n.fieldSelectedTicket,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.ticketNone),
                ),
                for (final option in options)
                  DropdownMenuItem<String?>(
                    value: option.id,
                    child: Text(option.name),
                  ),
              ],
              onChanged: (value) => vm.selectedTicketId = value,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < options.length; index += 1)
              Dismissible(
                key: ValueKey(options[index].id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => vm.removeTicketOptionAt(index),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: theme.colorScheme.error,
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onError,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(options[index].name),
                  subtitle: options[index].description == null
                      ? null
                      : Text(options[index].description!),
                  trailing: options[index].price == null
                      ? null
                      : Text(
                          '¥${NumberFormat.decimalPattern().format(options[index].price)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addTicket(vm),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.ticketAdd),
          ),
        ],
      ),
    );
  }

  Future<void> _addTicket(LiveEditorViewModel vm) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => TicketEntrySheet(
        onAdd: (name, price, description) => vm.addTicketOption(
          name: name,
          price: price,
          description: description,
        ),
      ),
    );
  }

  Widget _linksSection(LiveEditorViewModel vm, AppLocalizations l10n) {
    final ticketUrlInvalid =
        vm.ticketUrlString.text.trim().isNotEmpty &&
        LiveEvent.validHttpUrl(vm.ticketUrlString.text) == null;
    final sourceUrlInvalid =
        vm.sourceUrlString.text.trim().isNotEmpty &&
        LiveEvent.validHttpUrl(vm.sourceUrlString.text) == null;
    return SectionCard(
      header: l10n.editorLinks,
      child: Column(
        children: [
          TextField(
            controller: vm.ticketUrlString,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.fieldTicketUrl,
              border: const OutlineInputBorder(),
              errorText: ticketUrlInvalid ? l10n.validationTicketUrl : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.sourceUrlString,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.fieldSourceUrl,
              border: const OutlineInputBorder(),
              errorText: sourceUrlInvalid ? l10n.validationSourceUrl : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _validationSummary(LiveEditorViewModel vm, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SectionCard(
      header: l10n.validationTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in vm.validationMessages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationText(l10n, key),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
