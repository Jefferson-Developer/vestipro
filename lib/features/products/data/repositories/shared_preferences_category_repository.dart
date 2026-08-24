import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Local Category store used until the remote/outbox sync implementation
/// exists (TASK-067; same rationale as `SharedPreferencesSeasonRepository`,
/// TASK-066): every create/update/delete/reorder mutation stays durable in
/// `SharedPreferences`, scoped to the active Organization. Name uniqueness
/// is checked locally per sibling group, case-insensitive and trimmed.
@LazySingleton(as: CategoryRepository)
final class SharedPreferencesCategoryRepository implements CategoryRepository {
  const SharedPreferencesCategoryRepository();

  String _keyFor(String organizationId) => 'categories_$organizationId';

  /// Key `SharedPreferencesProductRepository` writes the set of
  /// category/subcategory ids currently referenced by a non-deleted Product
  /// to, so [hasProducts] never has to depend on the product repository
  /// directly — the same decoupled-usage-index pattern
  /// `SharedPreferencesSeasonRepository.hasCollections` already uses for
  /// Season/Collection.
  String _productUsageKeyFor(String organizationId) =>
      'category_product_usage_$organizationId';

  @override
  Future<AppResult<Category>> create({required Category category}) async {
    try {
      final categories = await _load(category.organizationId);
      final next = <Category>[
        ...categories.where((existing) => existing.id != category.id),
        category,
      ];
      await _save(category.organizationId, next);
      return AppSuccess<Category>(category);
    } catch (exception) {
      return AppFailure<Category>(
        UnexpectedFailure(
          'Unexpected error saving category locally.',
          code: 'category_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Category>> update({required Category category}) async {
    try {
      final categories = await _load(category.organizationId);
      final index = categories.indexWhere(
        (existing) => existing.id == category.id,
      );
      if (index == -1) {
        return const AppFailure<Category>(
          NotFoundFailure('Category not found.', code: 'category_not_found'),
        );
      }
      final next = List<Category>.of(categories)..[index] = category;
      await _save(category.organizationId, next);
      return AppSuccess<Category>(category);
    } catch (exception) {
      return AppFailure<Category>(
        UnexpectedFailure(
          'Unexpected error updating category locally.',
          code: 'category_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final categories = await _load(organizationId);
      return AppSuccess<List<Category>>(
        categories
            .where((category) => category.deletedAt == null)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Category>>(
        UnexpectedFailure(
          'Unexpected error listing categories locally.',
          code: 'category_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final categories = await _load(organizationId);
      for (final category in categories) {
        if (category.id == id && category.deletedAt == null) {
          return AppSuccess<Category>(category);
        }
      }
      return const AppFailure<Category>(
        NotFoundFailure('Category not found.', code: 'category_not_found'),
      );
    } catch (exception) {
      return AppFailure<Category>(
        UnexpectedFailure(
          'Unexpected error loading category locally.',
          code: 'category_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  }) async {
    try {
      final categories = await _load(organizationId);
      final normalizedName = name.trim().toLowerCase();
      final excludingId = excludingCategoryId?.trim();
      return AppSuccess<bool>(
        categories.any(
          (category) =>
              category.deletedAt == null &&
              category.parentId == parentId &&
              category.name.trim().toLowerCase() == normalizedName &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  category.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking category name locally.',
          code: 'category_local_exists_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usage =
          prefs.getStringList(_productUsageKeyFor(organizationId)) ??
          const <String>[];
      return AppSuccess<bool>(usage.contains(categoryId));
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking category usage locally.',
          code: 'category_local_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    try {
      final categories = await _load(organizationId);
      final index = categories.indexWhere((existing) => existing.id == id);
      if (index == -1) {
        return const AppFailure<Category>(
          NotFoundFailure('Category not found.', code: 'category_not_found'),
        );
      }
      final now = DateTime.now().toUtc();
      final deleted = categories[index].copyWith(
        deletedAt: now,
        updatedAt: now,
        updatedBy: deletedBy,
        version: categories[index].version + 1,
      );
      final next = List<Category>.of(categories)..[index] = deleted;
      await _save(organizationId, next);
      return AppSuccess<Category>(deleted);
    } catch (exception) {
      return AppFailure<Category>(
        UnexpectedFailure(
          'Unexpected error deleting category locally.',
          code: 'category_local_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) async {
    try {
      final categories = await _load(organizationId);
      final now = DateTime.now().toUtc();
      final updatedById = <String, Category>{};

      for (var index = 0; index < orderedIds.length; index++) {
        final id = orderedIds[index];
        final categoryIndex = categories.indexWhere(
          (category) => category.id == id,
        );
        if (categoryIndex == -1) {
          return const AppFailure<List<Category>>(
            NotFoundFailure('Category not found.', code: 'category_not_found'),
          );
        }
        final current = categories[categoryIndex];
        final reordered = current.copyWith(
          sortOrder: index,
          updatedAt: now,
          updatedBy: updatedBy,
          version: current.version + 1,
        );
        categories[categoryIndex] = reordered;
        updatedById[id] = reordered;
      }

      await _save(organizationId, categories);
      return AppSuccess<List<Category>>(
        orderedIds.map((id) => updatedById[id]!).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Category>>(
        UnexpectedFailure(
          'Unexpected error reordering categories locally.',
          code: 'category_local_reorder_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<Category>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return <Category>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local category list.',
        code: 'invalid_category_local_list',
      );
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ValidationException(
          'Invalid local category payload.',
          code: 'invalid_category_local_payload',
        );
      }
      return _fromJson(item);
    }).toList();
  }

  Future<void> _save(String organizationId, List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(categories.map(_toJson).toList(growable: false)),
    );
  }

  Category _fromJson(Map<String, dynamic> json) {
    return Category(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      name: _requiredString(json, 'name'),
      parentId: _optionalString(json, 'parentId'),
      sortOrder: _requiredInt(json, 'sortOrder'),
      version: _requiredInt(json, 'version'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
    );
  }

  Map<String, dynamic> _toJson(Category category) {
    return <String, dynamic>{
      'id': category.id,
      'organizationId': category.organizationId,
      'name': category.name,
      if (category.parentId != null) 'parentId': category.parentId,
      'sortOrder': category.sortOrder,
      'version': category.version,
      'createdAt': category.createdAt.toUtc().toIso8601String(),
      'createdBy': category.createdBy,
      'updatedAt': category.updatedAt.toUtc().toIso8601String(),
      'updatedBy': category.updatedBy,
      if (category.deletedAt != null)
        'deletedAt': category.deletedAt!.toUtc().toIso8601String(),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local category string field.',
      code: 'invalid_category_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local category string field.',
      code: 'invalid_category_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local category integer field.',
      code: 'invalid_category_local_payload',
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
}
