import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/repositories/product_variant_repository.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/product_sync_status.dart';
import '../../domain/value_objects/product_variant_status.dart';
import '../../domain/value_objects/sku.dart';

@LazySingleton(as: ProductVariantRepository)
final class SharedPreferencesProductVariantRepository
    implements ProductVariantRepository {
  const SharedPreferencesProductVariantRepository();

  String _keyFor(String organizationId) => 'product_variants_$organizationId';

  String _orderUsageKeyFor(String organizationId) =>
      'order_variant_usage_$organizationId';

  String _sizeUsageKeyFor(String organizationId) =>
      'size_grid_variant_usage_$organizationId';

  @override
  Future<AppResult<ProductVariant>> create({
    required ProductVariant variant,
  }) async {
    try {
      final variants = await _load(variant.organizationId);
      final next = <ProductVariant>[
        ...variants.where((existing) => existing.id != variant.id),
        variant,
      ];
      await _save(variant.organizationId, next);
      return AppSuccess<ProductVariant>(variant);
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error saving product variant locally.',
          code: 'product_variant_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductVariant>> update({
    required ProductVariant variant,
  }) async {
    try {
      final variants = await _load(variant.organizationId);
      final index = variants.indexWhere(
        (existing) => existing.id == variant.id,
      );
      if (index == -1) {
        return const AppFailure<ProductVariant>(
          NotFoundFailure(
            'Product variant not found.',
            code: 'product_variant_not_found',
          ),
        );
      }
      final next = List<ProductVariant>.of(variants)..[index] = variant;
      await _save(variant.organizationId, next);
      return AppSuccess<ProductVariant>(variant);
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error updating product variant locally.',
          code: 'product_variant_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final variants = await _load(organizationId);
      return AppSuccess<List<ProductVariant>>(variants..sort(_compareVariants));
    } catch (exception) {
      return AppFailure<List<ProductVariant>>(
        UnexpectedFailure(
          'Unexpected error listing product variants locally.',
          code: 'product_variant_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final variants = await _load(organizationId);
      return AppSuccess<List<ProductVariant>>(
        variants
            .where((variant) => variant.productId == productId)
            .toList(growable: false)
          ..sort(_compareVariants),
      );
    } catch (exception) {
      return AppFailure<List<ProductVariant>>(
        UnexpectedFailure(
          'Unexpected error listing product variants locally.',
          code: 'product_variant_local_product_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final variants = await _load(organizationId);
      for (final variant in variants) {
        if (variant.id == id) return AppSuccess<ProductVariant>(variant);
      }
      return const AppFailure<ProductVariant>(
        NotFoundFailure(
          'Product variant not found.',
          code: 'product_variant_not_found',
        ),
      );
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error loading product variant locally.',
          code: 'product_variant_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  }) async {
    try {
      final variants = await _load(organizationId);
      final excludingId = excludingVariantId?.trim();
      return AppSuccess<bool>(
        variants.any(
          (variant) =>
              variant.isActive &&
              variant.sku == sku &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  variant.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product variant SKU locally.',
          code: 'product_variant_local_sku_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  }) async {
    try {
      final variants = await _load(organizationId);
      final excludingId = excludingVariantId?.trim();
      return AppSuccess<bool>(
        variants.any(
          (variant) =>
              variant.isActive &&
              variant.ean == ean &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  variant.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product variant EAN locally.',
          code: 'product_variant_local_ean_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usage = prefs.getStringList(_orderUsageKeyFor(organizationId));
      return AppSuccess<bool>(usage?.contains(variantId) ?? false);
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product variant order usage locally.',
          code: 'product_variant_local_order_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<ProductVariant>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return <ProductVariant>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product variant list.',
        code: 'invalid_product_variant_local_list',
      );
    }
    return decoded.map(_fromDynamicJson).toList(growable: true);
  }

  Future<void> _save(
    String organizationId,
    List<ProductVariant> variants,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(variants.map(_toJson).toList(growable: false)),
    );
    await prefs.setStringList(
      _sizeUsageKeyFor(organizationId),
      variants
          .where((variant) => variant.isActive)
          .map((variant) => '${variant.sizeGridTemplateId}|${variant.sizeId}')
          .toSet()
          .toList(growable: false),
    );
  }

  ProductVariant _fromDynamicJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local product variant payload.',
        code: 'invalid_product_variant_local_payload',
      );
    }
    return ProductVariant(
      id: _requiredString(value, 'id'),
      organizationId: _requiredString(value, 'organizationId'),
      productId: _requiredString(value, 'productId'),
      colorId: _requiredString(value, 'colorId'),
      sizeGridTemplateId: _requiredString(value, 'sizeGridTemplateId'),
      sizeId: _requiredString(value, 'sizeId'),
      sku: Sku.parse(_requiredString(value, 'sku')),
      ean: _optionalString(value, 'ean') == null
          ? null
          : Ean.parse(_requiredString(value, 'ean')),
      status: _statusFromJson(_requiredString(value, 'status')),
      createdAt: _requiredDate(value, 'createdAt'),
      createdBy: _requiredString(value, 'createdBy'),
      updatedAt: _requiredDate(value, 'updatedAt'),
      updatedBy: _requiredString(value, 'updatedBy'),
      version: _requiredInt(value, 'version'),
      syncStatus: _syncStatusFromJson(_requiredString(value, 'syncStatus')),
    );
  }

  Map<String, dynamic> _toJson(ProductVariant variant) {
    return <String, dynamic>{
      'id': variant.id,
      'organizationId': variant.organizationId,
      'productId': variant.productId,
      'colorId': variant.colorId,
      'sizeGridTemplateId': variant.sizeGridTemplateId,
      'sizeId': variant.sizeId,
      'sku': variant.sku.value,
      if (variant.ean != null) 'ean': variant.ean!.digits,
      'status': _statusToJson(variant.status),
      'createdAt': variant.createdAt.toUtc().toIso8601String(),
      'createdBy': variant.createdBy,
      'updatedAt': variant.updatedAt.toUtc().toIso8601String(),
      'updatedBy': variant.updatedBy,
      'version': variant.version,
      'syncStatus': _syncStatusToJson(variant.syncStatus),
    };
  }

  ProductVariantStatus _statusFromJson(String value) {
    return switch (value) {
      'active' => ProductVariantStatus.active,
      'inactive' => ProductVariantStatus.inactive,
      _ => throw ValidationException(
        'Invalid product variant status.',
        code: 'invalid_product_variant_status',
        cause: value,
      ),
    };
  }

  String _statusToJson(ProductVariantStatus status) {
    return switch (status) {
      ProductVariantStatus.active => 'active',
      ProductVariantStatus.inactive => 'inactive',
    };
  }

  ProductSyncStatus _syncStatusFromJson(String value) {
    return switch (value) {
      'pending' => ProductSyncStatus.pending,
      'syncing' => ProductSyncStatus.syncing,
      'synced' => ProductSyncStatus.synced,
      'failed' => ProductSyncStatus.failed,
      'conflict' => ProductSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid product variant sync status.',
        code: 'invalid_product_variant_sync_status',
        cause: value,
      ),
    };
  }

  String _syncStatusToJson(ProductSyncStatus status) {
    return switch (status) {
      ProductSyncStatus.pending => 'pending',
      ProductSyncStatus.syncing => 'syncing',
      ProductSyncStatus.synced => 'synced',
      ProductSyncStatus.failed => 'failed',
      ProductSyncStatus.conflict => 'conflict',
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local product variant string field.',
      code: 'invalid_product_variant_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local product variant string field.',
      code: 'invalid_product_variant_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local product variant integer field.',
      code: 'invalid_product_variant_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  int _compareVariants(ProductVariant a, ProductVariant b) {
    final byProduct = a.productId.compareTo(b.productId);
    if (byProduct != 0) return byProduct;
    final byColor = a.colorId.compareTo(b.colorId);
    if (byColor != 0) return byColor;
    return a.sizeId.compareTo(b.sizeId);
  }
}
