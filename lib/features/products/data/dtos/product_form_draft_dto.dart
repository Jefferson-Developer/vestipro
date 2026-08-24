import '../../../../core/errors/errors.dart';

final class ProductFormDraftDto {
  const ProductFormDraftDto({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    this.productId,
    this.name,
    this.sku,
    this.reference,
    this.brand,
    this.categoryId,
    this.subcategoryId,
    this.collectionId,
    this.seasonId,
    this.line,
    this.gender,
    this.targetAudience,
    this.shortDescription,
    this.fullDescription,
    this.tags = const <String>[],
    this.fabric,
    this.composition,
    this.supplierId,
    this.ncm,
    this.ean,
    this.seoTitle,
    this.seoDescription,
    this.seoSlug,
    this.launchDate,
    required this.savedAt,
  });

  factory ProductFormDraftDto.fromJson(Map<String, dynamic> json) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final userId = json['userId'];
    final savedAt = json['savedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        userId is! String ||
        savedAt is! String) {
      throw const ValidationException(
        'Invalid product draft payload.',
        code: 'invalid_product_draft_payload',
      );
    }

    return ProductFormDraftDto(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      productId: _optionalString(json, 'productId'),
      name: _optionalString(json, 'name'),
      sku: _optionalString(json, 'sku'),
      reference: _optionalString(json, 'reference'),
      brand: _optionalString(json, 'brand'),
      categoryId: _optionalString(json, 'categoryId'),
      subcategoryId: _optionalString(json, 'subcategoryId'),
      collectionId: _optionalString(json, 'collectionId'),
      seasonId: _optionalString(json, 'seasonId'),
      line: _optionalString(json, 'line'),
      gender: _optionalString(json, 'gender'),
      targetAudience: _optionalString(json, 'targetAudience'),
      shortDescription: _optionalString(json, 'shortDescription'),
      fullDescription: _optionalString(json, 'fullDescription'),
      tags: _stringListFromJson(json['tags']),
      fabric: _optionalString(json, 'fabric'),
      composition: _optionalString(json, 'composition'),
      supplierId: _optionalString(json, 'supplierId'),
      ncm: _optionalString(json, 'ncm'),
      ean: _optionalString(json, 'ean'),
      seoTitle: _optionalString(json, 'seoTitle'),
      seoDescription: _optionalString(json, 'seoDescription'),
      seoSlug: _optionalString(json, 'seoSlug'),
      launchDate: _optionalString(json, 'launchDate') == null
          ? null
          : DateTime.parse(_optionalString(json, 'launchDate')!),
      savedAt: DateTime.parse(savedAt),
    );
  }

  final String organizationId;
  final String companyId;
  final String userId;
  final String? productId;
  final String? name;
  final String? sku;
  final String? reference;
  final String? brand;
  final String? categoryId;
  final String? subcategoryId;
  final String? collectionId;
  final String? seasonId;
  final String? line;
  final String? gender;
  final String? targetAudience;
  final String? shortDescription;
  final String? fullDescription;
  final List<String> tags;
  final String? fabric;
  final String? composition;
  final String? supplierId;
  final String? ncm;
  final String? ean;
  final String? seoTitle;
  final String? seoDescription;
  final String? seoSlug;
  final DateTime? launchDate;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'userId': userId,
      if (productId != null) 'productId': productId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (reference != null) 'reference': reference,
      if (brand != null) 'brand': brand,
      if (categoryId != null) 'categoryId': categoryId,
      if (subcategoryId != null) 'subcategoryId': subcategoryId,
      if (collectionId != null) 'collectionId': collectionId,
      if (seasonId != null) 'seasonId': seasonId,
      if (line != null) 'line': line,
      if (gender != null) 'gender': gender,
      if (targetAudience != null) 'targetAudience': targetAudience,
      if (shortDescription != null) 'shortDescription': shortDescription,
      if (fullDescription != null) 'fullDescription': fullDescription,
      if (tags.isNotEmpty) 'tags': tags,
      if (fabric != null) 'fabric': fabric,
      if (composition != null) 'composition': composition,
      if (supplierId != null) 'supplierId': supplierId,
      if (ncm != null) 'ncm': ncm,
      if (ean != null) 'ean': ean,
      if (seoTitle != null) 'seoTitle': seoTitle,
      if (seoDescription != null) 'seoDescription': seoDescription,
      if (seoSlug != null) 'seoSlug': seoSlug,
      if (launchDate != null)
        'launchDate': launchDate!.toUtc().toIso8601String(),
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw ValidationException(
    'Invalid product draft string field.',
    code: 'invalid_product_draft_payload',
    cause: field,
  );
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid product draft tags payload.',
      code: 'invalid_product_draft_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}
