import '../../../../core/errors/errors.dart';

final class BuyerCollaborationPriceDriftDto {
  const BuyerCollaborationPriceDriftDto({
    required this.itemId,
    required this.variantId,
    required this.approvedUnitPrice,
    this.currentUnitPrice,
  });

  factory BuyerCollaborationPriceDriftDto.fromJson(Map<String, dynamic> json) {
    final itemId = json['itemId'];
    final variantId = json['variantId'];
    final approvedUnitPrice = json['approvedUnitPrice'];
    final currentUnitPrice = json['currentUnitPrice'];
    if (itemId is! String ||
        variantId is! String ||
        approvedUnitPrice is! num ||
        (currentUnitPrice != null && currentUnitPrice is! num)) {
      throw const ValidationException(
        'Invalid buyer collaboration price drift payload.',
        code: 'invalid_buyer_collaboration_price_drift_payload',
      );
    }
    return BuyerCollaborationPriceDriftDto(
      itemId: itemId,
      variantId: variantId,
      approvedUnitPrice: approvedUnitPrice.toDouble(),
      currentUnitPrice: (currentUnitPrice as num?)?.toDouble(),
    );
  }

  final String itemId;
  final String variantId;
  final double approvedUnitPrice;
  final double? currentUnitPrice;
}

final class BuyerCollaborationConversionResultDto {
  const BuyerCollaborationConversionResultDto({
    required this.converted,
    this.orderId,
    this.priceDrift = const <BuyerCollaborationPriceDriftDto>[],
  });

  factory BuyerCollaborationConversionResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final converted = json['converted'];
    final orderId = json['orderId'];
    final rawPriceDrift = json['priceDrift'];
    if (converted is! bool || (orderId != null && orderId is! String)) {
      throw const ValidationException(
        'Invalid buyer collaboration conversion result payload.',
        code: 'invalid_buyer_collaboration_conversion_result_payload',
      );
    }
    final priceDrift = rawPriceDrift is List<dynamic>
        ? rawPriceDrift
              .map(
                (item) => BuyerCollaborationPriceDriftDto.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false)
        : const <BuyerCollaborationPriceDriftDto>[];
    return BuyerCollaborationConversionResultDto(
      converted: converted,
      orderId: orderId as String?,
      priceDrift: priceDrift,
    );
  }

  final bool converted;
  final String? orderId;
  final List<BuyerCollaborationPriceDriftDto> priceDrift;
}
