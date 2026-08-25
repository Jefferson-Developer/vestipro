import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/repositories/product_color_repository.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/hex_color.dart';
import '../../domain/value_objects/product_color_status.dart';
import '../../domain/value_objects/product_sync_status.dart';

@LazySingleton(as: ProductColorRepository)
final class SharedPreferencesProductColorRepository
    implements ProductColorRepository {
  const SharedPreferencesProductColorRepository();

  String _keyFor(String organizationId) => 'product_colors_$organizationId';

  @override
  Future<AppResult<ProductColor>> create({required ProductColor color}) async {
    try {
      final colors = await _load(color.organizationId);
      final next = <ProductColor>[
        ...colors.where((existing) => existing.id != color.id),
        color,
      ];
      await _save(color.organizationId, next);
      return AppSuccess<ProductColor>(color);
    } catch (exception) {
      return AppFailure<ProductColor>(
        UnexpectedFailure(
          'Unexpected error saving product color locally.',
          code: 'product_color_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductColor>> update({required ProductColor color}) async {
    try {
      final colors = await _load(color.organizationId);
      final index = colors.indexWhere((existing) => existing.id == color.id);
      if (index == -1) {
        return const AppFailure<ProductColor>(
          NotFoundFailure('Product color not found.', code: 'color_not_found'),
        );
      }
      final next = List<ProductColor>.of(colors)..[index] = color;
      await _save(color.organizationId, next);
      return AppSuccess<ProductColor>(color);
    } catch (exception) {
      return AppFailure<ProductColor>(
        UnexpectedFailure(
          'Unexpected error updating product color locally.',
          code: 'product_color_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductColor>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final colors = await _load(organizationId);
      return AppSuccess<List<ProductColor>>(
        colors.where((color) => color.deletedAt == null).toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
    } catch (exception) {
      return AppFailure<List<ProductColor>>(
        UnexpectedFailure(
          'Unexpected error listing product colors locally.',
          code: 'product_color_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductColor>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final colors = await _load(organizationId);
      for (final color in colors) {
        if (color.id == id && color.deletedAt == null) {
          return AppSuccess<ProductColor>(color);
        }
      }
      return const AppFailure<ProductColor>(
        NotFoundFailure('Product color not found.', code: 'color_not_found'),
      );
    } catch (exception) {
      return AppFailure<ProductColor>(
        UnexpectedFailure(
          'Unexpected error loading product color locally.',
          code: 'product_color_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> eanExists({
    required String organizationId,
    required Ean ean,
    String? excludingColorId,
  }) async {
    try {
      final colors = await _load(organizationId);
      return AppSuccess<bool>(
        colors.any(
          (color) =>
              color.deletedAt == null &&
              color.id != excludingColorId &&
              color.eans.any((existing) => existing == ean),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product color EAN locally.',
          code: 'product_color_local_ean_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<ProductColor>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <ProductColor>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product color list.',
        code: 'invalid_product_color_local_list',
      );
    }
    return decoded.map(_fromDynamicJson).toList(growable: false);
  }

  Future<void> _save(String organizationId, List<ProductColor> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(colors.map(_toJson).toList(growable: false)),
    );
  }

  ProductColor _fromDynamicJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local product color payload.',
        code: 'invalid_product_color_local_payload',
      );
    }
    return ProductColor(
      id: _requiredString(value, 'id'),
      organizationId: _requiredString(value, 'organizationId'),
      code: _requiredString(value, 'code'),
      name: _requiredString(value, 'name'),
      hex: HexColor.parse(_requiredString(value, 'hex')),
      mainImageUrl: _optionalString(value, 'mainImageUrl'),
      additionalImageUrls: _stringList(value['additionalImageUrls']),
      eans: _stringList(value['eans']).map(Ean.parse).toList(growable: false),
      status: _statusFromJson(_requiredString(value, 'status')),
      createdAt: _requiredDate(value, 'createdAt'),
      createdBy: _requiredString(value, 'createdBy'),
      updatedAt: _requiredDate(value, 'updatedAt'),
      updatedBy: _requiredString(value, 'updatedBy'),
      deletedAt: _optionalDate(value, 'deletedAt'),
      version: _requiredInt(value, 'version'),
      syncStatus: _syncStatusFromJson(_requiredString(value, 'syncStatus')),
    );
  }

  Map<String, dynamic> _toJson(ProductColor color) {
    return <String, dynamic>{
      'id': color.id,
      'organizationId': color.organizationId,
      'code': color.code,
      'name': color.name,
      'hex': color.hex.value,
      if (color.mainImageUrl != null) 'mainImageUrl': color.mainImageUrl,
      if (color.additionalImageUrls.isNotEmpty)
        'additionalImageUrls': color.additionalImageUrls,
      if (color.eans.isNotEmpty)
        'eans': color.eans.map((ean) => ean.digits).toList(growable: false),
      'status': _statusToJson(color.status),
      'createdAt': color.createdAt.toUtc().toIso8601String(),
      'createdBy': color.createdBy,
      'updatedAt': color.updatedAt.toUtc().toIso8601String(),
      'updatedBy': color.updatedBy,
      if (color.deletedAt != null)
        'deletedAt': color.deletedAt!.toUtc().toIso8601String(),
      'version': color.version,
      'syncStatus': _syncStatusToJson(color.syncStatus),
    };
  }

  ProductColorStatus _statusFromJson(String value) {
    return switch (value) {
      'available' => ProductColorStatus.available,
      'unavailable' => ProductColorStatus.unavailable,
      _ => throw ValidationException(
        'Invalid product color status.',
        code: 'invalid_product_color_status',
        cause: value,
      ),
    };
  }

  String _statusToJson(ProductColorStatus status) {
    return switch (status) {
      ProductColorStatus.available => 'available',
      ProductColorStatus.unavailable => 'unavailable',
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
        'Invalid product color sync status.',
        code: 'invalid_product_color_sync_status',
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
      'Invalid local product color string field.',
      code: 'invalid_product_color_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local product color string field.',
      code: 'invalid_product_color_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local product color integer field.',
      code: 'invalid_product_color_local_payload',
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

  List<String> _stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is! List<dynamic> || value.any((item) => item is! String)) {
      throw const ValidationException(
        'Invalid local product color string list.',
        code: 'invalid_product_color_local_payload',
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}
