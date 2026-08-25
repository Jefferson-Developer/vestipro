import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/size_grid_template.dart';
import '../../domain/repositories/size_grid_template_repository.dart';
import '../../domain/value_objects/product_sync_status.dart';

@LazySingleton(as: SizeGridTemplateRepository)
final class SharedPreferencesSizeGridTemplateRepository
    implements SizeGridTemplateRepository {
  const SharedPreferencesSizeGridTemplateRepository();

  String _keyFor(String organizationId) =>
      'size_grid_templates_$organizationId';

  String _productKeyFor(String organizationId) => 'products_$organizationId';

  String _variantUsageKeyFor(String organizationId) =>
      'size_grid_variant_usage_$organizationId';

  @override
  Future<AppResult<SizeGridTemplate>> create({
    required SizeGridTemplate template,
  }) async {
    try {
      final templates = await _load(template.organizationId);
      final next = <SizeGridTemplate>[
        ...templates.where((existing) => existing.id != template.id),
        template,
      ];
      await _save(template.organizationId, next);
      return AppSuccess<SizeGridTemplate>(template);
    } catch (exception) {
      return AppFailure<SizeGridTemplate>(
        UnexpectedFailure(
          'Unexpected error saving size grid template locally.',
          code: 'size_grid_template_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<SizeGridTemplate>> update({
    required SizeGridTemplate template,
  }) async {
    try {
      final templates = await _load(template.organizationId);
      final index = templates.indexWhere(
        (existing) => existing.id == template.id,
      );
      if (index == -1) {
        return const AppFailure<SizeGridTemplate>(
          NotFoundFailure(
            'Size grid template not found.',
            code: 'size_grid_template_not_found',
          ),
        );
      }

      final next = List<SizeGridTemplate>.of(templates)..[index] = template;
      await _save(template.organizationId, next);
      return AppSuccess<SizeGridTemplate>(template);
    } catch (exception) {
      return AppFailure<SizeGridTemplate>(
        UnexpectedFailure(
          'Unexpected error updating size grid template locally.',
          code: 'size_grid_template_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<SizeGridTemplate>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final templates = await _load(organizationId);
      return AppSuccess<List<SizeGridTemplate>>(
        templates
            .where((template) => !template.isDeleted)
            .map((template) => template.copyWith(sizes: template.orderedSizes))
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
    } catch (exception) {
      return AppFailure<List<SizeGridTemplate>>(
        UnexpectedFailure(
          'Unexpected error listing size grid templates locally.',
          code: 'size_grid_template_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<SizeGridTemplate>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final templates = await _load(organizationId);
      for (final template in templates) {
        if (template.id == id && !template.isDeleted) {
          return AppSuccess<SizeGridTemplate>(
            template.copyWith(sizes: template.orderedSizes),
          );
        }
      }
      return const AppFailure<SizeGridTemplate>(
        NotFoundFailure(
          'Size grid template not found.',
          code: 'size_grid_template_not_found',
        ),
      );
    } catch (exception) {
      return AppFailure<SizeGridTemplate>(
        UnexpectedFailure(
          'Unexpected error loading size grid template locally.',
          code: 'size_grid_template_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> nameExists({
    required String organizationId,
    required String name,
    String? excludingTemplateId,
  }) async {
    try {
      final normalized = _normalizeName(name);
      final excludedId = excludingTemplateId?.trim();
      final templates = await _load(organizationId);
      return AppSuccess<bool>(
        templates.any(
          (template) =>
              !template.isDeleted &&
              _normalizeName(template.name) == normalized &&
              (excludedId == null ||
                  excludedId.isEmpty ||
                  template.id != excludedId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking size grid template name locally.',
          code: 'size_grid_template_local_name_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> hasPublishedProductsUsingTemplate({
    required String organizationId,
    required String templateId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_productKeyFor(organizationId));
      if (raw == null) return const AppSuccess<bool>(false);
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        throw const ValidationException(
          'Invalid local product list.',
          code: 'invalid_product_local_list',
        );
      }
      return AppSuccess<bool>(
        decoded.whereType<Map<String, dynamic>>().any(
          (product) =>
              product['deletedAt'] == null &&
              product['status'] == 'active' &&
              product['sizeGridTemplateId'] == templateId,
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking size grid template product usage locally.',
          code: 'size_grid_template_local_product_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> sizeHasGeneratedVariants({
    required String organizationId,
    required String templateId,
    required String sizeId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usage = prefs.getStringList(_variantUsageKeyFor(organizationId));
      if (usage == null || usage.isEmpty) {
        return const AppSuccess<bool>(false);
      }
      return AppSuccess<bool>(usage.contains('$templateId|$sizeId'));
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking generated variant size usage locally.',
          code: 'size_grid_template_local_variant_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<SizeGridTemplate>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <SizeGridTemplate>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local size grid template list.',
        code: 'invalid_size_grid_template_local_list',
      );
    }
    return decoded.map(_fromDynamicJson).toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<SizeGridTemplate> templates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(templates.map(_toJson).toList(growable: false)),
    );
  }

  SizeGridTemplate _fromDynamicJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local size grid template payload.',
        code: 'invalid_size_grid_template_local_payload',
      );
    }
    return SizeGridTemplate(
      id: _requiredString(value, 'id'),
      organizationId: _requiredString(value, 'organizationId'),
      name: _requiredString(value, 'name'),
      sizes: _sizesFromJson(value['sizes']),
      createdAt: _requiredDate(value, 'createdAt'),
      createdBy: _requiredString(value, 'createdBy'),
      updatedAt: _requiredDate(value, 'updatedAt'),
      updatedBy: _requiredString(value, 'updatedBy'),
      deletedAt: _optionalDate(value, 'deletedAt'),
      version: _requiredInt(value, 'version'),
      syncStatus: _syncStatusFromJson(_requiredString(value, 'syncStatus')),
    );
  }

  Map<String, dynamic> _toJson(SizeGridTemplate template) {
    return <String, dynamic>{
      'id': template.id,
      'organizationId': template.organizationId,
      'name': template.name,
      'sizes': template.orderedSizes.map(_sizeToJson).toList(growable: false),
      'createdAt': template.createdAt.toUtc().toIso8601String(),
      'createdBy': template.createdBy,
      'updatedAt': template.updatedAt.toUtc().toIso8601String(),
      'updatedBy': template.updatedBy,
      if (template.deletedAt != null)
        'deletedAt': template.deletedAt!.toUtc().toIso8601String(),
      'version': template.version,
      'syncStatus': _syncStatusToJson(template.syncStatus),
    };
  }

  List<SizeGridSize> _sizesFromJson(Object? value) {
    if (value is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local size grid size list.',
        code: 'invalid_size_grid_template_local_payload',
      );
    }
    return value.map(_sizeFromDynamicJson).toList(growable: false);
  }

  SizeGridSize _sizeFromDynamicJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local size grid size payload.',
        code: 'invalid_size_grid_template_local_payload',
      );
    }
    return SizeGridSize(
      id: _requiredString(value, 'id'),
      organizationId: _requiredString(value, 'organizationId'),
      label: _requiredString(value, 'label'),
      orderScore: _requiredInt(value, 'orderScore'),
    );
  }

  Map<String, dynamic> _sizeToJson(SizeGridSize size) {
    return <String, dynamic>{
      'id': size.id,
      'organizationId': size.organizationId,
      'label': size.label,
      'orderScore': size.orderScore,
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
        'Invalid size grid template sync status.',
        code: 'invalid_size_grid_template_sync_status',
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
      'Invalid local size grid template string field.',
      code: 'invalid_size_grid_template_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local size grid template integer field.',
      code: 'invalid_size_grid_template_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is String) return DateTime.parse(value).toUtc();
    throw ValidationException(
      'Invalid local size grid template date field.',
      code: 'invalid_size_grid_template_local_payload',
      cause: field,
    );
  }

  String _normalizeName(String value) => value.trim().toLowerCase();
}
