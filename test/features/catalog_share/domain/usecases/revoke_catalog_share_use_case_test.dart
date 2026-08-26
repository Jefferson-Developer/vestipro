import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareRepository extends Mock
    implements CatalogShareRepository {}

void main() {
  group('RevokeCatalogShareUseCase', () {
    late _MockCatalogShareRepository repository;
    late RevokeCatalogShareUseCase useCase;

    final revokedShare = CatalogShare(
      id: 'share-1',
      organizationId: 'org-1',
      scope: CatalogShareScope.product,
      items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      isRevoked: true,
      openCount: 0,
      expiresAt: DateTime.utc(2026, 2, 1),
      createdBy: 'rep-1',
      createdByName: 'Rep Um',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      repository = _MockCatalogShareRepository();
      useCase = RevokeCatalogShareUseCase(repository);
    });

    test('delegates to the repository with trimmed fields', () async {
      when(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          shareId: any(named: 'shareId'),
        ),
      ).thenAnswer((_) async => AppSuccess<CatalogShare>(revokedShare));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        shareId: ' share-1 ',
      );

      expect(result, isA<AppSuccess<CatalogShare>>());
      verify(
        () => repository.revoke(organizationId: 'org-1', shareId: 'share-1'),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'shareId is blank', () async {
      final result = await useCase.call(organizationId: 'org-1', shareId: '  ');

      expect(result, isA<AppFailure<CatalogShare>>());
      verifyNever(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          shareId: any(named: 'shareId'),
        ),
      );
    });

    test('propagates a failed-precondition-mapped failure from the '
        'repository (e.g. already revoked)', () async {
      when(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          shareId: any(named: 'shareId'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<CatalogShare>(
          const ConflictFailure(
            'Somente um compartilhamento ativo pode ser revogado.',
          ),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        shareId: 'share-1',
      );

      expect(result, isA<AppFailure<CatalogShare>>());
      expect(
        (result as AppFailure<CatalogShare>).failure,
        isA<ConflictFailure>(),
      );
    });
  });
}
