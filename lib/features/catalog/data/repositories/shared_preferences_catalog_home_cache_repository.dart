import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_home_item.dart';
import '../../domain/entities/catalog_home_section.dart';
import '../../domain/entities/catalog_home_section_type.dart';
import '../../domain/entities/catalog_home_snapshot.dart';
import '../../domain/repositories/catalog_home_cache_repository.dart';

/// Local stale-while-revalidate cache for the catalog home (TASK-076),
/// scoped by organization and (optionally) company. Stores the already
/// flattened [CatalogHomeSection]/[CatalogHomeItem] shape `CatalogHomeBloc`
/// renders — the same "local store, hand-rolled JSON, ISO-8601 dates"
/// approach `SharedPreferencesProductRepository`/`SharedPreferencesCollectionRepository`
/// already use, since this cache is not itself the entity's source of truth.
@LazySingleton(as: CatalogHomeCacheRepository)
final class SharedPreferencesCatalogHomeCacheRepository
    implements CatalogHomeCacheRepository {
  const SharedPreferencesCatalogHomeCacheRepository();

  String _keyFor(String organizationId, String? companyId) {
    final scope = (companyId == null || companyId.trim().isEmpty)
        ? 'all'
        : companyId.trim();
    return 'catalog_home_cache_${organizationId}_$scope';
  }

  @override
  Future<AppResult<CatalogHomeSnapshot?>> load({
    required String organizationId,
    String? companyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(organizationId, companyId));
      if (raw == null) return const AppSuccess<CatalogHomeSnapshot?>(null);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const ValidationException(
          'Invalid local catalog home cache payload.',
          code: 'invalid_catalog_home_cache_local_payload',
        );
      }
      return AppSuccess<CatalogHomeSnapshot?>(_snapshotFromJson(decoded));
    } catch (exception) {
      return AppFailure<CatalogHomeSnapshot?>(
        UnexpectedFailure(
          'Unexpected error loading catalog home cache locally.',
          code: 'catalog_home_cache_local_load_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    String? companyId,
    required CatalogHomeSnapshot snapshot,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(organizationId, companyId),
        jsonEncode(_snapshotToJson(snapshot)),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving catalog home cache locally.',
          code: 'catalog_home_cache_local_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Map<String, dynamic> _snapshotToJson(CatalogHomeSnapshot snapshot) {
    return <String, dynamic>{
      'savedAt': snapshot.savedAt.toUtc().toIso8601String(),
      'sections': snapshot.sections.map(_sectionToJson).toList(growable: false),
    };
  }

  CatalogHomeSnapshot _snapshotFromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'];
    if (sectionsRaw is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local catalog home cache sections.',
        code: 'invalid_catalog_home_cache_local_payload',
      );
    }
    return CatalogHomeSnapshot(
      savedAt: DateTime.parse(_requiredString(json, 'savedAt')).toUtc(),
      sections: sectionsRaw
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ValidationException(
                'Invalid local catalog home cache section.',
                code: 'invalid_catalog_home_cache_local_payload',
              );
            }
            return _sectionFromJson(item);
          })
          .toList(growable: false),
    );
  }

  Map<String, dynamic> _sectionToJson(CatalogHomeSection section) {
    return <String, dynamic>{
      'type': section.type.name,
      'title': section.title,
      'order': section.order,
      'priority': section.priority,
      'items': section.items.map(_itemToJson).toList(growable: false),
    };
  }

  CatalogHomeSection _sectionFromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    if (itemsRaw is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local catalog home cache section items.',
        code: 'invalid_catalog_home_cache_local_payload',
      );
    }
    return CatalogHomeSection(
      type: CatalogHomeSectionType.values.byName(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      order: _requiredInt(json, 'order'),
      priority: _requiredInt(json, 'priority'),
      items: itemsRaw
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ValidationException(
                'Invalid local catalog home cache item.',
                code: 'invalid_catalog_home_cache_local_payload',
              );
            }
            return _itemFromJson(item);
          })
          .toList(growable: false),
    );
  }

  Map<String, dynamic> _itemToJson(CatalogHomeItem item) {
    return <String, dynamic>{
      'id': item.id,
      'title': item.title,
      if (item.subtitle != null) 'subtitle': item.subtitle,
      if (item.imageUrl != null) 'imageUrl': item.imageUrl,
      if (item.badgeLabel != null) 'badgeLabel': item.badgeLabel,
    };
  }

  CatalogHomeItem _itemFromJson(Map<String, dynamic> json) {
    return CatalogHomeItem(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      subtitle: _optionalString(json, 'subtitle'),
      imageUrl: _optionalString(json, 'imageUrl'),
      badgeLabel: _optionalString(json, 'badgeLabel'),
    );
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local catalog home cache string field.',
      code: 'invalid_catalog_home_cache_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local catalog home cache string field.',
      code: 'invalid_catalog_home_cache_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local catalog home cache integer field.',
      code: 'invalid_catalog_home_cache_local_payload',
      cause: field,
    );
  }
}
