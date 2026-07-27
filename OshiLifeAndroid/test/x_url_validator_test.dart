import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/import/x_url_validator.dart';

// Port of OshiLifeTests/XURLValidatorTests.swift.
void main() {
  test('normalizes X and legacy Twitter URLs', () {
    expect(
      XUrlValidator.normalizedPostUrl(
        Uri.parse('https://x.com/example/status/123456?ref_src=test#fragment'),
      )?.toString(),
      'https://x.com/example/status/123456',
    );
    expect(
      XUrlValidator.normalizedPostUrl(
        Uri.parse('https://mobile.twitter.com/example/status/987'),
      )?.toString(),
      'https://x.com/example/status/987',
    );
  });

  test('rejects unsupported or non-status URLs', () {
    expect(
      XUrlValidator.normalizedPostUrl(Uri.parse('http://x.com/a/status/1')),
      isNull,
    );
    expect(
      XUrlValidator.normalizedPostUrl(
        Uri.parse('https://example.com/a/status/1'),
      ),
      isNull,
    );
    expect(
      XUrlValidator.normalizedPostUrl(Uri.parse('https://x.com/a/photo/1')),
      isNull,
    );
    expect(
      XUrlValidator.normalizedPostUrl(
        Uri.parse('https://x.com/a/status/not-a-number'),
      ),
      isNull,
    );
    expect(
      XUrlValidator.normalizedPostUrl(Uri.parse('https://x.com/a/status/１２３')),
      isNull,
    );
  });

  test('extracts first valid URL from text', () {
    const text =
        'こちら https://example.com/nope と https://twitter.com/oshi/status/42?s=20';
    expect(
      XUrlValidator.firstPostUrl(text)?.toString(),
      'https://x.com/oshi/status/42',
    );
  });

  test('normalizes pasted URL text and rejects invalid text', () {
    expect(
      XUrlValidator.normalizedPostUrlFromText(
        '  https://www.twitter.com/oshi/status/42?s=20\n',
      )?.toString(),
      'https://x.com/oshi/status/42',
    );
    expect(XUrlValidator.normalizedPostUrlFromText('not a URL'), isNull);
    expect(
      XUrlValidator.normalizedPostUrlFromText('https://x.com/oshi'),
      isNull,
    );
  });
}
