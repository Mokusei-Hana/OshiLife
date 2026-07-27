import 'package:oshilife/import/fx_twitter_client.dart';
import 'package:oshilife/import/x_oembed_client.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Renders import-layer errors with the same strings iOS produces through
/// `LocalizedError`: oEmbed errors map to their `error.*` keys, FxTwitter
/// errors keep their English literals, and anything else falls back to its
/// description.
String describeImportError(AppLocalizations l10n, Object error) {
  if (error is XOEmbedException) {
    return switch (error.kind) {
      XOEmbedErrorKind.invalidUrl => l10n.errorInvalidXUrl,
      XOEmbedErrorKind.invalidResponse => l10n.errorOembedResponse,
      XOEmbedErrorKind.responseTooLarge => l10n.errorOembedTooLarge,
      XOEmbedErrorKind.httpStatus => l10n.errorOembedHttp(error.statusCode!),
    };
  }
  if (error is FXTwitterException) return error.message;
  return error.toString();
}
