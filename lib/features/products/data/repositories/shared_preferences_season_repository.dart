import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/season.dart';
import '../../domain/repositories/season_repository.dart';

/// Local Season store used until the remote/outbox sync implementation
/// exists (TASK-066; same rationale as `SharedPreferencesProductRepository`,
/// TASK-065): every create/update/delete mutation stays durable in
/// `SharedPreferences`, scoped to the active Organization. Name uniqueness
/// is checked locally, case-insensitive and trimmed.
@LazySingleton(as: SeasonRepository)
final class SharedPreferencesSeasonRepository implements SeasonRepository {
  const SharedPreferencesSeasonRepository();

  String _keyFor(String organizationId) => 'seasons_$organizationId';

  /// Key used to check whether a `Collection` still references a Season.
  /// `SharedPreferencesCollectionRepository` writes the set of seasonIds in
  /// use here so `hasCollections` never has to depend on the collection
  /// repository directly (keeps both local stores independent, same as
  /// their Firestore-siblings would be two separate subcollections).
  String _collectionUsageKeyFor(String organizationId) =>
      'season_collection_usage_$organizationId';

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  }) async {
    try {
      final seasons = await _load(organizationId);
      final normalizedName = name.trim().toLowerCase();
      final excludingId = excludingSeasonId?.trim();
      return AppSuccess<bool>(
        seasons.any(
          (season) =>
              season.deletedAt == null &&
              season.name.trim().toLowerCase() == normalizedName &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  season.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking season name locally.',
          code: 'season_local_exists_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Season>> create({required Season season}) async {
    try {
      final seasons = await _load(season.organizationId);
      final next = <Season>[
        ...seasons.where((existing) => existing.id != season.id),
        season,
      ];
      await _save(season.organizationId, next);
      return AppSuccess<Season>(season);
    } catch (exception) {
      return AppFailure<Season>(
        UnexpectedFailure(
          'Unexpected error saving season locally.',
          code: 'season_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Season>> update({required Season season}) async {
    try {
      final seasons = await _load(season.organizationId);
      final index = seasons.indexWhere((existing) => existing.id == season.id);
      if (index == -1) {
        return const AppFailure<Season>(
          NotFoundFailure('Season not found.', code: 'season_not_found'),
        );
      }
      final next = List<Season>.of(seasons)..[index] = season;
      await _save(season.organizationId, next);
      return AppSuccess<Season>(season);
    } catch (exception) {
      return AppFailure<Season>(
        UnexpectedFailure(
          'Unexpected error updating season locally.',
          code: 'season_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Season>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final seasons = await _load(organizationId);
      return AppSuccess<List<Season>>(
        seasons
            .where((season) => season.deletedAt == null)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Season>>(
        UnexpectedFailure(
          'Unexpected error listing seasons locally.',
          code: 'season_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Season>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final seasons = await _load(organizationId);
      for (final season in seasons) {
        if (season.id == id) return AppSuccess<Season>(season);
      }
      return const AppFailure<Season>(
        NotFoundFailure('Season not found.', code: 'season_not_found'),
      );
    } catch (exception) {
      return AppFailure<Season>(
        UnexpectedFailure(
          'Unexpected error loading season locally.',
          code: 'season_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> hasCollections({
    required String organizationId,
    required String seasonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usage =
          prefs.getStringList(_collectionUsageKeyFor(organizationId)) ??
          const <String>[];
      return AppSuccess<bool>(usage.contains(seasonId));
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking season usage locally.',
          code: 'season_local_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    try {
      final seasons = await _load(organizationId);
      final index = seasons.indexWhere((existing) => existing.id == id);
      if (index == -1) {
        return const AppFailure<Season>(
          NotFoundFailure('Season not found.', code: 'season_not_found'),
        );
      }
      final now = DateTime.now().toUtc();
      final deleted = seasons[index].copyWith(
        deletedAt: now,
        updatedAt: now,
        updatedBy: deletedBy,
        version: seasons[index].version + 1,
      );
      final next = List<Season>.of(seasons)..[index] = deleted;
      await _save(organizationId, next);
      return AppSuccess<Season>(deleted);
    } catch (exception) {
      return AppFailure<Season>(
        UnexpectedFailure(
          'Unexpected error deleting season locally.',
          code: 'season_local_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<Season>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Season>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local season list.',
        code: 'invalid_season_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local season payload.',
              code: 'invalid_season_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<Season> seasons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(seasons.map(_toJson).toList(growable: false)),
    );
  }

  Season _fromJson(Map<String, dynamic> json) {
    return Season(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      name: _requiredString(json, 'name'),
      version: _requiredInt(json, 'version'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
    );
  }

  Map<String, dynamic> _toJson(Season season) {
    return <String, dynamic>{
      'id': season.id,
      'organizationId': season.organizationId,
      'name': season.name,
      'version': season.version,
      'createdAt': season.createdAt.toUtc().toIso8601String(),
      'createdBy': season.createdBy,
      'updatedAt': season.updatedAt.toUtc().toIso8601String(),
      'updatedBy': season.updatedBy,
      if (season.deletedAt != null)
        'deletedAt': season.deletedAt!.toUtc().toIso8601String(),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local season string field.',
      code: 'invalid_season_local_payload',
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
      'Invalid local season string field.',
      code: 'invalid_season_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local season integer field.',
      code: 'invalid_season_local_payload',
      cause: field,
    );
  }
}
