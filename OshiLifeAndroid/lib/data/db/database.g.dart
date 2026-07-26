// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LiveEventsTable extends LiveEvents
    with TableInfo<$LiveEventsTable, LiveEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openTimeMeta = const VerificationMeta(
    'openTime',
  );
  @override
  late final GeneratedColumn<DateTime> openTime = GeneratedColumn<DateTime>(
    'open_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
    'venue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImagePathMeta = const VerificationMeta(
    'coverImagePath',
  );
  @override
  late final GeneratedColumn<String> coverImagePath = GeneratedColumn<String>(
    'cover_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketUrlStringMeta = const VerificationMeta(
    'ticketUrlString',
  );
  @override
  late final GeneratedColumn<String> ticketUrlString = GeneratedColumn<String>(
    'ticket_url_string',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceUrlStringMeta = const VerificationMeta(
    'sourceUrlString',
  );
  @override
  late final GeneratedColumn<String> sourceUrlString = GeneratedColumn<String>(
    'source_url_string',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _performersJsonMeta = const VerificationMeta(
    'performersJson',
  );
  @override
  late final GeneratedColumn<String> performersJson = GeneratedColumn<String>(
    'performers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _ticketOptionsJsonMeta = const VerificationMeta(
    'ticketOptionsJson',
  );
  @override
  late final GeneratedColumn<String> ticketOptionsJson =
      GeneratedColumn<String>(
        'ticket_options_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _selectedTicketIdMeta = const VerificationMeta(
    'selectedTicketId',
  );
  @override
  late final GeneratedColumn<String> selectedTicketId = GeneratedColumn<String>(
    'selected_ticket_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusRawValueMeta = const VerificationMeta(
    'statusRawValue',
  );
  @override
  late final GeneratedColumn<String> statusRawValue = GeneratedColumn<String>(
    'status_raw_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    artistName,
    title,
    eventDate,
    openTime,
    startTime,
    venue,
    address,
    latitude,
    longitude,
    coverImagePath,
    ticketUrlString,
    sourceUrlString,
    performersJson,
    ticketOptionsJson,
    selectedTicketId,
    notes,
    statusRawValue,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('open_time')) {
      context.handle(
        _openTimeMeta,
        openTime.isAcceptableOrUnknown(data['open_time']!, _openTimeMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('venue')) {
      context.handle(
        _venueMeta,
        venue.isAcceptableOrUnknown(data['venue']!, _venueMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('cover_image_path')) {
      context.handle(
        _coverImagePathMeta,
        coverImagePath.isAcceptableOrUnknown(
          data['cover_image_path']!,
          _coverImagePathMeta,
        ),
      );
    }
    if (data.containsKey('ticket_url_string')) {
      context.handle(
        _ticketUrlStringMeta,
        ticketUrlString.isAcceptableOrUnknown(
          data['ticket_url_string']!,
          _ticketUrlStringMeta,
        ),
      );
    }
    if (data.containsKey('source_url_string')) {
      context.handle(
        _sourceUrlStringMeta,
        sourceUrlString.isAcceptableOrUnknown(
          data['source_url_string']!,
          _sourceUrlStringMeta,
        ),
      );
    }
    if (data.containsKey('performers_json')) {
      context.handle(
        _performersJsonMeta,
        performersJson.isAcceptableOrUnknown(
          data['performers_json']!,
          _performersJsonMeta,
        ),
      );
    }
    if (data.containsKey('ticket_options_json')) {
      context.handle(
        _ticketOptionsJsonMeta,
        ticketOptionsJson.isAcceptableOrUnknown(
          data['ticket_options_json']!,
          _ticketOptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('selected_ticket_id')) {
      context.handle(
        _selectedTicketIdMeta,
        selectedTicketId.isAcceptableOrUnknown(
          data['selected_ticket_id']!,
          _selectedTicketIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status_raw_value')) {
      context.handle(
        _statusRawValueMeta,
        statusRawValue.isAcceptableOrUnknown(
          data['status_raw_value']!,
          _statusRawValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statusRawValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiveEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      artistName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date'],
      )!,
      openTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}open_time'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      ),
      venue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      coverImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_path'],
      ),
      ticketUrlString: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_url_string'],
      )!,
      sourceUrlString: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url_string'],
      )!,
      performersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}performers_json'],
      )!,
      ticketOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_options_json'],
      )!,
      selectedTicketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_ticket_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      statusRawValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_raw_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LiveEventsTable createAlias(String alias) {
    return $LiveEventsTable(attachedDatabase, alias);
  }
}

class LiveEventRow extends DataClass implements Insertable<LiveEventRow> {
  final String id;
  final String artistName;
  final String title;
  final DateTime eventDate;
  final DateTime? openTime;
  final DateTime? startTime;
  final String venue;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? coverImagePath;
  final String ticketUrlString;
  final String sourceUrlString;
  final String performersJson;
  final String ticketOptionsJson;
  final String? selectedTicketId;
  final String notes;
  final String statusRawValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LiveEventRow({
    required this.id,
    required this.artistName,
    required this.title,
    required this.eventDate,
    this.openTime,
    this.startTime,
    required this.venue,
    required this.address,
    this.latitude,
    this.longitude,
    this.coverImagePath,
    required this.ticketUrlString,
    required this.sourceUrlString,
    required this.performersJson,
    required this.ticketOptionsJson,
    this.selectedTicketId,
    required this.notes,
    required this.statusRawValue,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['artist_name'] = Variable<String>(artistName);
    map['title'] = Variable<String>(title);
    map['event_date'] = Variable<DateTime>(eventDate);
    if (!nullToAbsent || openTime != null) {
      map['open_time'] = Variable<DateTime>(openTime);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    map['venue'] = Variable<String>(venue);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || coverImagePath != null) {
      map['cover_image_path'] = Variable<String>(coverImagePath);
    }
    map['ticket_url_string'] = Variable<String>(ticketUrlString);
    map['source_url_string'] = Variable<String>(sourceUrlString);
    map['performers_json'] = Variable<String>(performersJson);
    map['ticket_options_json'] = Variable<String>(ticketOptionsJson);
    if (!nullToAbsent || selectedTicketId != null) {
      map['selected_ticket_id'] = Variable<String>(selectedTicketId);
    }
    map['notes'] = Variable<String>(notes);
    map['status_raw_value'] = Variable<String>(statusRawValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LiveEventsCompanion toCompanion(bool nullToAbsent) {
    return LiveEventsCompanion(
      id: Value(id),
      artistName: Value(artistName),
      title: Value(title),
      eventDate: Value(eventDate),
      openTime: openTime == null && nullToAbsent
          ? const Value.absent()
          : Value(openTime),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      venue: Value(venue),
      address: Value(address),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      coverImagePath: coverImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImagePath),
      ticketUrlString: Value(ticketUrlString),
      sourceUrlString: Value(sourceUrlString),
      performersJson: Value(performersJson),
      ticketOptionsJson: Value(ticketOptionsJson),
      selectedTicketId: selectedTicketId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedTicketId),
      notes: Value(notes),
      statusRawValue: Value(statusRawValue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LiveEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveEventRow(
      id: serializer.fromJson<String>(json['id']),
      artistName: serializer.fromJson<String>(json['artistName']),
      title: serializer.fromJson<String>(json['title']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      openTime: serializer.fromJson<DateTime?>(json['openTime']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      venue: serializer.fromJson<String>(json['venue']),
      address: serializer.fromJson<String>(json['address']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      coverImagePath: serializer.fromJson<String?>(json['coverImagePath']),
      ticketUrlString: serializer.fromJson<String>(json['ticketUrlString']),
      sourceUrlString: serializer.fromJson<String>(json['sourceUrlString']),
      performersJson: serializer.fromJson<String>(json['performersJson']),
      ticketOptionsJson: serializer.fromJson<String>(json['ticketOptionsJson']),
      selectedTicketId: serializer.fromJson<String?>(json['selectedTicketId']),
      notes: serializer.fromJson<String>(json['notes']),
      statusRawValue: serializer.fromJson<String>(json['statusRawValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'artistName': serializer.toJson<String>(artistName),
      'title': serializer.toJson<String>(title),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'openTime': serializer.toJson<DateTime?>(openTime),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'venue': serializer.toJson<String>(venue),
      'address': serializer.toJson<String>(address),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'coverImagePath': serializer.toJson<String?>(coverImagePath),
      'ticketUrlString': serializer.toJson<String>(ticketUrlString),
      'sourceUrlString': serializer.toJson<String>(sourceUrlString),
      'performersJson': serializer.toJson<String>(performersJson),
      'ticketOptionsJson': serializer.toJson<String>(ticketOptionsJson),
      'selectedTicketId': serializer.toJson<String?>(selectedTicketId),
      'notes': serializer.toJson<String>(notes),
      'statusRawValue': serializer.toJson<String>(statusRawValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LiveEventRow copyWith({
    String? id,
    String? artistName,
    String? title,
    DateTime? eventDate,
    Value<DateTime?> openTime = const Value.absent(),
    Value<DateTime?> startTime = const Value.absent(),
    String? venue,
    String? address,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> coverImagePath = const Value.absent(),
    String? ticketUrlString,
    String? sourceUrlString,
    String? performersJson,
    String? ticketOptionsJson,
    Value<String?> selectedTicketId = const Value.absent(),
    String? notes,
    String? statusRawValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LiveEventRow(
    id: id ?? this.id,
    artistName: artistName ?? this.artistName,
    title: title ?? this.title,
    eventDate: eventDate ?? this.eventDate,
    openTime: openTime.present ? openTime.value : this.openTime,
    startTime: startTime.present ? startTime.value : this.startTime,
    venue: venue ?? this.venue,
    address: address ?? this.address,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    coverImagePath: coverImagePath.present
        ? coverImagePath.value
        : this.coverImagePath,
    ticketUrlString: ticketUrlString ?? this.ticketUrlString,
    sourceUrlString: sourceUrlString ?? this.sourceUrlString,
    performersJson: performersJson ?? this.performersJson,
    ticketOptionsJson: ticketOptionsJson ?? this.ticketOptionsJson,
    selectedTicketId: selectedTicketId.present
        ? selectedTicketId.value
        : this.selectedTicketId,
    notes: notes ?? this.notes,
    statusRawValue: statusRawValue ?? this.statusRawValue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LiveEventRow copyWithCompanion(LiveEventsCompanion data) {
    return LiveEventRow(
      id: data.id.present ? data.id.value : this.id,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      title: data.title.present ? data.title.value : this.title,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      openTime: data.openTime.present ? data.openTime.value : this.openTime,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      venue: data.venue.present ? data.venue.value : this.venue,
      address: data.address.present ? data.address.value : this.address,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      coverImagePath: data.coverImagePath.present
          ? data.coverImagePath.value
          : this.coverImagePath,
      ticketUrlString: data.ticketUrlString.present
          ? data.ticketUrlString.value
          : this.ticketUrlString,
      sourceUrlString: data.sourceUrlString.present
          ? data.sourceUrlString.value
          : this.sourceUrlString,
      performersJson: data.performersJson.present
          ? data.performersJson.value
          : this.performersJson,
      ticketOptionsJson: data.ticketOptionsJson.present
          ? data.ticketOptionsJson.value
          : this.ticketOptionsJson,
      selectedTicketId: data.selectedTicketId.present
          ? data.selectedTicketId.value
          : this.selectedTicketId,
      notes: data.notes.present ? data.notes.value : this.notes,
      statusRawValue: data.statusRawValue.present
          ? data.statusRawValue.value
          : this.statusRawValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveEventRow(')
          ..write('id: $id, ')
          ..write('artistName: $artistName, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('openTime: $openTime, ')
          ..write('startTime: $startTime, ')
          ..write('venue: $venue, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('ticketUrlString: $ticketUrlString, ')
          ..write('sourceUrlString: $sourceUrlString, ')
          ..write('performersJson: $performersJson, ')
          ..write('ticketOptionsJson: $ticketOptionsJson, ')
          ..write('selectedTicketId: $selectedTicketId, ')
          ..write('notes: $notes, ')
          ..write('statusRawValue: $statusRawValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    artistName,
    title,
    eventDate,
    openTime,
    startTime,
    venue,
    address,
    latitude,
    longitude,
    coverImagePath,
    ticketUrlString,
    sourceUrlString,
    performersJson,
    ticketOptionsJson,
    selectedTicketId,
    notes,
    statusRawValue,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveEventRow &&
          other.id == this.id &&
          other.artistName == this.artistName &&
          other.title == this.title &&
          other.eventDate == this.eventDate &&
          other.openTime == this.openTime &&
          other.startTime == this.startTime &&
          other.venue == this.venue &&
          other.address == this.address &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.coverImagePath == this.coverImagePath &&
          other.ticketUrlString == this.ticketUrlString &&
          other.sourceUrlString == this.sourceUrlString &&
          other.performersJson == this.performersJson &&
          other.ticketOptionsJson == this.ticketOptionsJson &&
          other.selectedTicketId == this.selectedTicketId &&
          other.notes == this.notes &&
          other.statusRawValue == this.statusRawValue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LiveEventsCompanion extends UpdateCompanion<LiveEventRow> {
  final Value<String> id;
  final Value<String> artistName;
  final Value<String> title;
  final Value<DateTime> eventDate;
  final Value<DateTime?> openTime;
  final Value<DateTime?> startTime;
  final Value<String> venue;
  final Value<String> address;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> coverImagePath;
  final Value<String> ticketUrlString;
  final Value<String> sourceUrlString;
  final Value<String> performersJson;
  final Value<String> ticketOptionsJson;
  final Value<String?> selectedTicketId;
  final Value<String> notes;
  final Value<String> statusRawValue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LiveEventsCompanion({
    this.id = const Value.absent(),
    this.artistName = const Value.absent(),
    this.title = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.openTime = const Value.absent(),
    this.startTime = const Value.absent(),
    this.venue = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.ticketUrlString = const Value.absent(),
    this.sourceUrlString = const Value.absent(),
    this.performersJson = const Value.absent(),
    this.ticketOptionsJson = const Value.absent(),
    this.selectedTicketId = const Value.absent(),
    this.notes = const Value.absent(),
    this.statusRawValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveEventsCompanion.insert({
    required String id,
    required String artistName,
    required String title,
    required DateTime eventDate,
    this.openTime = const Value.absent(),
    this.startTime = const Value.absent(),
    this.venue = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.ticketUrlString = const Value.absent(),
    this.sourceUrlString = const Value.absent(),
    this.performersJson = const Value.absent(),
    this.ticketOptionsJson = const Value.absent(),
    this.selectedTicketId = const Value.absent(),
    this.notes = const Value.absent(),
    required String statusRawValue,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       artistName = Value(artistName),
       title = Value(title),
       eventDate = Value(eventDate),
       statusRawValue = Value(statusRawValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LiveEventRow> custom({
    Expression<String>? id,
    Expression<String>? artistName,
    Expression<String>? title,
    Expression<DateTime>? eventDate,
    Expression<DateTime>? openTime,
    Expression<DateTime>? startTime,
    Expression<String>? venue,
    Expression<String>? address,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? coverImagePath,
    Expression<String>? ticketUrlString,
    Expression<String>? sourceUrlString,
    Expression<String>? performersJson,
    Expression<String>? ticketOptionsJson,
    Expression<String>? selectedTicketId,
    Expression<String>? notes,
    Expression<String>? statusRawValue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (artistName != null) 'artist_name': artistName,
      if (title != null) 'title': title,
      if (eventDate != null) 'event_date': eventDate,
      if (openTime != null) 'open_time': openTime,
      if (startTime != null) 'start_time': startTime,
      if (venue != null) 'venue': venue,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (coverImagePath != null) 'cover_image_path': coverImagePath,
      if (ticketUrlString != null) 'ticket_url_string': ticketUrlString,
      if (sourceUrlString != null) 'source_url_string': sourceUrlString,
      if (performersJson != null) 'performers_json': performersJson,
      if (ticketOptionsJson != null) 'ticket_options_json': ticketOptionsJson,
      if (selectedTicketId != null) 'selected_ticket_id': selectedTicketId,
      if (notes != null) 'notes': notes,
      if (statusRawValue != null) 'status_raw_value': statusRawValue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? artistName,
    Value<String>? title,
    Value<DateTime>? eventDate,
    Value<DateTime?>? openTime,
    Value<DateTime?>? startTime,
    Value<String>? venue,
    Value<String>? address,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? coverImagePath,
    Value<String>? ticketUrlString,
    Value<String>? sourceUrlString,
    Value<String>? performersJson,
    Value<String>? ticketOptionsJson,
    Value<String?>? selectedTicketId,
    Value<String>? notes,
    Value<String>? statusRawValue,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LiveEventsCompanion(
      id: id ?? this.id,
      artistName: artistName ?? this.artistName,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      openTime: openTime ?? this.openTime,
      startTime: startTime ?? this.startTime,
      venue: venue ?? this.venue,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      ticketUrlString: ticketUrlString ?? this.ticketUrlString,
      sourceUrlString: sourceUrlString ?? this.sourceUrlString,
      performersJson: performersJson ?? this.performersJson,
      ticketOptionsJson: ticketOptionsJson ?? this.ticketOptionsJson,
      selectedTicketId: selectedTicketId ?? this.selectedTicketId,
      notes: notes ?? this.notes,
      statusRawValue: statusRawValue ?? this.statusRawValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (openTime.present) {
      map['open_time'] = Variable<DateTime>(openTime.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (coverImagePath.present) {
      map['cover_image_path'] = Variable<String>(coverImagePath.value);
    }
    if (ticketUrlString.present) {
      map['ticket_url_string'] = Variable<String>(ticketUrlString.value);
    }
    if (sourceUrlString.present) {
      map['source_url_string'] = Variable<String>(sourceUrlString.value);
    }
    if (performersJson.present) {
      map['performers_json'] = Variable<String>(performersJson.value);
    }
    if (ticketOptionsJson.present) {
      map['ticket_options_json'] = Variable<String>(ticketOptionsJson.value);
    }
    if (selectedTicketId.present) {
      map['selected_ticket_id'] = Variable<String>(selectedTicketId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (statusRawValue.present) {
      map['status_raw_value'] = Variable<String>(statusRawValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveEventsCompanion(')
          ..write('id: $id, ')
          ..write('artistName: $artistName, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('openTime: $openTime, ')
          ..write('startTime: $startTime, ')
          ..write('venue: $venue, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('ticketUrlString: $ticketUrlString, ')
          ..write('sourceUrlString: $sourceUrlString, ')
          ..write('performersJson: $performersJson, ')
          ..write('ticketOptionsJson: $ticketOptionsJson, ')
          ..write('selectedTicketId: $selectedTicketId, ')
          ..write('notes: $notes, ')
          ..write('statusRawValue: $statusRawValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OshiLifeDatabase extends GeneratedDatabase {
  _$OshiLifeDatabase(QueryExecutor e) : super(e);
  $OshiLifeDatabaseManager get managers => $OshiLifeDatabaseManager(this);
  late final $LiveEventsTable liveEvents = $LiveEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [liveEvents];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LiveEventsTableCreateCompanionBuilder =
    LiveEventsCompanion Function({
      required String id,
      required String artistName,
      required String title,
      required DateTime eventDate,
      Value<DateTime?> openTime,
      Value<DateTime?> startTime,
      Value<String> venue,
      Value<String> address,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> coverImagePath,
      Value<String> ticketUrlString,
      Value<String> sourceUrlString,
      Value<String> performersJson,
      Value<String> ticketOptionsJson,
      Value<String?> selectedTicketId,
      Value<String> notes,
      required String statusRawValue,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LiveEventsTableUpdateCompanionBuilder =
    LiveEventsCompanion Function({
      Value<String> id,
      Value<String> artistName,
      Value<String> title,
      Value<DateTime> eventDate,
      Value<DateTime?> openTime,
      Value<DateTime?> startTime,
      Value<String> venue,
      Value<String> address,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> coverImagePath,
      Value<String> ticketUrlString,
      Value<String> sourceUrlString,
      Value<String> performersJson,
      Value<String> ticketOptionsJson,
      Value<String?> selectedTicketId,
      Value<String> notes,
      Value<String> statusRawValue,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LiveEventsTableFilterComposer
    extends Composer<_$OshiLifeDatabase, $LiveEventsTable> {
  $$LiveEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openTime => $composableBuilder(
    column: $table.openTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketUrlString => $composableBuilder(
    column: $table.ticketUrlString,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrlString => $composableBuilder(
    column: $table.sourceUrlString,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get performersJson => $composableBuilder(
    column: $table.performersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketOptionsJson => $composableBuilder(
    column: $table.ticketOptionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedTicketId => $composableBuilder(
    column: $table.selectedTicketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusRawValue => $composableBuilder(
    column: $table.statusRawValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LiveEventsTableOrderingComposer
    extends Composer<_$OshiLifeDatabase, $LiveEventsTable> {
  $$LiveEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openTime => $composableBuilder(
    column: $table.openTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketUrlString => $composableBuilder(
    column: $table.ticketUrlString,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrlString => $composableBuilder(
    column: $table.sourceUrlString,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get performersJson => $composableBuilder(
    column: $table.performersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketOptionsJson => $composableBuilder(
    column: $table.ticketOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedTicketId => $composableBuilder(
    column: $table.selectedTicketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusRawValue => $composableBuilder(
    column: $table.statusRawValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LiveEventsTableAnnotationComposer
    extends Composer<_$OshiLifeDatabase, $LiveEventsTable> {
  $$LiveEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<DateTime> get openTime =>
      $composableBuilder(column: $table.openTime, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ticketUrlString => $composableBuilder(
    column: $table.ticketUrlString,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrlString => $composableBuilder(
    column: $table.sourceUrlString,
    builder: (column) => column,
  );

  GeneratedColumn<String> get performersJson => $composableBuilder(
    column: $table.performersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ticketOptionsJson => $composableBuilder(
    column: $table.ticketOptionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedTicketId => $composableBuilder(
    column: $table.selectedTicketId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get statusRawValue => $composableBuilder(
    column: $table.statusRawValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LiveEventsTableTableManager
    extends
        RootTableManager<
          _$OshiLifeDatabase,
          $LiveEventsTable,
          LiveEventRow,
          $$LiveEventsTableFilterComposer,
          $$LiveEventsTableOrderingComposer,
          $$LiveEventsTableAnnotationComposer,
          $$LiveEventsTableCreateCompanionBuilder,
          $$LiveEventsTableUpdateCompanionBuilder,
          (
            LiveEventRow,
            BaseReferences<_$OshiLifeDatabase, $LiveEventsTable, LiveEventRow>,
          ),
          LiveEventRow,
          PrefetchHooks Function()
        > {
  $$LiveEventsTableTableManager(_$OshiLifeDatabase db, $LiveEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> eventDate = const Value.absent(),
                Value<DateTime?> openTime = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<String> venue = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String> ticketUrlString = const Value.absent(),
                Value<String> sourceUrlString = const Value.absent(),
                Value<String> performersJson = const Value.absent(),
                Value<String> ticketOptionsJson = const Value.absent(),
                Value<String?> selectedTicketId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> statusRawValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveEventsCompanion(
                id: id,
                artistName: artistName,
                title: title,
                eventDate: eventDate,
                openTime: openTime,
                startTime: startTime,
                venue: venue,
                address: address,
                latitude: latitude,
                longitude: longitude,
                coverImagePath: coverImagePath,
                ticketUrlString: ticketUrlString,
                sourceUrlString: sourceUrlString,
                performersJson: performersJson,
                ticketOptionsJson: ticketOptionsJson,
                selectedTicketId: selectedTicketId,
                notes: notes,
                statusRawValue: statusRawValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String artistName,
                required String title,
                required DateTime eventDate,
                Value<DateTime?> openTime = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<String> venue = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String> ticketUrlString = const Value.absent(),
                Value<String> sourceUrlString = const Value.absent(),
                Value<String> performersJson = const Value.absent(),
                Value<String> ticketOptionsJson = const Value.absent(),
                Value<String?> selectedTicketId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                required String statusRawValue,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LiveEventsCompanion.insert(
                id: id,
                artistName: artistName,
                title: title,
                eventDate: eventDate,
                openTime: openTime,
                startTime: startTime,
                venue: venue,
                address: address,
                latitude: latitude,
                longitude: longitude,
                coverImagePath: coverImagePath,
                ticketUrlString: ticketUrlString,
                sourceUrlString: sourceUrlString,
                performersJson: performersJson,
                ticketOptionsJson: ticketOptionsJson,
                selectedTicketId: selectedTicketId,
                notes: notes,
                statusRawValue: statusRawValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiveEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$OshiLifeDatabase,
      $LiveEventsTable,
      LiveEventRow,
      $$LiveEventsTableFilterComposer,
      $$LiveEventsTableOrderingComposer,
      $$LiveEventsTableAnnotationComposer,
      $$LiveEventsTableCreateCompanionBuilder,
      $$LiveEventsTableUpdateCompanionBuilder,
      (
        LiveEventRow,
        BaseReferences<_$OshiLifeDatabase, $LiveEventsTable, LiveEventRow>,
      ),
      LiveEventRow,
      PrefetchHooks Function()
    >;

class $OshiLifeDatabaseManager {
  final _$OshiLifeDatabase _db;
  $OshiLifeDatabaseManager(this._db);
  $$LiveEventsTableTableManager get liveEvents =>
      $$LiveEventsTableTableManager(_db, _db.liveEvents);
}
