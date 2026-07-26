import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/data/models/venue_selection.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';

/// Port of `LiveEditorViewModel.swift`.
///
/// Text-backed fields live in [TextEditingController]s (each notifies this
/// model, so validation stays live); everything else is plain state with
/// mutator methods. The initializer performs the same three-way merge as
/// iOS: existing event → imported details → pending-import fallback →
/// defaults.
///
/// Validation message strings are injected ([validationMessages] returns
/// localization keys; the form maps them) so the model stays free of
/// Flutter localization state.
class LiveEditorViewModel extends ChangeNotifier {
  LiveEditorViewModel({
    required LiveStore store,
    LiveEvent? event,
    this.pendingImport,
    Uint8List? pendingImageBytes,
    XImportDraftBuilder? draftBuilder,
    String Function(Object error)? warningFormatter,
  }) : _store = store, // ignore: prefer_initializing_formals
       _existingEvent = event,
       _draftBuilder = draftBuilder ?? XImportDraftBuilder(),
       _warningFormatter = warningFormatter ?? ((error) => error.toString()) {
    final importedDetails = pendingImport?.eventDetails;
    final importedPerformers = importedDetails?.performers ?? const [];

    artistName.text =
        event?.artistName ??
        (importedPerformers.isNotEmpty
            ? importedPerformers.join(' / ')
            : null) ??
        pendingImport?.authorName ??
        '';
    title.text = event?.title ?? importedDetails?.title ?? '';
    _eventDate = event?.eventDate ?? importedDetails?.date;
    _hasOpenTime = event?.openTime != null || importedDetails?.openTime != null;
    _openTime = event?.openTime ?? importedDetails?.openTime ?? DateTime.now();
    _hasStartTime =
        event?.startTime != null || importedDetails?.startTime != null;
    _startTime =
        event?.startTime ?? importedDetails?.startTime ?? DateTime.now();
    performersText.text =
        event?.performers.join(' / ') ??
        (importedPerformers.isNotEmpty
            ? importedPerformers.join(' / ')
            : null) ??
        '';
    _ticketOptions = List.of(
      event?.ticketOptions ?? importedDetails?.ticketOptions ?? [],
    );
    _selectedTicketId = event?.selectedTicketId;
    venue.text = event?.venue ?? importedDetails?.venue ?? '';
    address.text = event?.address ?? '';
    _latitude = event?.latitude;
    _longitude = event?.longitude;
    ticketUrlString.text =
        event?.ticketUrlString ?? importedDetails?.linkedUrl.toString() ?? '';
    sourceUrlString.text =
        event?.sourceUrlString ?? pendingImport?.sourceUrl.toString() ?? '';
    notes.text = event?.notes ?? _importNotes(pendingImport);
    _status = event?.status ?? LiveStatus.planned;
    _coverImageBytes = pendingImageBytes;
    _importWarning = pendingImport?.warning;

    for (final controller in _controllers) {
      controller.addListener(notifyListeners);
    }
  }

  final LiveStore _store;
  final LiveEvent? _existingEvent;
  final XImportDraftBuilder _draftBuilder;
  final String Function(Object error) _warningFormatter;
  final PendingShareImport? pendingImport;

  final TextEditingController artistName = TextEditingController();
  final TextEditingController title = TextEditingController();
  final TextEditingController performersText = TextEditingController();
  final TextEditingController venue = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController ticketUrlString = TextEditingController();
  final TextEditingController sourceUrlString = TextEditingController();
  final TextEditingController notes = TextEditingController();

  late final List<TextEditingController> _controllers = [
    artistName,
    title,
    performersText,
    venue,
    address,
    ticketUrlString,
    sourceUrlString,
    notes,
  ];

  DateTime? _eventDate;
  bool _hasOpenTime = false;
  DateTime _openTime = DateTime.now();
  bool _hasStartTime = false;
  DateTime _startTime = DateTime.now();
  List<TicketOption> _ticketOptions = [];
  String? _selectedTicketId;
  double? _latitude;
  double? _longitude;
  LiveStatus _status = LiveStatus.planned;
  Uint8List? _coverImageBytes;
  bool _removesExistingCover = false;
  String? _errorMessage;
  String? _importWarning;
  bool _isRetryingMetadata = false;
  bool _isSaving = false;

  DateTime? get eventDate => _eventDate;
  set eventDate(DateTime? value) {
    _eventDate = value;
    notifyListeners();
  }

