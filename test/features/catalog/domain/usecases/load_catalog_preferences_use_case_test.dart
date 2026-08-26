import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

void main() {
  group('LoadCatalogPreferencesUseCase', () {
    test('trims organizationId/userId before delegating', () async {
      final repository = _FakeRepository(
        const AppSuccess<CatalogPreferences?>(null),
      );
      final useCase = LoadCatalogPreferencesUseCase(repository);

      await useCase(organizationId: '  org-1  ', userId: '  user-1  ');

      expect(repository.lastOrganizationId, 'org-1');
      expect(repository.lastUserId, 'user-1');
    });

    test('propagates a repository failure', () async {
      const failure = ServerFailure('down', code: 'down');
      final useCase = LoadCatalogPreferencesUseCase(
        _FakeRepository(const AppFailure<CatalogPreferences?>(failure)),
      );

      final result = await useCase(organizationId: 'org-1', userId: 'user-1');

      expect(result, isA<AppFailure<CatalogPreferences?>>());
    });
  });
}

final class _FakeRepository implements CatalogPreferencesRepository {
  _FakeRepository(this._result);

  final AppResult<CatalogPreferences?> _result;
  String? lastOrganizationId;
  String? lastUserId;

  @override
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  }) async {
    lastOrganizationId = organizationId;
    lastUserId = userId;
    return _result;
  }

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) => throw UnimplementedError();
}
