import 'dart:typed_data';

import 'package:oshilife/import/models/event_import_details.dart';
import 'package:uuid/uuid.dart';

/// Port of `Shared/Models/PendingShareImport.swift`.
///
/// `imageBytes` mirrors the iOS `imageData` property: deliberately excluded
/// from JSON — downloaded media stays in memory only. JSON keys match the
/// Swift `CodingKeys` (`sourceURL` with capital URL), and `id` is an
/// uppercase UUID string like Swift's `uuidString`.
class PendingShareImport {
  PendingShareImport({
    String? id,
    required this.sourceUrl,
    this.authorName,
    this.postText,
    this.imageRelativePath,
    this.imageBytes,
    DateTime? createdAt,
    this.warning,
    this.eventDetails,
  }) : id = id ?? const Uuid().v4().toUpperCase(),
       createdAt = createdAt ?? DateTime.now();

  factory PendingShareImport.fromJson(Map<String, dynamic> json) {
    final rawSourceUrl = json['sourceURL'];
    final sourceUrl = rawSourceUrl is String
        ? Uri.tryParse(rawSourceUrl)
        : null;
    if (sourceUrl == null) {
      throw const FormatException('PendingShareImport requires sourceURL');
    }
    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt)
        : null;
    return PendingShareImport(
      id: json['id'] as String?,
      sourceUrl: sourceUrl,
      authorName: json['authorName'] as String?,
      postText: json['postText'] as String?,
      imageRelativePath: json['imageRelativePath'] as String?,
      createdAt: createdAt,
      warning: json['warning'] as String?,
      eventDetails: json['eventDetails'] == null
          ? null
          : EventImportDetails.fromJson(
              json['eventDetails'] as Map<String, dynamic>,
            ),
    );
  }

  final String id;
  Uri sourceUrl;
  String? authorName;
  String? postText;
  String? imageRelativePath;

  /// Downloaded media, kept only while the draft is in memory — never
  /// serialized (matches the iOS `CodingKeys` omission).
  Uint8List? imageBytes;

  DateTime createdAt;
  String? warning;
  EventImportDetails? eventDetails;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceURL': sourceUrl.toString(),
      if (authorName != null) 'authorName': authorName,
      if (postText != null) 'postText': postText,
      if (imageRelativePath != null) 'imageRelativePath': imageRelativePath,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (warning != null) 'warning': warning,
      if (eventDetails != null) 'eventDetails': eventDetails!.toJson(),
    };
  }
}