  bool get hasOpenTime => _hasOpenTime;
  set hasOpenTime(bool value) {
    _hasOpenTime = value;
    notifyListeners();
  }

  DateTime get openTime => _openTime;
  set openTime(DateTime value) {
    _openTime = value;
    notifyListeners();
  }

  bool get hasStartTime => _hasStartTime;
  set hasStartTime(bool value) {
    _hasStartTime = value;
    notifyListeners();
  }

  DateTime get startTime => _startTime;
  set startTime(DateTime value) {
    _startTime = value;
    notifyListeners();
  }

  List<TicketOption> get ticketOptions => List.unmodifiable(_ticketOptions);

  String? get selectedTicketId => _selectedTicketId;
  set selectedTicketId(String? value) {
    _selectedTicketId = value;
    notifyListeners();
  }

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  LiveStatus get status => _status;
  set status(LiveStatus value) {
    _status = value;
    notifyListeners();
  }

  Uint8List? get coverImageBytes => _coverImageBytes;
  set coverImageBytes(Uint8List? value) {
    _coverImageBytes = value;
    notifyListeners();
  }

  bool get removesExistingCover => _removesExistingCover;
  set removesExistingCover(bool value) {
    _removesExistingCover = value;
    notifyListeners();
  }

  String? get errorMessage => _errorMessage;
  String? get importWarning => _importWarning;
  bool get isRetryingMetadata => _isRetryingMetadata;
  bool get isSaving => _isSaving;

  bool get isEditing => _existingEvent != null;
  String? get existingCoverPath => _existingEvent?.coverImagePath;

  /// Validation rules ported 1:1; returned as localization keys
  /// (`validation.*`), mapped to strings by the form.
  List<String> get validationMessages {
    final messages = <String>[];
    if (artistName.text.trim().isEmpty) {
      messages.add('validation.artist_required');
    }
    if (title.text.trim().isEmpty) {
      messages.add('validation.title_required');
    }
    if (_eventDate == null) {
      messages.add('validation.date_required');
    }
    if (ticketUrlString.text.trim().isNotEmpty &&
        LiveEvent.validHttpUrl(ticketUrlString.text) == null) {
      messages.add('validation.ticket_url');
    }
    if (sourceUrlString.text.trim().isNotEmpty &&
        LiveEvent.validHttpUrl(sourceUrlString.text) == null) {
      messages.add('validation.source_url');
    }
    return messages;
  }

  bool get canSave => validationMessages.isEmpty && !_isSaving;

  void selectVenue(VenueSelection selection) {
    venue.text = selection.name;
    address.text = selection.address;
    _latitude = selection.latitude;
    _longitude = selection.longitude;
    notifyListeners();
  }

  void clearVenue() {
    venue.text = '';
    address.text = '';
    _latitude = null;
    _longitude = null;
    notifyListeners();
  }

