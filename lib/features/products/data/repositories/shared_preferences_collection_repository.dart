import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/value_objects/collection_status.dart';

/// Local Collection store used until the remote/outbox sync implementation
/// exists (TASK-066; same rationale as `SharedPreferencesProductRepository`,
/// TASK-065): every create/update/close mutation stays durable in
/// `SharedPreferences`, scoped to the active Organization.
///
/// Also maintains the season-usage index
/// `SharedPreferencesSeasonRepository.hasCollections` reads, so
/// `DeleteSeasonUseCase` can block deleting a Season still referenced by a
/// Collection without the two local stores depending on each other
/// directly.
@LazySingleton(as: CollectionRepository)
final class SharedPreferencesCollectionRepository
    implements CollectionRepository {
  const SharedPreferencesCollectionRepository();

  String _keyFor(String organizationId) => 'collections_$organizationId';

  String _seasonUsageKeyFor(String organizationId) =>
      'season_collection_usage_$organizationId';

  @override
  Future<AppResult<Collection>> create({required Collection collection}) async {
    try {
      final collections = await _load(collection.organizationId);
      final next = <Collection>[
        ...collections.where((existing) => existing.id != collection.id),
        collection,
      ];
      await _save(collection.organizationId, next);
      await _syncSeasonUsage(collection.organizationId, next);
      return AppSuccess<Collection>(collection);
    } catch (exception) {
      return AppFailure<Collection>(
        UnexpectedFailure(
          'Unexpected error saving collection locally.',
          code: 'collection_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Collection>> update({required Collection collection}) async {
    try {
      final collections = await _load(collection.organizationId);
      final index = collections.indexWhere(
        (existing) => existing.id == collection.id,
      );
      if (index == -1) {
        return const AppFailure<Collection>(
          NotFoundFailure(
            'Collection not found.',
            code: 'collection_not_found',
          ),
        );
      }
      final next = List<Collection>.of(collections)..[index] = collection;
      await _save(collection.organizationId, next);
      await _syncSeasonUsage(collection.organizationId, next);
      return AppSuccess<Collection>(collection);
    } catch (exception) {
      return AppFailure<Collection>(
        UnexpectedFailure(
          'Unexpected error updating collection locally.',
          code: 'collection_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final collections = await _load(organizationId);
      return AppSuccess<List<Collection>>(
        collections
            .where((collection) => collection.deletedAt == null)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Collection>>(
        UnexpectedFailure(
          'Unexpected error listing collections locally.',
          code: 'collection_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final collections = await _load(organizationId);
      for (final collection in collections) {
        if (collection.id == id) return AppSuccess<Collection>(collection);
      }
      return const AppFailure<Collection>(
        NotFoundFailure('Collection not found.', code: 'collection_not_found'),
      );
    } catch (exception) {
      return AppFailure<Collection>(
        UnexpectedFailure(
          'Unexpected error loading collection locally.',
          code: 'collection_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    try {
      final collections = await _load(organizationId);
      final index = collections.indexWhere((existing) => existing.id == id);
      if (index == -1) {
        return const AppFailure<Collection>(
          NotFoundFailure(
            'Collection not found.',
            code: 'collection_not_found',
          ),
        );
      }
      final now = DateTime.now().toUtc();
      final closed = collections[index].copyWith(
        status: CollectionStatus.closed,
        updatedAt: now,
        updatedBy: updatedBy,
        version: collections[index].version + 1,
      );
      final next = List<Collection>.of(collections)..[index] = closed;
      await _save(organizationId, next);
      return AppSuccess<Collection>(closed);
    } catch (exception) {
      return AppFailure<Collection>(
        UnexpectedFailure(
          'Unexpected error closing collection locally.',
          code: 'collection_local_close_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<void> _syncSeasonUsage(
    String organizationId,
    List<Collection> collections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonIds = collections
        .where((collection) => collection.deletedAt == null)
        .map((collection) => collection.seasonId)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    await prefs.setStringList(_seasonUsageKeyFor(organizationId), seasonIds);
  }

  Future<List<Collection>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Collection>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local collection list.',
        code: 'invalid_collection_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local collection payload.',
              code: 'invalid_collection_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<Collection> collections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(collections.map(_toJson).toList(growable: false)),
    );
  }

  Collection _fromJson(Map<String, dynamic> json) {
    return Collection(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      name: _requiredString(json, 'name'),
      seasonId: _optionalString(json, 'seasonId'),
      year: _optionalInt(json, 'year'),
      startDate: _optionalDate(json, 'startDate'),
      endDate: _optionalDate(json, 'endDate'),
      status: _statusFromJson(_requiredString(json, 'status')),
      version: _requiredInt(json, 'version'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
    );
  }

  Map<String, dynamic> _toJson(Collection collection) {
    return <String, dynamic>{
      'id': collection.id,
      'organizationId': collection.organizationId,
      'name': collection.name,
      if (collection.seasonId != null) 'seasonId': collection.seasonId,
      if (collection.year != null) 'year': collection.year,
      if (collection.startDate != null)
        'startDate': collection.startDate!.toUtc().toIso8601String(),
      if (collection.endDate != null)
        'endDate': collection.endDate!.toUtc().toIso8601String(),
      'status': _statusToJson(collection.status),
      'version': collection.version,
      'createdAt': collection.createdAt.toUtc().toIso8601String(),
      'createdBy': collection.createdBy,
      'updatedAt': collection.updatedAt.toUtc().toIso8601String(),
      'updatedBy': collection.updatedBy,
      if (collection.deletedAt != null)
        'deletedAt': collection.deletedAt!.toUtc().toIso8601String(),
    };
  }

  CollectionStatus _statusFromJson(String value) {
    return switch (value) {
      'active' => CollectionStatus.active,
      'closed' => CollectionStatus.closed,
      _ => throw ValidationException(
        'Invalid local collection status.',
        code: 'invalid_collection_local_payload',
        cause: value,
      ),
    };
  }

  String _statusToJson(CollectionStatus status) {
    return switch (status) {
      CollectionStatus.active => 'active',
      CollectionStatus.closed => 'closed',
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local collection string field.',
      code: 'invalid_collection_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local collection string field.',
      code: 'invalid_collection_local_payload',
      cause: field,
    );
  }

  int? _optionalInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is int) return value as int?;
    throw ValidationException(
      'Invalid local collection integer field.',
      code: 'invalid_collection_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local collection integer field.',
      code: 'invalid_collection_local_payload',
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
