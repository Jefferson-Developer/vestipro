import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/data/datasources/catalog_share_data_source.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_dto.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_item_dto.dart';
import 'package:vestipro/features/catalog_share/data/mappers/catalog_share_mapper.dart';
import 'package:vestipro/features/catalog_share/data/repositories/catalog_share_repository_impl.dart';
import 'package:vestipro/features/catalog_share/domain/entities/catalog_share.dart';
import 'package:vestipro/features/catalog_share/domain/entities/catalog_share_item.dart';
import 'package:vestipro/features/catalog_share/domain/entities/issued_catalog_share.dart';
import 'package:vestipro/features/catalog_share/domain/value_objects/catalog_share_scope.dart';

class _MockCatalogShareDataSource extends Mock
    implements CatalogShareDataSource {}

void main() {
  group('CatalogShareRepositoryImpl', () {
    late _MockCatalogShareDataSource dataSource;
    late CatalogShareRepositoryImpl repository;

    final dto = CatalogShareDto(
      id: 'share-1',
      organizationId: 'org-1',
      scope: 'product',
      items: const [
        CatalogShareItemDto(productId: 'product-1', name: 'Camisa'),
      ],
      status: 'active',
      openCount: 0,
      expiresAt: DateTime.utc(2026, 2, 1),
      createdBy: 'rep-1',
      createdByName: 'Rep Um',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUpAll(() {
      registerFallbackValue(CatalogShareScope.product);
      registerFallbackValue(const <CatalogShareItemDto>[]);
    });

    setUp(() {
      dataSource = _MockCatalogShareDataSource();
      repository = CatalogShareRepositoryImpl(
        dataSource: dataSource,
        mapper: const CatalogShareMapper(),
      );
    });

    group('create', () {
      test(
        'maps a successful datasource call into an IssuedCatalogShare',
        () async {
          when(
            () => dataSource.create(
              organizationId: any(named: 'organizationId'),
              scope: any(named: 'scope'),
              items: any(named: 'items'),
              collectionId: any(named: 'collectionId'),
              collectionName: any(named: 'collectionName'),
              expiresInDays: any(named: 'expiresInDays'),
            ),
          ).thenAnswer((_) async => (share: dto, token: 'raw-token'));

          final result = await repository.create(
            organizationId: 'org-1',
            scope: CatalogShareScope.product,
            items: const [
              CatalogShareItem(productId: 'product-1', name: 'Camisa'),
            ],
          );

          expect(result, isA<AppSuccess<IssuedCatalogShare>>());
          final issued = (result as AppSuccess<IssuedCatalogShare>).value;
          expect(issued.token, 'raw-token');
          expect(issued.share.id, 'share-1');
        },
      );

      test(
        'maps an AppException thrown by the datasource into a Failure',
        () async {
          when(
            () => dataSource.create(
              organizationId: any(named: 'organizationId'),
              scope: any(named: 'scope'),
              items: any(named: 'items'),
              collectionId: any(named: 'collectionId'),
              collectionName: any(named: 'collectionName'),
              expiresInDays: any(named: 'expiresInDays'),
            ),
          ).thenThrow(const ForbiddenException('Not allowed.'));

          final result = await repository.create(
            organizationId: 'org-1',
            scope: CatalogShareScope.product,
            items: const [
              CatalogShareItem(productId: 'product-1', name: 'Camisa'),
            ],
          );

          expect(result, isA<AppFailure<IssuedCatalogShare>>());
          expect(
            (result as AppFailure<IssuedCatalogShare>).failure,
            isA<PermissionFailure>(),
          );
        },
      );

      test('maps an unexpected error into an UnexpectedFailure', () async {
        when(
          () => dataSource.create(
            organizationId: any(named: 'organizationId'),
            scope: any(named: 'scope'),
            items: any(named: 'items'),
            collectionId: any(named: 'collectionId'),
            collectionName: any(named: 'collectionName'),
            expiresInDays: any(named: 'expiresInDays'),
          ),
        ).thenThrow(StateError('boom'));

        final result = await repository.create(
          organizationId: 'org-1',
          scope: CatalogShareScope.product,
          items: const [
            CatalogShareItem(productId: 'product-1', name: 'Camisa'),
          ],
        );

        expect(result, isA<AppFailure<IssuedCatalogShare>>());
        expect(
          (result as AppFailure<IssuedCatalogShare>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('revoke', () {
      test('maps a successful datasource call into a CatalogShare', () async {
        when(
          () => dataSource.revoke(
            organizationId: any(named: 'organizationId'),
            shareId: any(named: 'shareId'),
          ),
        ).thenAnswer((_) async => dto);

        final result = await repository.revoke(
          organizationId: 'org-1',
          shareId: 'share-1',
        );

        expect(result, isA<AppSuccess<CatalogShare>>());
      });
    });

    group('getById', () {
      test('maps a found document into a CatalogShare', () async {
        when(
          () => dataSource.getById(
            organizationId: any(named: 'organizationId'),
            shareId: any(named: 'shareId'),
          ),
        ).thenAnswer((_) async => dto);

        final result = await repository.getById(
          organizationId: 'org-1',
          shareId: 'share-1',
        );

        expect(result, isA<AppSuccess<CatalogShare>>());
      });

      test(
        'returns a NotFoundFailure when the document does not exist',
        () async {
          when(
            () => dataSource.getById(
              organizationId: any(named: 'organizationId'),
              shareId: any(named: 'shareId'),
            ),
          ).thenAnswer((_) async => null);

          final result = await repository.getById(
            organizationId: 'org-1',
            shareId: 'share-1',
          );

          expect(result, isA<AppFailure<CatalogShare>>());
          expect(
            (result as AppFailure<CatalogShare>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });
  });
}
