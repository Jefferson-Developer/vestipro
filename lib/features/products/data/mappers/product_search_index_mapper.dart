import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_custom_field_value.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/services/product_search_normalizer.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/sku.dart';
import 'product_mapper.dart';

@lazySingleton
final class ProductSearchIndexMapper {
  const ProductSearchIndexMapper(this._productMapper);

  final ProductMapper _productMapper;

  ProductSearchIndexTableCompanion toRow(Product product) {
    final now = DateTime.now().toUtc();
    return ProductSearchIndexTableCompanion.insert(
      productId: product.id,
      organizationId: product.organizationId,
      companyId: Value(product.companyId),
      sku: product.sku.value,
      reference: product.reference,
      name: product.name,
      shortDescription: Value(product.shortDescription),
      fullDescription: Value(product.fullDescription),
      brand: Value(product.brand),
      collectionId: Value(product.collectionId),
      seasonId: Value(product.seasonId),
      line: Value(product.line),
      categoryId: Value(product.categoryId),
      subcategoryId: Value(product.subcategoryId),
      gender: Value(
        product.gender == null
            ? null
            : _productMapper.genderToDto(product.gender!),
      ),
      targetAudience: Value(
        product.targetAudience == null
            ? null
            : _productMapper.targetAudienceToDto(product.targetAudience!),
      ),
      fabric: Value(product.fabric),
      composition: Value(product.composition),
      supplierId: Value(product.supplierId),
      ncm: Value(product.ncm),
      ean: Value(product.ean?.digits),
      tagsJson: jsonEncode(product.tags),
      status: _productMapper.statusToDto(product.status),
      launchDate: Value(product.launchDate),
      seoTitle: Value(product.seoTitle),
      seoDescription: Value(product.seoDescription),
      seoSlug: Value(product.seoSlug),
      mediaJson: jsonEncode(
        product.media.map(_mediaToJson).toList(growable: false),
      ),
      customFieldValuesJson: jsonEncode(
        product.customFieldValues
            .map(_customFieldValueToJson)
            .toList(growable: false),
      ),
      createdAt: product.createdAt,
      createdBy: product.createdBy,
      updatedAt: product.updatedAt,
      updatedBy: product.updatedBy,
      deletedAt: Value(product.deletedAt),
      version: product.version,
      syncStatus: _productMapper.syncStatusToDto(product.syncStatus),
      normalizedSearchText: ProductSearchNormalizer.searchTextForProduct(
        product,
      ),
      indexedAt: now,
    );
  }

  Product fromRow(ProductSearchIndexTableData row) {
    return Product(
      id: row.productId,
      organizationId: row.organizationId,
      companyId: row.companyId,
      sku: Sku.parse(row.sku),
      reference: row.reference,
      name: row.name,
      shortDescription: row.shortDescription,
      fullDescription: row.fullDescription,
      brand: row.brand,
      collectionId: row.collectionId,
      seasonId: row.seasonId,
      line: row.line,
      categoryId: row.categoryId,
      subcategoryId: row.subcategoryId,
      gender: row.gender == null
          ? null
          : _productMapper.genderToEntity(row.gender!),
      targetAudience: row.targetAudience == null
          ? null
          : _productMapper.targetAudienceToEntity(row.targetAudience!),
      fabric: row.fabric,
      composition: row.composition,
      supplierId: row.supplierId,
      ncm: row.ncm,
      ean: row.ean == null ? null : Ean.parse(row.ean!),
      tags: _stringList(row.tagsJson, 'tagsJson'),
      status: _productMapper.statusToEntity(row.status),
      launchDate: row.launchDate,
      seoTitle: row.seoTitle,
      seoDescription: row.seoDescription,
      seoSlug: row.seoSlug,
      media: _mediaFromJson(row.mediaJson),
      customFieldValues: _customFieldValuesFromJson(row.customFieldValuesJson),
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
      version: row.version,
      syncStatus: _productMapper.syncStatusToEntity(row.syncStatus),
    );
  }

  Map<String, dynamic> _mediaToJson(ProductMedia media) {
    return <String, dynamic>{
      'id': media.id,
      'type': _productMapper.mediaTypeToDto(media.type),
      'url': media.url,
      if (media.thumbnailUrl != null) 'thumbnailUrl': media.thumbnailUrl,
      'order': media.order,
      'principal': media.principal,
      if (media.colorId != null) 'colorId': media.colorId,
    };
  }

  List<ProductMedia> _mediaFromJson(String raw) {
    final decoded = _decodeList(raw, 'mediaJson');
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product search media payload.',
              code: 'invalid_product_search_index_payload',
            );
          }
          return ProductMedia(
            id: _requiredString(item, 'id'),
            type: _productMapper.mediaTypeToEntity(
              _requiredString(item, 'type'),
            ),
            url: _requiredString(item, 'url'),
            thumbnailUrl: _optionalString(item, 'thumbnailUrl'),
            order: _requiredInt(item, 'order'),
            principal: (item['principal'] as bool?) ?? false,
            colorId: _optionalString(item, 'colorId'),
          );
        })
        .toList(growable: false);
  }

  Map<String, dynamic> _customFieldValueToJson(ProductCustomFieldValue value) {
    return <String, dynamic>{
      'fieldDefinitionId': value.fieldDefinitionId,
      'value': value.value,
    };
  }

  List<ProductCustomFieldValue> _customFieldValuesFromJson(String raw) {
    final decoded = _decodeList(raw, 'customFieldValuesJson');
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product search custom field payload.',
              code: 'invalid_product_search_index_payload',
            );
          }
          return ProductCustomFieldValue(
            fieldDefinitionId: _requiredString(item, 'fieldDefinitionId'),
            value: item['value'],
          );
        })
        .toList(growable: false);
  }

  List<dynamic> _decodeList(String raw, String field) {
    final decoded = jsonDecode(raw);
    if (decoded is List<dynamic>) return decoded;
    throw ValidationException(
      'Invalid local product search index list.',
      code: 'invalid_product_search_index_payload',
      cause: field,
    );
  }

  List<String> _stringList(String raw, String field) {
    final decoded = _decodeList(raw, field);
    if (decoded.any((item) => item is! String)) {
      throw ValidationException(
        'Invalid local product search string list.',
        code: 'invalid_product_search_index_payload',
        cause: field,
      );
    }
    return List<String>.unmodifiable(decoded.cast<String>());
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local product search string field.',
      code: 'invalid_product_search_index_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local product search string field.',
      code: 'invalid_product_search_index_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local product search integer field.',
      code: 'invalid_product_search_index_payload',
      cause: field,
    );
  }
}
