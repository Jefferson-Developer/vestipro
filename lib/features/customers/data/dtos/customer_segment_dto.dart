import '../../../../core/errors/errors.dart';

final class CustomerSegmentDto {
  const CustomerSegmentDto({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.visibility,
    this.statuses = const <String>[],
    this.stateCodes = const <String>[],
    this.potentials = const <String>[],
    this.lastPurchase = 'any',
    this.purchasedCategoryCodes = const <String>[],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  factory CustomerSegmentDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final organizationId = json['organizationId'];
    final name = json['name'];
    final visibility = json['visibility'];
    final createdBy = json['createdBy'];
    final createdAt = json['createdAt'];
    final updatedBy = json['updatedBy'];
    final updatedAt = json['updatedAt'];
    final version = json['version'];

    if (id is! String ||
        organizationId is! String ||
        name is! String ||
        visibility is! String ||
        createdBy is! String ||
        createdAt is! String ||
        updatedBy is! String ||
        updatedAt is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid customer segment payload.',
        code: 'invalid_customer_segment_local_payload',
      );
    }

    return CustomerSegmentDto(
      id: id,
      organizationId: organizationId,
      name: name,
      visibility: visibility,
      statuses: _stringList(json['statuses']),
      stateCodes: _stringList(json['stateCodes']),
      potentials: _stringList(json['potentials']),
      lastPurchase: json['lastPurchase'] is String
          ? json['lastPurchase'] as String
          : 'any',
      purchasedCategoryCodes: _stringList(json['purchasedCategoryCodes']),
      createdBy: createdBy,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      updatedBy: updatedBy,
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final String visibility;
  final List<String> statuses;
  final List<String> stateCodes;
  final List<String> potentials;
  final String lastPurchase;
  final List<String> purchasedCategoryCodes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'visibility': visibility,
      'statuses': statuses,
      'stateCodes': stateCodes,
      'potentials': potentials,
      'lastPurchase': lastPurchase,
      'purchasedCategoryCodes': purchasedCategoryCodes,
      'createdBy': createdBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'updatedBy': updatedBy,
      'version': version,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return List<String>.unmodifiable(value.whereType<String>());
  }
}
