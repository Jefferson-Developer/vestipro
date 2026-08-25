import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a sellable product/color/size variant.
///
/// The document id is the variant id; `organizationId` is also duplicated in
/// the payload so Security Rules can verify tenant scope from document data.
final class ProductVariantDto {
  const ProductVariantDto({
    required this.id,
    required this.organizationId,
    required this.productId,
    required this.colorId,
    required this.sizeGridTemplateId,
    required this.sizeId,
    required this.sku,
    this.ean,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
    required this.syncStatus,
  });

  factory ProductVariantDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final productId = json['productId'];
    final colorId = json['colorId'];
    final sizeGridTemplateId = json['sizeGridTemplateId'];
    final sizeId = json['sizeId'];
    final sku = json['sku'];
    final ean = json['ean'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        productId is! String ||
        colorId is! String ||
        sizeGridTemplateId is! String ||
        sizeId is! String ||
        sku is! String ||
        (ean != null && ean is! String) ||
        status is! String ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid product variant payload.',
        code: 'invalid_product_variant_payload',
      );
    }

    return ProductVariantDto(
      id: id,
      organizationId: organizationId,
      productId: productId,
      colorId: colorId,
      sizeGridTemplateId: sizeGridTemplateId,
      sizeId: sizeId,
      sku: sku,
      ean: ean as String?,
      status: status,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String productId;
  final String colorId;
  final String sizeGridTemplateId;
  final String sizeId;
  final String sku;
  final String? ean;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'productId': productId,
      'colorId': colorId,
      'sizeGridTemplateId': sizeGridTemplateId,
      'sizeId': sizeId,
      'sku': sku,
      'ean': ean,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}
