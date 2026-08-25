import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

void main() {
  group('GetCatalogHomeConfigUseCase', () {
    test('returns the repository configs when present', () async {
      final custom = <CatalogHomeSectionConfig>[
        const CatalogHomeSectionConfig(
          type: CatalogHomeSectionType.newArrivals,
          title: 'Novidades',
          order: 0,
          priority: 0,
        ),
      ];
      final useCase = GetCatalogHomeConfigUseCase(
        _FakeRepository(AppSuccess<List<CatalogHomeSectionConfig>>(custom)),
      );

      final result = await useCase('org-1');

      expect(result, custom);
    });

    test('falls back to the safe default when the repository fails', () async {
      final useCase = GetCatalogHomeConfigUseCase(
        _FakeRepository(
          const AppFailure<List<CatalogHomeSectionConfig>>(
            ServerFailure('down', code: 'down'),
          ),
        ),
      );

      final result = await useCase('org-1');

      expect(result, defaultCatalogHomeSectionConfigs);
    });

    test(
      'falls back to the safe default when the repository returns empty',
      () async {
        final useCase = GetCatalogHomeConfigUseCase(
          _FakeRepository(
            const AppSuccess<List<CatalogHomeSectionConfig>>(
              <CatalogHomeSectionConfig>[],
            ),
          ),
        );

        final result = await useCase('org-1');

        expect(result, defaultCatalogHomeSectionConfigs);
      },
    );
  });
}

class _FakeRepository implements CatalogHomeConfigRepository {
  _FakeRepository(this._result);

  final AppResult<List<CatalogHomeSectionConfig>> _result;

  @override
  Future<AppResult<List<CatalogHomeSectionConfig>>> getSectionConfigs(
    String organizationId,
  ) async => _result;
}
