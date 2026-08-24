import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_custom_field_value.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/sku.dart';
import '../mappers/product_mapper.dart';

/// Local product store used until the remote/outbox sync implementation
/// exists (TASK-065; same rationale as `SharedPreferencesCustomerRepository`,
/// TASK-048/049): every create/update mutation stays durable with
/// `ProductSyncStatus.pending` and SKU uniqueness is checked locally, scoped
/// to the active Organization.
///
/// Serializes with hand-rolled JSON (dates as ISO-8601 strings), not
/// `ProductDto`/`ProductMapper.toDto`/`toEntity` directly: `ProductDto` is
/// shaped for Firestore's `Timestamp`, which `jsonEncode`/`jsonDecode` cannot
/// round-trip — the same reason `SharedPreferencesCustomerRepository` keeps
/// its own `_toJson`/`_fromJson` instead of reusing `CustomerDto`. Only
/// [ProductMapper]'s enum<->string helpers are reused here.
@LazySingleton(as: ProductRepository)
final class SharedPreferencesProductRepository implements ProductRepository {
  const SharedPreferencesProductRepository(this._mapper);

  final ProductMapper _mapper;

  String _keyFor(String organizationId) => 'products_$organizationId';

  /// Key `SharedPreferencesCategoryRepository.hasProducts` reads from to
  /// block deleting a `Category` still referenced by a Product, the same
  /// decoupled-usage-index pattern `SharedPreferencesCollectionRepository`
  /// already maintains for Season usage.
  String _categoryUsageKeyFor(String organizationId) =>
      'category_product_usage_$organizationId';

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async {
    try {
      final products = await _load(organizationId);
      final excludingId = excludingProductId?.trim();
      return AppSuccess<bool>(
        products.any(
          (product) =>
              product.deletedAt == null &&
              product.sku == sku &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  product.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product SKU locally.',
          code: 'product_local_exists_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    try {
      final products = await _load(product.organizationId);
      if (products.any(
        (existing) =>
            existing.deletedAt == null &&
            existing.sku == product.sku &&
            existing.id != product.id,
      )) {
        return const AppFailure<Product>(
          ConflictFailure(
            'Product SKU already exists in this organization.',
            code: 'product_sku_already_exists',
          ),
        );
      }

      final next = <Product>[
        ...products.where((existing) => existing.id != product.id),
        product,
      ];
      await _save(product.organizationId, next);
      await _syncCategoryUsage(product.organizationId, next);
      return AppSuccess<Product>(product);
    } catch (exception) {
      return AppFailure<Product>(
        UnexpectedFailure(
          'Unexpected error saving product locally.',
          code: 'product_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    try {
      final products = await _load(product.organizationId);
      final index = products.indexWhere(
        (existing) => existing.id == product.id,
      );
      if (index == -1) {
        return const AppFailure<Product>(
          NotFoundFailure('Product not found.', code: 'product_not_found'),
        );
      }

      final next = List<Product>.of(products)..[index] = product;
      await _save(product.organizationId, next);
      await _syncCategoryUsage(product.organizationId, next);
      return AppSuccess<Product>(product);
    } catch (exception) {
      return AppFailure<Product>(
        UnexpectedFailure(
          'Unexpected error updating product locally.',
          code: 'product_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final products = await _load(organizationId);
      for (final product in products) {
        if (product.id == id) return AppSuccess<Product>(product);
      }
      return const AppFailure<Product>(
        NotFoundFailure('Product not found.', code: 'product_not_found'),
      );
    } catch (exception) {
      return AppFailure<Product>(
        UnexpectedFailure(
          'Unexpected error loading product locally.',
          code: 'product_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    try {
      final wanted = ids.toSet();
      final products = await _load(organizationId);
      return AppSuccess<List<Product>>(
        products
            .where((product) => wanted.contains(product.id))
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Product>>(
        UnexpectedFailure(
          'Unexpected error loading products locally.',
          code: 'product_local_get_by_ids_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<void> _syncCategoryUsage(
    String organizationId,
    List<Product> products,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryIds = products
        .where((product) => product.deletedAt == null)
        .expand(
          (product) => <String?>[product.categoryId, product.subcategoryId],
        )
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    await prefs.setStringList(
      _categoryUsageKeyFor(organizationId),
      categoryIds,
    );
  }

  Future<List<Product>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Product>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product list.',
        code: 'invalid_product_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product payload.',
              code: 'invalid_product_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(products.map(_toJson).toList(growable: false)),
    );
  }

  Product _fromJson(Map<String, dynamic> json) {
    return Product(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _optionalString(json, 'companyId'),
      sku: Sku.parse(_requiredString(json, 'sku')),
      reference: _requiredString(json, 'reference'),
      name: _requiredString(json, 'name'),
      shortDescription: _optionalString(json, 'shortDescription'),
      fullDescription: _optionalString(json, 'fullDescription'),
      brand: _optionalString(json, 'brand'),
      collectionId: _optionalString(json, 'collectionId'),
      seasonId: _optionalString(json, 'seasonId'),
      line: _optionalString(json, 'line'),
      categoryId: _optionalString(json, 'categoryId'),
      subcategoryId: _optionalString(json, 'subcategoryId'),
      gender: _optionalString(json, 'gender') == null
          ? null
          : _mapper.genderToEntity(_requiredString(json, 'gender')),
      targetAudience: _optionalString(json, 'targetAudience') == null
          ? null
          : _mapper.targetAudienceToEntity(
              _requiredString(json, 'targetAudience'),
            ),
      fabric: _optionalString(json, 'fabric'),
      composition: _optionalString(json, 'composition'),
      supplierId: _optionalString(json, 'supplierId'),
      ncm: _optionalString(json, 'ncm'),
      ean: _optionalString(json, 'ean') == null
          ? null
          : Ean.parse(_requiredString(json, 'ean')),
      tags: _stringList(json['tags']),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      launchDate: _optionalDate(json, 'launchDate'),
      seoTitle: _optionalString(json, 'seoTitle'),
      seoDescription: _optionalString(json, 'seoDescription'),
      seoSlug: _optionalString(json, 'seoSlug'),
      media: _mediaFromJson(json['media']),
      customFieldValues: _customFieldValuesFromJson(json['customFieldValues']),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(Product product) {
    return <String, dynamic>{
      'id': product.id,
      'organizationId': product.organizationId,
      if (product.companyId != null) 'companyId': product.companyId,
      'sku': product.sku.value,
      'reference': product.reference,
      'name': product.name,
      if (product.shortDescription != null)
        'shortDescription': product.shortDescription,
      if (product.fullDescription != null)
        'fullDescription': product.fullDescription,
      if (product.brand != null) 'brand': product.brand,
      if (product.collectionId != null) 'collectionId': product.collectionId,
      if (product.seasonId != null) 'seasonId': product.seasonId,
      if (product.line != null) 'line': product.line,
      if (product.categoryId != null) 'categoryId': product.categoryId,
      if (product.subcategoryId != null) 'subcategoryId': product.subcategoryId,
      if (product.gender != null)
        'gender': _mapper.genderToDto(product.gender!),
      if (product.targetAudience != null)
        'targetAudience': _mapper.targetAudienceToDto(product.targetAudience!),
      if (product.fabric != null) 'fabric': product.fabric,
      if (product.composition != null) 'composition': product.composition,
      if (product.supplierId != null) 'supplierId': product.supplierId,
      if (product.ncm != null) 'ncm': product.ncm,
      if (product.ean != null) 'ean': product.ean!.digits,
      if (product.tags.isNotEmpty) 'tags': product.tags,
      'status': _mapper.statusToDto(product.status),
      if (product.launchDate != null)
        'launchDate': product.launchDate!.toUtc().toIso8601String(),
      if (product.seoTitle != null) 'seoTitle': product.seoTitle,
      if (product.seoDescription != null)
        'seoDescription': product.seoDescription,
      if (product.seoSlug != null) 'seoSlug': product.seoSlug,
      if (product.media.isNotEmpty)
        'media': product.media.map(_mediaToJson).toList(growable: false),
      if (product.customFieldValues.isNotEmpty)
        'customFieldValues': product.customFieldValues
            .map(_customFieldValueToJson)
            .toList(growable: false),
      'createdAt': product.createdAt.toUtc().toIso8601String(),
      'createdBy': product.createdBy,
      'updatedAt': product.updatedAt.toUtc().toIso8601String(),
      'updatedBy': product.updatedBy,
      if (product.deletedAt != null)
        'deletedAt': product.deletedAt!.toUtc().toIso8601String(),
      'version': product.version,
      'syncStatus': _mapper.syncStatusToDto(product.syncStatus),
    };
  }

  List<ProductMedia> _mediaFromJson(Object? value) {
    if (value == null) return const <ProductMedia>[];
    if (value is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product media list.',
        code: 'invalid_product_local_payload',
      );
    }
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product media payload.',
              code: 'invalid_product_local_payload',
            );
          }
          return ProductMedia(
            id: _requiredString(item, 'id'),
            type: _mapper.mediaTypeToEntity(_requiredString(item, 'type')),
            url: _requiredString(item, 'url'),
            thumbnailUrl: _optionalString(item, 'thumbnailUrl'),
            order: _requiredInt(item, 'order'),
            principal: (item['principal'] as bool?) ?? false,
            colorId: _optionalString(item, 'colorId'),
          );
        })
        .toList(growable: false);
  }

  Map<String, dynamic> _mediaToJson(ProductMedia media) {
    return <String, dynamic>{
      'id': media.id,
      'type': _mapper.mediaTypeToDto(media.type),
      'url': media.url,
      if (media.thumbnailUrl != null) 'thumbnailUrl': media.thumbnailUrl,
      'order': media.order,
      'principal': media.principal,
      if (media.colorId != null) 'colorId': media.colorId,
    };
  }

  List<ProductCustomFieldValue> _customFieldValuesFromJson(Object? value) {
    if (value == null) return const <ProductCustomFieldValue>[];
    if (value is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product custom field values.',
        code: 'invalid_product_local_payload',
      );
    }
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product custom field value payload.',
              code: 'invalid_product_local_payload',
            );
          }
          return ProductCustomFieldValue(
            fieldDefinitionId: _requiredString(item, 'fieldDefinitionId'),
            value: item['value'],
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

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local product string field.',
      code: 'invalid_product_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local product string field.',
      code: 'invalid_product_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : DateTime.parse(value).toUtc();
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local product integer field.',
      code: 'invalid_product_local_payload',
      cause: field,
    );
  }

  List<String> _stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is! List<dynamic> || value.any((item) => item is! String)) {
      throw const ValidationException(
        'Invalid local product string list.',
        code: 'invalid_product_local_payload',
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}
