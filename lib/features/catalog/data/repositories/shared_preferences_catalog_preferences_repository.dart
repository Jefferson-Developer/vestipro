import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../domain/entities/catalog_preferences.dart';
import '../../domain/repositories/catalog_preferences_repository.dart';
import '../../domain/value_objects/catalog_view_mode.dart';

/// Local (`SharedPreferences`) store for [CatalogPreferences] (TASK-082),
/// the same "local store, hand-rolled JSON" approach
/// `SharedPreferencesCatalogHomeCacheRepository` already uses — reuses
/// `CatalogFilter.toQueryParameters`/`fromQueryParameters` for the filter
/// payload itself instead of a second, parallel serialization.
@LazySingleton(as: CatalogPreferencesRepository)
final class SharedPreferencesCatalogPreferencesRepository
    implements CatalogPreferencesRepository {
  const SharedPreferencesCatalogPreferencesRepository();

  String _keyFor(String organizationId, String userId) =>
      'catalog_preferences_${organizationId}_$userId';

  @override
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(organizationId, userId));
      if (raw == null) return const AppSuccess<CatalogPreferences?>(null);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const ValidationException(
          'Invalid local catalog preferences payload.',
          code: 'invalid_catalog_preferences_local_payload',
        );
      }
      final filterRaw = decoded['filter'];
      final filterQuery = filterRaw is Map<String, dynamic>
          ? filterRaw.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            )
          : const <String, String>{};

      return AppSuccess<CatalogPreferences?>(
        CatalogPreferences(
          viewMode: CatalogViewMode.fromCode(decoded['viewMode'] as String?),
          filter: CatalogFilter.fromQueryParameters(filterQuery),
        ),
      );
    } catch (exception) {
      return AppFailure<CatalogPreferences?>(
        UnexpectedFailure(
          'Unexpected error loading catalog preferences locally.',
          code: 'catalog_preferences_local_load_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(organizationId, userId),
        jsonEncode(<String, dynamic>{
          'viewMode': preferences.viewMode.code,
          'filter': preferences.filter.toQueryParameters(),
        }),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving catalog preferences locally.',
          code: 'catalog_preferences_local_save_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
