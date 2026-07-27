import 'package:uuid/uuid.dart';

/// Port of `Shared/Models/TicketOption.swift`.
///
/// JSON must round-trip data written by the iOS app: `id` is an
/// uppercase UUID string, `price` is whole yen, and null `price` /
/// `description` are omitted from the encoded object (Swift's synthesized
/// `Codable` uses `encodeIfPresent` for optionals).
class TicketOption {
  TicketOption({String? id, required this.name, this.price, this.description})
    : id = id ?? const Uuid().v4().toUpperCase();

  factory TicketOption.fromJson(Map<String, dynamic> json) {
    return TicketOption(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toInt(),
      description: json['description'] as String?,
    );
  }

  final String id;
  String name;
  int? price;
  String? description;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (price != null) 'price': price,
      if (description != null) 'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TicketOption &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, name, price, description);

  @override
  String toString() =>
      'TicketOption(id: $id, name: $name, price: $price, description: $description)';
}
