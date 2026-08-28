import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class VariantStockBalanceDto {
  const VariantStockBalanceDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.productId,
    required this.variantId,
    required this.warehouseId,
    required this.physicalQuantity,
    required this.reservedQuantity,
    required this.blockedQuantity,
    required this.updatedAt,
    required this.updatedBy,
    required this.lastSource,
    required this.version,
  });

  factory VariantStockBalanceDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final productId = json['productId'];
    final variantId = json['variantId'];
    final warehouseId = json['warehouseId'];
    final physicalQuantity = json['physicalQuantity'];
    final reservedQuantity = json['reservedQuantity'];
    final blockedQuantity = json['blockedQuantity'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final lastSource = json['lastSource'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        productId is! String ||
        variantId is! String ||
        warehouseId is! String ||
        physicalQuantity is! int ||
        reservedQuantity is! int ||
        blockedQuantity is! int ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        lastSource is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid variant stock balance payload.',
        code: 'invalid_variant_stock_balance_payload',
      );
    }

    return VariantStockBalanceDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      variantId: variantId,
      warehouseId: warehouseId,
      physicalQuantity: physicalQuantity,
      reservedQuantity: reservedQuantity,
      blockedQuantity: blockedQuantity,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      lastSource: lastSource,
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String productId;
  final String variantId;
  final String warehouseId;
  final int physicalQuantity;
  final int reservedQuantity;
  final int blockedQuantity;
  final DateTime updatedAt;
  final String updatedBy;
  final String lastSource;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'productId': productId,
      'variantId': variantId,
      'warehouseId': warehouseId,
      'physicalQuantity': physicalQuantity,
      'reservedQuantity': reservedQuantity,
      'blockedQuantity': blockedQuantity,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'lastSource': lastSource,
      'version': version,
    };
  }
}