  TicketOption? addTicketOption({
    required String name,
    int? price,
    String? description,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;
    final trimmedDescription = description?.trim();
    final option = TicketOption(
      name: trimmedName,
      price: price,
      description: (trimmedDescription != null && trimmedDescription.isNotEmpty)
          ? trimmedDescription
          : null,
    );
    _ticketOptions.add(option);
    notifyListeners();
    return option;
  }

  void removeTicketOptionAt(int index) {
    if (index < 0 || index >= _ticketOptions.length) return;
    final removedId = _ticketOptions[index].id;
    _ticketOptions.removeAt(index);
    if (_selectedTicketId == removedId) {
      _selectedTicketId = null;
    }
    notifyListeners();
  }

  /// Port of `retryImportMetadata()`: re-runs the draft builder and fills
  /// only empty fields; `sourceURLString` and the warning are always
  /// overwritten.
  Future<void> retryImportMetadata() async {
    final pending = pendingImport;
    if (pending == null) return;
    _isRetryingMetadata = true;
    notifyListeners();
    try {
      final draft = await _draftBuilder.makeDraft(pending.sourceUrl);
      final details = draft.eventDetails;
      if (artistName.text.trim().isEmpty) {
        if (details != null && details.performers.isNotEmpty) {
          artistName.text = details.performers.join(' / ');
        } else {
          artistName.text = draft.authorName ?? '';
        }
      }
      if (title.text.trim().isEmpty) title.text = details?.title ?? '';
      _eventDate ??= details?.date;
      if (venue.text.trim().isEmpty) venue.text = details?.venue ?? '';
      final importedOpen = details?.openTime;
      if (!_hasOpenTime && importedOpen != null) {
        _openTime = importedOpen;
        _hasOpenTime = true;
      }
      final importedStart = details?.startTime;
      if (!_hasStartTime && importedStart != null) {
        _startTime = importedStart;
        _hasStartTime = true;
      }
      if (ticketUrlString.text.trim().isEmpty) {
        ticketUrlString.text = details?.linkedUrl.toString() ?? '';
      }
      if (notes.text.trim().isEmpty) {
        notes.text = _importNotes(draft);
      }
      if (_ticketOptions.isEmpty) {
        _ticketOptions = List.of(details?.ticketOptions ?? []);
      }
      if (performersText.text.trim().isEmpty) {
        performersText.text = details == null
            ? ''
            : details.performers.join(' / ');
      }
      _coverImageBytes ??= draft.imageBytes;
      sourceUrlString.text = draft.sourceUrl.toString();
      _importWarning = draft.warning;
    } on Object catch (error) {
      _importWarning = _warningFormatter(error);
    } finally {
      _isRetryingMetadata = false;
      notifyListeners();
    }
  }

  /// Port of the iOS note composition: post text, then "OPEN <time>", then
  /// the ticket information, joined with blank lines.
  static String _importNotes(PendingShareImport? pending) {
    if (pending == null) return '';
    final sections = <String>[];
    final postText = pending.postText?.trim();
    if (postText != null && postText.isNotEmpty) sections.add(postText);
    final openTime = pending.eventDetails?.openTime;
    if (openTime != null) {
      sections.add('OPEN ${DateFormat.Hm().format(openTime)}');
    }
    final ticketInformation = pending.eventDetails?.ticketInformation;
    if (ticketInformation != null && ticketInformation.trim().isNotEmpty) {
      sections.add(ticketInformation);
    }
    return sections.join('\n\n');
  }

  static List<String> splitPerformers(String text) {
    return text
        .split(RegExp('[/／、,]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  /// Port of `save(imageStore:)`: write-replacement-file-first, mutate or
  /// create the event, persist, then delete the superseded cover only
  /// after the database succeeded; on failure remove the newly written
  /// file.
  Future<LiveEvent?> save({required ImageStore imageStore}) async {
    final eventDate = _eventDate;
    if (!canSave || eventDate == null) return null;
    _isSaving = true;
    notifyListeners();

    final oldImagePath = _existingEvent?.coverImagePath;
    String? newImagePath;
    try {
      final coverBytes = _coverImageBytes;
      if (coverBytes != null) {
        newImagePath = await imageStore.saveJpeg(coverBytes);
      }

      final event =
          _existingEvent ??
          LiveEvent(
            artistName: artistName.text.trim(),
            title: title.text.trim(),
            eventDate: eventDate,
          );
      event.artistName = artistName.text.trim();
      event.title = title.text.trim();
      event.eventDate = eventDate;
      event.openTime = _hasOpenTime ? _openTime : null;
      event.startTime = _hasStartTime ? _startTime : null;
      event.performers = splitPerformers(performersText.text);
      event.venue = venue.text.trim();
      event.address = address.text.trim();
      event.latitude = _latitude;
      event.longitude = _longitude;
      event.ticketUrlString = ticketUrlString.text.trim();
      event.sourceUrlString = sourceUrlString.text.trim();
      event.ticketOptions = _ticketOptions;
      event.selectedTicketId = _selectedTicketId;
      event.notes = notes.text.trim();
      event.status = _status;
      event.updatedAt = DateTime.now();
      if (newImagePath != null) {
        event.coverImagePath = newImagePath;
      } else if (_removesExistingCover) {
        event.coverImagePath = null;
      }

      if (_existingEvent == null) {
        await _store.insertEvent(event);
      } else {
        await _store.saveEvent(event);
      }

      if (oldImagePath != event.coverImagePath) {
        try {
          await imageStore.remove(oldImagePath);
        } on Object {
          // Orphan cleanup is best-effort, like the iOS `try?`.
        }
      }
      _errorMessage = null;
      return event;
    } on Object catch (error) {
      if (newImagePath != null) {
        try {
          await imageStore.remove(newImagePath);
        } on Object {
          // Best-effort rollback of the newly written file.
        }
      }
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
