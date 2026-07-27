import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/data/models/venue_selection.dart';
import 'package:oshilife/features/live_editor/live_editor_view_model.dart';
import 'package:oshilife/import/models/event_import_details.dart';
import 'package:oshilife/import/models/pending_share_import.dart';

// Port of OshiLifeTests/LiveEditorViewModelTests.swift.
void main() {
  late OshiLifeDatabase database;
  late LiveStore store;
  late Directory imageRoot;
  late ImageStore imageStore;

  setUp(() {
    database = OshiLifeDatabase(NativeDatabase.memory());
    store = LiveStore(database);
    imageRoot = Directory.systemTemp.createTempSync('oshilife-editor-test-');
    imageStore = ImageStore(root: imageRoot);
  });

  tearDown(() async {
    await database.close();
    if (imageRoot.existsSync()) {
      imageRoot.deleteSync(recursive: true);
    }
  });

  test('requires artist, title, and date', () {
    final viewModel = LiveEditorViewModel(store: store);
    expect(viewModel.canSave, isFalse);
    expect(viewModel.validationMessages, hasLength(3));

    viewModel.artistName.text = '推し';
    viewModel.title.text = 'ワンマンライブ';
    viewModel.eventDate = DateTime.now();
    expect(viewModel.canSave, isTrue);
  });

  test('import maps author, text, and URL without inferring event fields', () {
    final sourceUrl = Uri.parse('https://x.com/oshi/status/42');
    final pending = PendingShareImport(
      sourceUrl: sourceUrl,
      authorName: '推し',
      postText: 'ライブ告知',
    );
    final viewModel = LiveEditorViewModel(store: store, pendingImport: pending);

    expect(viewModel.artistName.text, '推し');
    expect(viewModel.notes.text, 'ライブ告知');
    expect(viewModel.sourceUrlString.text, sourceUrl.toString());
    expect(viewModel.title.text, isEmpty);
    expect(viewModel.eventDate, isNull);
  });

  test('import maps parsed event fields into editable editor', () async {
    final sourceUrl = Uri.parse('https://x.com/oshi/status/42');
    final eventUrl = Uri.parse('https://heroines.jp/news/event');
    final date = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);
    final details = EventImportDetails(
      title: 'HEROINES FES',
      date: date,
      venue: 'Spotify O-EAST',
      openTime: date.add(const Duration(hours: 17)),
      startTime: date.add(const Duration(hours: 18)),
      performers: ['iLiFE!', 'のんふぃく！'],
      ticketOptions: [
        TicketOption(name: 'Sチケット', price: 9000),
        TicketOption(name: 'Aチケット', price: 3500),
      ],
      ticketInformation: '一般チケット ¥3,500',
      linkedUrl: eventUrl,
    );
    final pending = PendingShareImport(
      sourceUrl: sourceUrl,
      authorName: '公式',
      postText: 'ライブ告知',
      eventDetails: details,
    );

    final viewModel = LiveEditorViewModel(store: store, pendingImport: pending);

    expect(viewModel.artistName.text, 'iLiFE! / のんふぃく！');
    expect(viewModel.title.text, 'HEROINES FES');
    expect(viewModel.eventDate, date);
    expect(viewModel.venue.text, 'Spotify O-EAST');
    expect(viewModel.hasOpenTime, isTrue);
    expect(viewModel.hasStartTime, isTrue);
    expect(viewModel.performersText.text, 'iLiFE! / のんふぃく！');
    expect(viewModel.ticketOptions, hasLength(2));
    expect(viewModel.ticketUrlString.text, eventUrl.toString());
    expect(viewModel.sourceUrlString.text, sourceUrl.toString());
    expect(viewModel.notes.text, contains('一般チケット ¥3,500'));

    viewModel.title.text = '編集したタイトル';
    viewModel.selectedTicketId = viewModel.ticketOptions[0].id;
    final saved = await viewModel.save(imageStore: imageStore);
    expect(saved, isNotNull);
    expect(saved!.selectedTicketId, viewModel.ticketOptions[0].id);
    expect(saved.selectedTicketName, 'Sチケット');
    expect(saved.ticketOptions, hasLength(2));
    expect(viewModel.title.text, '編集したタイトル');
  });

  test('venue selection saves resolved location', () async {
    final viewModel = LiveEditorViewModel(store: store);
    viewModel.artistName.text = '推し';
    viewModel.title.text = 'ワンマンライブ';
    viewModel.eventDate = DateTime.now();

    viewModel.selectVenue(
      const VenueSelection(
        name: '日本武道館',
        address: '東京都千代田区北の丸公園2-3',
        latitude: 35.693317,
        longitude: 139.749885,
      ),
    );

    final event = await viewModel.save(imageStore: imageStore);
    expect(event, isNotNull);
    expect(event!.venue, '日本武道館');
    expect(event.address, '東京都千代田区北の丸公園2-3');
    expect(event.latitude, 35.693317);
    expect(event.longitude, 139.749885);
  });

  test(
    'import without parsed tickets starts empty and allows manual entry',
    () async {
      final sourceUrl = Uri.parse('https://x.com/oshi/status/42');
      final pending = PendingShareImport(
        sourceUrl: sourceUrl,
        authorName: '推し',
        postText: 'ライブ告知',
      );
      final viewModel = LiveEditorViewModel(
        store: store,
        pendingImport: pending,
      );
      viewModel.title.text = 'ワンマンライブ';
      viewModel.eventDate = DateTime.now();

      expect(viewModel.ticketOptions, isEmpty);

      final added = viewModel.addTicketOption(
        name: ' 一般チケット ',
        price: 3500,
        description: ' ドリンク代別 ',
      );
      expect(added, isNotNull);
      expect(added!.name, '一般チケット');
      expect(added.price, 3500);
      expect(added.description, 'ドリンク代別');
      viewModel.selectedTicketId = added.id;

      final saved = await viewModel.save(imageStore: imageStore);
      expect(saved, isNotNull);
      expect(saved!.ticketOptions, hasLength(1));
      expect(saved.selectedTicketId, added.id);
    },
  );

  test('addTicketOption rejects blank name and drops empty description', () {
    final viewModel = LiveEditorViewModel(store: store);

    expect(
      viewModel.addTicketOption(name: '   ', price: 1000, description: null),
      isNull,
    );
    expect(viewModel.ticketOptions, isEmpty);

    final added = viewModel.addTicketOption(
      name: 'VIP',
      price: null,
      description: '  ',
    );
    expect(added, isNotNull);
    expect(added!.price, isNull);
    expect(added.description, isNull);
  });

  test('removing selected ticket clears selection', () {
    final viewModel = LiveEditorViewModel(store: store);
    final first = viewModel.addTicketOption(name: 'Sチケット', price: 9000)!;
    final second = viewModel.addTicketOption(name: 'Aチケット', price: 3500)!;

    viewModel.selectedTicketId = first.id;
    viewModel.removeTicketOptionAt(0);
    expect(viewModel.selectedTicketId, isNull);
    expect(viewModel.ticketOptions, [second]);

    viewModel.selectedTicketId = second.id;
    viewModel.removeTicketOptionAt(1);
    expect(viewModel.selectedTicketId, second.id);
    expect(viewModel.ticketOptions, [second]);
  });

  test('clearing venue also clears coordinates', () {
    final event = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
      venue: '日本武道館',
      address: '東京都千代田区',
      latitude: 35.693317,
      longitude: 139.749885,
    );
    final viewModel = LiveEditorViewModel(store: store, event: event);

    viewModel.clearVenue();

    expect(viewModel.venue.text, isEmpty);
    expect(viewModel.address.text, isEmpty);
    expect(viewModel.latitude, isNull);
    expect(viewModel.longitude, isNull);
  });

  test('editing replaces the cover only after a successful save', () async {
    final existing = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
    );
    await store.insertEvent(existing);

    final viewModel = LiveEditorViewModel(store: store, event: existing);
    viewModel.removesExistingCover = true;
    final saved = await viewModel.save(imageStore: imageStore);
    expect(saved, isNotNull);
    expect(saved!.coverImagePath, isNull);
    expect((await store.eventById(existing.id))!.coverImagePath, isNull);
  });
}
