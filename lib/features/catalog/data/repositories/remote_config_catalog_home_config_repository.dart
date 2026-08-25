import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_registry.dart';
import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_home_section_config.dart';
import '../../domain/entities/catalog_home_section_type.dart';
import '../../domain/repositories/catalog_home_config_repository.dart';

/// Reads the catalog home's section composition from Remote Config
/// (TASK-076), via [FeatureFlagRegistry.configCatalogHomeSectionsJson] — a
/// JSON array of `{type, title, order, priority, enabled, itemLimit}`
/// objects. Falls back to [defaultCatalogHomeSectionConfigs] whenever the
/// remote value is empty, malformed, or references an unknown
/// `CatalogHomeSectionType`, mirroring `configureRemoteConfig`'s "never
/// blocks, always falls back to the safe local default" contract — this
/// never throws.
@LazySingleton(as: CatalogHomeConfigRepository)
final class RemoteConfigCatalogHomeConfigRepository
    implements CatalogHomeConfigRepository {
  const RemoteConfigCatalogHomeConfigRepository(this._featureFlagService);

  final FeatureFlagService _featureFlagService;

  @override
  Future<AppResult<List<CatalogHomeSectionConfig>>> getSectionConfigs(
    String organizationId,
  ) async {
    final raw = _featureFlagService.getString(
      FeatureFlagRegistry.configCatalogHomeSectionsJson,
    );
    final parsed = _tryParse(raw);
    return AppSuccess<List<CatalogHomeSectionConfig>>(
      parsed ?? defaultCatalogHomeSectionConfigs,
    );
  }

  List<CatalogHomeSectionConfig>? _tryParse(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return null;

      final configs = <CatalogHomeSectionConfig>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) return null;
        final config = _configFromJson(item);
        if (config == null) return null;
        configs.add(config);
      }
      return configs.isEmpty ? null : configs;
    } catch (_) {
      return null;
    }
  }

  CatalogHomeSectionConfig? _configFromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    final title = json['title'];
    final order = json['order'];
    final priority = json['priority'];
    if (typeName is! String || title is! String) return null;
    if (order is! int || priority is! int) return null;

    CatalogHomeSectionType type;
    try {
      type = CatalogHomeSectionType.values.byName(typeName);
    } catch (_) {
      return null;
    }

    final enabled = json['enabled'];
    final itemLimit = json['itemLimit'];
    return CatalogHomeSectionConfig(
      type: type,
      title: title,
      order: order,
      priority: priority,
      enabled: enabled is bool ? enabled : true,
      itemLimit: itemLimit is int ? itemLimit : 12,
    );
  }
}
