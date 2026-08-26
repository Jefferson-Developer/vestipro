import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SaveCatalogPreferencesUseCase', () {
    test('trims organizationId/userId and forwards the preferences', () async {
      final repository = _FakeRepository();
      final useCase = SaveCatalogPreferencesUseCase(repository);
      const preferences = CatalogPreferences(
        viewMode: CatalogViewMode.readyStock,
        filter: CatalogFilter(brand: 'Malwee'),
      );

      final result = await useCase(
        organizationId: '  org-1  ',
        userId: '  user-1  ',
        preferences: preferences,
      );

      expect(result, isA<AppSuccess<void>>());
      expect(repository.lastOrganizationId, 'org-1');
      expect(repository.lastUserId, 'user-1');
      expect(repository.lastPreferences, preferences);
    });

    test('propagates a repository failure', () async {
      final repository = _FakeRepository(
        result: const AppFailure<void>(ServerFailure('down', code: 'down')),
      );
      final useCase = SaveCatalogPreferencesUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        preferences: const CatalogPreferences(),
      );

      expect(result, isA<AppFailure<void>>());
    });
  });
}

final class _FakeRepository implements CatalogPreferencesRepository {
  _FakeRepository({AppResult<void>? result})
    : _result = result ?? const AppSuccess<void>(null);

  final AppResult<void> _result;
  String? lastOrganizationId;
  String? lastUserId;
  CatalogPreferences? lastPreferences;

  @override
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) async {
    lastOrganizationId = organizationId;
    lastUserId = userId;
    lastPreferences = preferences;
    return _result;
  }
}
