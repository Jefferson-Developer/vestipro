import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/feature_flags/fake_feature_flag_service.dart';
import 'package:vestipro/core/feature_flags/feature_flag_registry.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/catalog/data/repositories/remote_config_catalog_home_config_repository.dart';

void main() {
  group('RemoteConfigCatalogHomeConfigRepository', () {
    test('falls back to the safe default when the flag is empty', () async {
      final repository = RemoteConfigCatalogHomeConfigRepository(
        FakeFeatureFlagService(),
      );

      final result = await repository.getSectionConfigs('org-1');

      expect(
        (result as AppSuccess<List<CatalogHomeSectionConfig>>).value,
        defaultCatalogHomeSectionConfigs,
      );
    });

    test('falls back to the safe default when the JSON is malformed', () async {
      final featureFlagService = FakeFeatureFlagService()
        ..overrideFlag(
          FeatureFlagRegistry.configCatalogHomeSectionsJson,
          'not-json',
        );
      final repository = RemoteConfigCatalogHomeConfigRepository(
        featureFlagService,
      );

      final result = await repository.getSectionConfigs('org-1');

      expect(
        (result as AppSuccess<List<CatalogHomeSectionConfig>>).value,
        defaultCatalogHomeSectionConfigs,
      );
    });

    test(
      'falls back to the safe default when a section type is unknown',
      () async {
        final featureFlagService = FakeFeatureFlagService()
          ..overrideFlag(
            FeatureFlagRegistry.configCatalogHomeSectionsJson,
            jsonEncode(<Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'notARealType',
                'title': 'Título',
                'order': 0,
                'priority': 0,
              },
            ]),
          );
        final repository = RemoteConfigCatalogHomeConfigRepository(
          featureFlagService,
        );

        final result = await repository.getSectionConfigs('org-1');

        expect(
          (result as AppSuccess<List<CatalogHomeSectionConfig>>).value,
          defaultCatalogHomeSectionConfigs,
        );
      },
    );

    test(
      'parses a valid override, applying defaults for optional fields',
      () async {
        final featureFlagService = FakeFeatureFlagService()
          ..overrideFlag(
            FeatureFlagRegistry.configCatalogHomeSectionsJson,
            jsonEncode(<Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'campaigns',
                'title': 'Campanhas VIP',
                'order': 0,
                'priority': 0,
              },
            ]),
          );
        final repository = RemoteConfigCatalogHomeConfigRepository(
          featureFlagService,
        );

        final result = await repository.getSectionConfigs('org-1');

        final configs =
            (result as AppSuccess<List<CatalogHomeSectionConfig>>).value;
        expect(configs, hasLength(1));
        expect(configs.single.type, CatalogHomeSectionType.campaigns);
        expect(configs.single.title, 'Campanhas VIP');
        expect(configs.single.enabled, isTrue);
        expect(configs.single.itemLimit, 12);
      },
    );
  });
}
