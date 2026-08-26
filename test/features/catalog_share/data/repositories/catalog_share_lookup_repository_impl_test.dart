import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/data/datasources/catalog_share_lookup_data_source.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_preview_dto.dart';
import 'package:vestipro/features/catalog_share/data/mappers/catalog_share_mapper.dart';
import 'package:vestipro/features/catalog_share/data/repositories/catalog_share_lookup_repository_impl.dart';
import 'package:vestipro/features/catalog_share/domain/entities/catalog_share_preview.dart';

class _MockCatalogShareLookupDataSource extends Mock
    implements CatalogShareLookupDataSource {}

void main() {
  group('CatalogShareLookupRepositoryImpl', () {
    late _MockCatalogShareLookupDataSource dataSource;
    late CatalogShareLookupRepositoryImpl repository;

    setUp(() {
      dataSource = _MockCatalogShareLookupDataSource();
      repository = CatalogShareLookupRepositoryImpl(
        dataSource: dataSource,
        mapper: const CatalogShareMapper(),
      );
    });

    group('preview', () {
      test(
        'maps a successful datasource call into a CatalogSharePreview',
        () async {
          when(() => dataSource.preview(token: any(named: 'token'))).thenAnswer(
            (_) async =>
                const CatalogSharePreviewDto(outcome: 'valid', items: []),
          );

          final result = await repository.preview(token: 'token-1');

          expect(result, isA<AppSuccess<CatalogSharePreview>>());
        },
      );

      test(
        'maps an AppException thrown by the datasource into a Failure',
        () async {
          when(
            () => dataSource.preview(token: any(named: 'token')),
          ).thenThrow(const NetworkException('Offline.'));

          final result = await repository.preview(token: 'token-1');

          expect(result, isA<AppFailure<CatalogSharePreview>>());
        },
      );
    });

    group('registerOpen', () {
      test('delegates to the datasource', () async {
        when(
          () => dataSource.registerOpen(token: any(named: 'token')),
        ).thenAnswer((_) async {});

        await repository.registerOpen(token: 'token-1');

        verify(() => dataSource.registerOpen(token: 'token-1')).called(1);
      });
    });
  });
}
