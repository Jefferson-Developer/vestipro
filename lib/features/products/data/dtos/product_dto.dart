import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a Product scoped by organization.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] is duplicated in the payload so Security Rules
/// and queries can validate tenant scope without trusting a client value.
final class ProductDto {
  const ProductDto({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.sku,
    required this.reference,
    required this.name,
    this.shortDescription,
    this.fullDescription,
    this.brand,
    this.collectionId,
    this.seasonId,
    this.line,
    this.categoryId,
    this.subcategoryId,
    this.gender,
    this.targetAudience,
    this.fabric,
    this.composition,
    this.supplierId,
    this.ncm,
    this.ean,
    this.tags = const <String>[],
    required this.status,
    this.launchDate,
    this.seoTitle,
    this.seoDescription,
    this.seoSlug,
    this.photoUrls = const <String>[],
    this.videoUrls = const <String>[],
    this.customFieldValues = const <ProductCustomFieldValueDto>[],
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final sku = json['sku'];
    final reference = json['reference'];
    final name = json['name'];
    final shortDescription = json['shortDescription'];
    final fullDescription = json['fullDescription'];
    final brand = json['brand'];
    final collectionId = json['collectionId'];
    final seasonId = json['seasonId'];
    final line = json['line'];
    final categoryId = json['categoryId'];
    final subcategoryId = json['subcategoryId'];
    final gender = json['gender'];
    final targetAudience = json['targetAudience'];
    final fabric = json['fabric'];
    final composition = json['composition'];
    final supplierId = json['supplierId'];
    final ncm = json['ncm'];
    final ean = json['ean'];
    final status = json['status'];
    final launchDate = json['launchDate'];
    final seoTitle = json['seoTitle'];
    final seoDescription = json['seoDescription'];
    final seoSlug = json['seoSlug'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        (companyId != null && companyId is! String) ||
        sku is! String ||
        reference is! String ||
        name is! String ||
        (shortDescription != null && shortDescription is! String) ||
        (fullDescription != null && fullDescription is! String) ||
        (brand != null && brand is! String) ||
        (collectionId != null && collectionId is! String) ||
        (seasonId != null && seasonId is! String) ||
        (line != null && line is! String) ||
        (categoryId != null && categoryId is! String) ||
        (subcategoryId != null && subcategoryId is! String) ||
        (gender != null && gender is! String) ||
        (targetAudience != null && targetAudience is! String) ||
        (fabric != null && fabric is! String) ||
        (composition != null && composition is! String) ||
        (supplierId != null && supplierId is! String) ||
        (ncm != null && ncm is! String) ||
        (ean != null && ean is! String) ||
        status is! String ||
        (launchDate != null && launchDate is! Timestamp) ||
        (seoTitle != null && seoTitle is! String) ||
        (seoDescription != null && seoDescription is! String) ||
        (seoSlug != null && seoSlug is! String) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid product payload.',
        code: 'invalid_product_payload',
      );
    }

    return ProductDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId as String?,
      sku: sku,
      reference: reference,
      name: name,
      shortDescription: shortDescription as String?,
      fullDescription: fullDescription as String?,
      brand: brand as String?,
      collectionId: collectionId as String?,
      seasonId: seasonId as String?,
      line: line as String?,
      categoryId: categoryId as String?,
      subcategoryId: subcategoryId as String?,
      gender: gender as String?,
      targetAudience: targetAudience as String?,
      fabric: fabric as String?,
      composition: composition as String?,
      supplierId: supplierId as String?,
      ncm: ncm as String?,
      ean: ean as String?,
      tags: _stringListFromJson(json['tags'], field: 'tags'),
      status: status,
      launchDate: (launchDate as Timestamp?)?.toDate(),
      seoTitle: seoTitle as String?,
      seoDescription: seoDescription as String?,
      seoSlug: seoSlug as String?,
      photoUrls: _stringListFromJson(json['photoUrls'], field: 'photoUrls'),
      videoUrls: _stringListFromJson(json['videoUrls'], field: 'videoUrls'),
      customFieldValues: _customFieldValueDtosFromJson(
        json['customFieldValues'],
      ),
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String? companyId;
  final String sku;
  final String reference;
  final String name;
  final String? shortDescription;
  final String? fullDescription;
  final String? brand;
  final String? collectionId;
  final String? seasonId;
  final String? line;
  final String? categoryId;
  final String? subcategoryId;
  final String? gender;
  final String? targetAudience;
  final String? fabric;
  final String? composition;
  final String? supplierId;
  final String? ncm;
  final String? ean;
  final List<String> tags;
  final String status;
  final DateTime? launchDate;
  final String? seoTitle;
  final String? seoDescription;
  final String? seoSlug;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final List<ProductCustomFieldValueDto> customFieldValues;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'sku': sku,
      'reference': reference,
      'name': name,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'brand': brand,
      'collectionId': collectionId,
      'seasonId': seasonId,
      'line': line,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'gender': gender,
      'targetAudience': targetAudience,
      'fabric': fabric,
      'composition': composition,
      'supplierId': supplierId,
      'ncm': ncm,
      'ean': ean,
      'tags': tags,
      'status': status,
      'launchDate': launchDate == null ? null : Timestamp.fromDate(launchDate!),
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'seoSlug': seoSlug,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'customFieldValues': customFieldValues
          .map((value) => value.toJson())
          .toList(growable: false),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}

/// Firestore/embedded shape of a single Product custom field value, linking
/// back to its `ProductCustomFieldDefinition` by [fieldDefinitionId].
final class ProductCustomFieldValueDto {
  const ProductCustomFieldValueDto({
    required this.fieldDefinitionId,
    required this.value,
  });

  factory ProductCustomFieldValueDto.fromJson(Map<String, dynamic> json) {
    final fieldDefinitionId = json['fieldDefinitionId'];
    if (fieldDefinitionId is! String) {
      throw const ValidationException(
        'Invalid product custom field value payload.',
        code: 'invalid_product_payload',
      );
    }
    return ProductCustomFieldValueDto(
      fieldDefinitionId: fieldDefinitionId,
      value: json['value'],
    );
  }

  final String fieldDefinitionId;
  final Object? value;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fieldDefinitionId': fieldDefinitionId,
      'value': value,
    };
  }
}

List<String> _stringListFromJson(Object? value, {required String field}) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid product payload.',
      code: 'invalid_product_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}

List<ProductCustomFieldValueDto> _customFieldValueDtosFromJson(Object? value) {
  if (value == null) return const <ProductCustomFieldValueDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid product custom field values.',
      code: 'invalid_product_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid product custom field value payload.',
            code: 'invalid_product_payload',
          );
        }
        return ProductCustomFieldValueDto.fromJson(item);
      })
      .toList(growable: false);
}
