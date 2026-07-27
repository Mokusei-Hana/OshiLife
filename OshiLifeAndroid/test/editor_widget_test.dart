import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('new editor validates required fields and saves once satisfied', (
    tester,
  ) async {
    // List mode: it shows every event, so the freshly saved live is visible
    // even though its picked date (today) is before the fixed test clock.
    await pumpApp(tester, prefs: {'settings.homeDisplayStyle': 'list'});
    final l10n = l10nOf(tester);

    // Open the add menu and create manually.
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.liveCreateManually).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.editorNewTitle), findsOneWidget);
    final saveButton = tester.widget<TextButton>(
      find.byKey(const Key('editorSaveButton')),
    );
    expect(saveButton.onPressed, isNull);

    // The validation summary sits at the bottom of the lazily built form.
    await scrollTo(tester, find.text(l10n.validationArtistRequired));
    expect(find.text(l10n.validationArtistRequired), findsOneWidget);
    expect(find.text(l10n.validationTitleRequired), findsOneWidget);
    expect(find.text(l10n.validationDateRequired), findsOneWidget);

    // Scroll back up to the basic section and fill the required fields.
    await scrollTo(
      tester,
      find.byKey(const Key('editorArtistField')),
      delta: -200,
    );
    await tester.enterText(find.byKey(const Key('editorArtistField')), '推し');
    await tester.enterText(
      find.byKey(const Key('editorTitleField')),
      'ワンマンライブ',
    );
    await tester.pump();

    await scrollTo(tester, find.byKey(const Key('editorDateChoose')));
    await tester.tap(find.byKey(const Key('editorDateChoose')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final enabledSave = tester.widget<TextButton>(
      find.byKey(const Key('editorSaveButton')),
    );
    expect(enabledSave.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('editorSaveButton')));
    await tester.pumpAndSettle();

    // Back on home with the saved event visible.
    expect(find.text('ワンマンライブ'), findsWidgets);

    await disposeApp(tester);
  });

  testWidgets('invalid ticket URL shows the inline validation message', (
    tester,
  ) async {
    await pumpApp(tester);
    final l10n = l10nOf(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.liveCreateManually).last);
    await tester.pumpAndSettle();

    final ticketUrlField = find.widgetWithText(TextField, l10n.fieldTicketUrl);
    await scrollTo(tester, ticketUrlField);
    await tester.enterText(ticketUrlField, 'not a url');
    await tester.pump();

    // Inline error plus the validation summary entry.
    expect(find.text(l10n.validationTicketUrl), findsWidgets);

    await disposeApp(tester);
  });
}
