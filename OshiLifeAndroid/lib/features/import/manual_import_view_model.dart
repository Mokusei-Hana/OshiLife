import 'package:flutter/widgets.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';
import 'package:oshilife/import/x_oembed_client.dart';
import 'package:oshilife/import/x_url_validator.dart';

/// Port of `ManualXImportViewModel.swift`.
///
/// Error strings are produced by the injected [errorFormatter] so the
/// model stays free of localization state (the invalid-URL case reuses
/// `XOEmbedException.invalidUrl`, whose localized description is the same
/// `error.invalid_x_url` string iOS shows).
class ManualImportViewModel extends ChangeNotifier {
  ManualImportViewModel({
    XImportDraftBuilder? draftBuilder,
    String Function(Object error)? errorFormatter,
  }) : _draftBuilder = draftBuilder ?? XImportDraftBuilder(),
       _errorFormatter = errorFormatter ?? ((error) => error.toString()) {
    urlText.addListener(_onUrlTextChanged);
  }

  final XImportDraftBuilder _draftBuilder;
  final String Function(Object error) _errorFormatter;

  final TextEditingController urlText = TextEditingController();

  bool _didCheckClipboard = false;
  Uri? _clipboardSuggestion;
  bool _isLoading = false;
  String? _errorMessage;
  String _lastUrlText = '';

  Uri? get clipboardSuggestion => _clipboardSuggestion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Uri? get normalizedUrl =>
      XUrlValidator.normalizedPostUrlFromText(urlText.text);

  bool get canImport => urlText.text.trim().isNotEmpty && !_isLoading;

  /// iOS clears the error whenever the URL text changes (the view's
  /// `.onChange`); here the controller listener owns that rule.
  void _onUrlTextChanged() {
    if (urlText.text != _lastUrlText) {
      _lastUrlText = urlText.text;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// The clipboard is inspected once per presentation, like the iOS
  /// `.task` guarded by `didCheckClipboard`.
  void checkClipboard(String? text) {
    if (_didCheckClipboard) return;
    _didCheckClipboard = true;
    _clipboardSuggestion = text == null
        ? null
        : XUrlValidator.firstPostUrl(text);
    notifyListeners();
  }

  void useClipboardSuggestion() {
    final suggestion = _clipboardSuggestion;
    if (suggestion == null) return;
    urlText.text = suggestion.toString();
    _clipboardSuggestion = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<PendingShareImport?> importDraft() async {
    final normalized = normalizedUrl;
    if (normalized == null) {
      _errorMessage = _errorFormatter(const XOEmbedException.invalidUrl());
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _draftBuilder.makeDraft(normalized);
    } on Object catch (error) {
      _errorMessage = _errorFormatter(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    urlText.dispose();
    super.dispose();
  }
}
