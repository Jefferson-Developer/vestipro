import '../../../../core/errors/errors.dart';

/// Firestore/local-embedded shape of a `PackComponent` (TASK-207) — nested
/// inside [CommercialPackDto], never its own top-level document/collection,
/// same precedent `OrderItemDto` already follows for `OrderDto`.
final class PackComponentDto {
  const PackComponentDto({
    required this.id,
    required this.scopeType,
    required this.scopeReferenceId,
    required this.compositionType,
    this.quantity,
    this.minQuantity,
    this.maxQuantity,
    this.proportion,
    required this.isBonusItem,
  });

  factory PackComponentDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final scopeType = json['scopeType'];
    final scopeReferenceId = json['scopeReferenceId'];
    final compositionType = json['compositionType'];
    final quantity = json['quantity'];
    final minQuantity = json['minQuantity'];
    final maxQuantity = json['maxQuantity'];
    final proportion = json['proportion'];
    final isBonusItem = json['isBonusItem'];

    if (id is! String ||
        scopeType is! String ||
        scopeReferenceId is! String ||
        compositionType is! String ||
        (quantity != null && quantity is! int) ||
        (minQuantity != null && minQuantity is! int) ||
        (maxQuantity != null && maxQuantity is! int) ||
        (proportion != null && proportion is! num) ||
        isBonusItem is! bool) {
      throw const ValidationException(
        'Invalid pack component payload.',
        code: 'invalid_commercial_pack_payload',
      );
    }

    return PackComponentDto(
      id: id,
      scopeType: scopeType,
      scopeReferenceId: scopeReferenceId,
      compositionType: compositionType,
      quantity: quantity as int?,
      minQuantity: minQuantity as int?,
      maxQuantity: maxQuantity as int?,
      proportion: (proportion as num?)?.toDouble(),
      isBonusItem: isBonusItem,
    );
  }

  final String id;
  final String scopeType;
  final String scopeReferenceId;
  final String compositionType;
  final int? quantity;
  final int? minQuantity;
  final int? maxQuantity;
  final double? proportion;
  final bool isBonusItem;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'scopeType': scopeType,
      'scopeReferenceId': scopeReferenceId,
      'compositionType': compositionType,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'proportion': proportion,
      'isBonusItem': isBonusItem,
    };
  }
}
