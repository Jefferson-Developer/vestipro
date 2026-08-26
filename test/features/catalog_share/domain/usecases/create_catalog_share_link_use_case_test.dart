import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareRepository extends Mock
    implements CatalogShareRepository {}

void main() {
  group('CreateCatalogShareLinkUseCase', () {
    late _MockCatalogShareRepository repository;
    late CreateCatalogShareLinkUseCase useCase;

    final issuedShare = IssuedCatalogShare(
      share: CatalogShare(
        id: 'share-1',
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
        isRevoked: false,
        openCount: 0,
        expiresAt: DateTime.utc(2026, 2, 1),
        createdBy: 'rep-1',
        createdByName: 'Rep Um',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'raw-token',
    );

    setUpAll(() {
      registerFallbackValue(CatalogShareScope.product);
      registerFallbackValue(const <CatalogShareItem>[]);
    });

    setUp(() {
      repository = _MockCatalogShareRepository();
      useCase = CreateCatalogShareLinkUseCase(repository);
    });

    test('delegates to the repository with trimmed fields on a valid '
        'product-scope payload', () async {
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          scope: any(named: 'scope'),
          items: any(named: 'items'),
          collectionId: any(named: 'collectionId'),
          collectionName: any(named: 'collectionName'),
          expiresInDays: any(named: 'expiresInDays'),
        ),
      ).thenAnswer((_) async => AppSuccess<IssuedCatalogShare>(issuedShare));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        scope: CatalogShareScope.product,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      );

      expect(result, isA<AppSuccess<IssuedCatalogShare>>());
      verify(
        () => repository.create(
          organizationId: 'org-1',
          scope: CatalogShareScope.product,
          items: const [
            CatalogShareItem(productId: 'product-1', name: 'Camisa'),
          ],
          collectionId: null,
          collectionName: null,
          expiresInDays: null,
        ),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'organizationId is blank', () async {
      final result = await useCase.call(
        organizationId: '  ',
        scope: CatalogShareScope.product,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      );

      expect(result, isA<AppFailure<IssuedCatalogShare>>());
      final failure = (result as AppFailure<IssuedCatalogShare>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('organizationId'),
      );
      verifyNever(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          scope: any(named: 'scope'),
          items: any(named: 'items'),
          collectionId: any(named: 'collectionId'),
          collectionName: any(named: 'collectionName'),
          expiresInDays: any(named: 'expiresInDays'),
        ),
      );
    });

    test('returns a ValidationFailure without calling the repository when '
        'items is empty', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        scope: CatalogShareScope.selection,
        items: const [],
      );

      expect(result, isA<AppFailure<IssuedCatalogShare>>());
      final failure = (result as AppFailure<IssuedCatalogShare>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('items'),
      );
    });

    test("returns a ValidationFailure when scope is 'product' with more "
        'than one item', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: const [
          CatalogShareItem(productId: 'product-1', name: 'Camisa'),
          CatalogShareItem(productId: 'product-2', name: 'Calça'),
        ],
      );

      expect(result, isA<AppFailure<IssuedCatalogShare>>());
    });

    test("returns a ValidationFailure when scope is 'collection' without a "
        'collectionId', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        scope: CatalogShareScope.collection,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      );

      expect(result, isA<AppFailure<IssuedCatalogShare>>());
      final failure = (result as AppFailure<IssuedCatalogShare>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('collectionId'),
      );
    });

    test('propagates a permission failure from the repository', () async {
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          scope: any(named: 'scope'),
          items: any(named: 'items'),
          collectionId: any(named: 'collectionId'),
          collectionName: any(named: 'collectionName'),
          expiresInDays: any(named: 'expiresInDays'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<IssuedCatalogShare>(
          const PermissionFailure('Not allowed.'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
      );

      expect(result, isA<AppFailure<IssuedCatalogShare>>());
      expect(
        (result as AppFailure<IssuedCatalogShare>).failure,
        isA<PermissionFailure>(),
      );
    });
  });
}
