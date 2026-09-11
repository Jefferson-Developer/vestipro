import '../../../../core/errors/errors.dart';

/// Firestore/local-embedded shape of an `AssortmentRule` (TASK-207) —
/// nested inside [CommercialPackDto], never its own top-level document/
/// collection, same precedent [PackComponentDto] already follows.
final class AssortmentRuleDto {
  const AssortmentRuleDto({
    required this.id,
    required this.type,
    this.colorId,
    this.sizeId,
    this.minPercentage,
    this.minQuantity,
  });

  factory AssortmentRuleDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final colorId = json['colorId'];
    final sizeId = json['sizeId'];
    final minPercentage = json['minPercentage'];
    final minQuantity = json['minQuantity'];

    if (id is! String ||
        type is! String ||
        (colorId != null && colorId is! String) ||
        (sizeId != null && sizeId is! String) ||
        (minPercentage != null && minPercentage is! num) ||
        (minQuantity != null && minQuantity is! int)) {
      throw const ValidationException(
        'Invalid assortment rule payload.',
        code: 'invalid_commercial_pack_payload',
      );
    }

    return AssortmentRuleDto(
      id: id,
      type: type,
      colorId: colorId as String?,
      sizeId: sizeId as String?,
      minPercentage: (minPercentage as num?)?.toDouble(),
      minQuantity: minQuantity as int?,
    );
  }

  final String id;
  final String type;
  final String? colorId;
  final String? sizeId;
  final double? minPercentage;
  final int? minQuantity;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'colorId': colorId,
      'sizeId': sizeId,
      'minPercentage': minPercentage,
      'minQuantity': minQuantity,
    };
  }
}
