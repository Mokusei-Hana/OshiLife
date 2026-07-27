// Converts the iOS String Catalog (Shared/Resources/Localizable.xcstrings)
// into Flutter ARB files (lib/l10n/app_ja.arb + app_zh.arb) plus a parity
// manifest (lib/l10n/l10n_parity.json) mapping iOS keys to ARB ids.
//
// Run from the OshiLifeAndroid directory:
//   dart run tool/convert_xcstrings.dart
//
// The catalog stays the single source of truth: string changes land on iOS
// first, then this script is re-run in the same parity PR. CI regenerates
// and fails if the committed output is stale.
import 'dart:convert';
import 'dart:io';

const String defaultCatalogPath = '../Shared/Resources/Localizable.xcstrings';
const String outputDir = 'lib/l10n';

/// Keys that exist in the catalog but are referenced nowhere in the iOS app
/// (verified by grep) — skipped per plan §8.
const Set<String> orphanedKeys = {
  'home.next_live',
  'detail.ticket',
  'detail.available_tickets',
  'display_mode.title',
  'field.venue',
  'field.address',
};

/// The five printf-style format keys, with explicit ARB ids and named
/// placeholders (order matters: positional %1$@/%2$@ map onto this list).
const Map<String, ({String id, List<({String name, String type})> args})>
formatKeys = {
  'card.accessibility %@ %@': (
    id: 'cardAccessibility',
    args: [(name: 'artist', type: 'String'), (name: 'title', type: 'String')],
  ),
  'error.oembed_http %lld': (
    id: 'errorOembedHttp',
    args: [(name: 'code', type: 'int')],
  ),
  'error.persistence_fallback %@': (
    id: 'errorPersistenceFallback',
    args: [(name: 'message', type: 'String')],
  ),
  'import.duplicate.message %@': (
    id: 'importDuplicateMessage',
    args: [(name: 'title', type: 'String')],
  ),
  'share.metadata_warning %@': (
    id: 'shareMetadataWarning',
    args: [(name: 'message', type: 'String')],
  ),
};

void main(List<String> arguments) {
  final catalogPath = arguments.isNotEmpty
      ? arguments.first
      : defaultCatalogPath;
  final catalogFile = File(catalogPath);
  if (!catalogFile.existsSync()) {
    stderr.writeln('Catalog not found: $catalogPath');
    exit(1);
  }

  final catalog =
      jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
  final strings = catalog['strings'] as Map<String, dynamic>;

  final ja = <String, dynamic>{'@@locale': 'ja'};
  final zh = <String, dynamic>{'@@locale': 'zh'};
  final parity = <String, String>{};
  final seenIds = <String>{};
  var skippedOrphans = 0;

  final sortedKeys = strings.keys.toList()..sort();
  for (final key in sortedKeys) {
    if (orphanedKeys.contains(key)) {
      skippedOrphans += 1;
      continue;
    }

    final jaValue = _localizedValue(strings[key], 'ja');
    if (jaValue == null) {
      stderr.writeln('Missing ja translation for "$key"');
      exit(1);
    }
    var zhValue = _localizedValue(strings[key], 'zh-Hans');
    if (zhValue == null) {
      stderr.writeln('WARN: missing zh-Hans for "$key", falling back to ja');
      zhValue = jaValue;
    }

    final format = formatKeys[key];
    final id = format?.id ?? _camelCaseId(key);
    if (!seenIds.add(id)) {
      stderr.writeln('Duplicate ARB id "$id" (from "$key")');
      exit(1);
    }
    parity[key] = id;

    if (format == null) {
      _assertNoBraces(key, jaValue);
      _assertNoBraces(key, zhValue);
      ja[id] = jaValue;
      zh[id] = zhValue;
    } else {
      ja[id] = _convertPlaceholders(jaValue, format.args);
      zh[id] = _convertPlaceholders(zhValue, format.args);
      ja['@$id'] = {
        'placeholders': {
          for (final arg in format.args) arg.name: {'type': arg.type},
        },
      };
    }
  }

  Directory(outputDir).createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  File('$outputDir/app_ja.arb').writeAsStringSync('${encoder.convert(ja)}\n');
  File('$outputDir/app_zh.arb').writeAsStringSync('${encoder.convert(zh)}\n');
  File(
    '$outputDir/l10n_parity.json',
  ).writeAsStringSync('${encoder.convert(parity)}\n');

  stdout.writeln(
    'Converted ${parity.length} keys '
    '($skippedOrphans orphaned keys skipped).',
  );
}

String? _localizedValue(Object? entry, String locale) {
  if (entry is! Map<String, dynamic>) return null;
  final localizations = entry['localizations'];
  if (localizations is! Map<String, dynamic>) return null;
  final localization = localizations[locale];
  if (localization is! Map<String, dynamic>) return null;
  final unit = localization['stringUnit'];
  if (unit is! Map<String, dynamic>) return null;
  final value = unit['value'];
  return value is String ? value : null;
}

/// `settings.language.simplified_chinese` → `settingsLanguageSimplifiedChinese`.
String _camelCaseId(String key) {
  final parts = key.split(RegExp(r'[._]')).where((p) => p.isNotEmpty).toList();
  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    buffer.write(part[0].toUpperCase());
    buffer.write(part.substring(1));
  }
  return buffer.toString();
}

/// Replaces `%1$@`-style positional and `%@`/`%lld` sequential specifiers
/// with `{name}` ICU placeholders.
String _convertPlaceholders(
  String value,
  List<({String name, String type})> args,
) {
  var result = value;
  for (var index = 0; index < args.length; index += 1) {
    final position = index + 1;
    result = result
        .replaceAll('%$position\$@', '{${args[index].name}}')
        .replaceAll('%$position\$lld', '{${args[index].name}}');
  }
  for (final arg in args) {
    if (!result.contains('{${arg.name}}')) {
      final specifier = arg.type == 'int' ? '%lld' : '%@';
      final index = result.indexOf(specifier);
      if (index < 0) {
        stderr.writeln('Cannot map placeholder ${arg.name} in "$value"');
        exit(1);
      }
      result = result.replaceFirst(specifier, '{${arg.name}}');
    }
  }
  return result;
}

void _assertNoBraces(String key, String value) {
  if (value.contains('{') || value.contains('}')) {
    stderr.writeln(
      'Value for "$key" contains literal braces; extend the converter to '
      'escape them before adding such strings.',
    );
    exit(1);
  }
}
