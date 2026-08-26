import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareRepository extends Mock
    implements CatalogShareRepository {}

void main() {
  group('GetCatalogShareUseCase', () {
    late _MockCatalogShareRepository repository;
    late GetCatalogShareUseCase useCase;

    final share = CatalogShare(
      id: 'share-1',
      organizationId: 'org-1',
      scope: CatalogShareScope.product,
      items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      isRevoked: false,
      openCount: 3,
      expiresAt: DateTime.utc(2026, 2, 1),
      createdBy: 'rep-1',
      createdByName: 'Rep Um',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      repository = _MockCatalogShareRepository();
      useCase = GetCatalogShareUseCase(repository);
    });

    test('delegates to the repository with trimmed fields', () async {
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          shareId: any(named: 'shareId'),
        ),
      ).thenAnswer((_) async => AppSuccess<CatalogShare>(share));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        shareId: ' share-1 ',
      );

      expect(result, isA<AppSuccess<CatalogShare>>());
      expect((result as AppSuccess<CatalogShare>).value.openCount, 3);
      verify(
        () => repository.getById(organizationId: 'org-1', shareId: 'share-1'),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'organizationId is blank', () async {
      final result = await useCase.call(
        organizationId: '  ',
        shareId: 'share-1',
      );

      expect(result, isA<AppFailure<CatalogShare>>());
      verifyNever(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          shareId: any(named: 'shareId'),
        ),
      );
    });
  });
}
