import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/product_import/product_import.dart';

class _MockProductImportJobRepository extends Mock
    implements ProductImportJobRepository {}

void main() {
  group('StartProductImportJobUseCase', () {
    late _MockProductImportJobRepository repository;
    late StartProductImportJobUseCase useCase;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        const ProductImportMapping(
          hasHeaderRow: true,
          columnByField: <ProductImportField, int>{ProductImportField.sku: 0},
          sizeGridTemplateId: 'grid-1',
        ),
      );
      registerFallbackValue(const ProductImportLookup());
    });

    setUp(() {
      repository = _MockProductImportJobRepository();
      useCase = StartProductImportJobUseCase(repository);
    });

    test(
      'never calls the repository when the mapping is missing required fields',
      () async {
        final mapping = ProductImportMapping(
          hasHeaderRow: true,
          columnByField: const <ProductImportField, int>{
            ProductImportField.sku: 0,
          },
          sizeGridTemplateId: 'grid-1',
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          fileName: 'produtos.csv',
          isXlsx: false,
          fileBytes: Uint8List(0),
          mapping: mapping,
          lookup: const ProductImportLookup(),
          createMissingCategories: false,
          createMissingCollections: false,
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<ProductImportJob>>());
        verifyNever(
          () => repository.startJob(
            organizationId: any(named: 'organizationId'),
            companyId: any(named: 'companyId'),
            fileName: any(named: 'fileName'),
            isXlsx: any(named: 'isXlsx'),
            fileBytes: any(named: 'fileBytes'),
            mapping: any(named: 'mapping'),
            lookup: any(named: 'lookup'),
            createMissingCategories: any(named: 'createMissingCategories'),
            createMissingCollections: any(named: 'createMissingCollections'),
            imageBytesByFileName: any(named: 'imageBytesByFileName'),
            templateId: any(named: 'templateId'),
            createdBy: any(named: 'createdBy'),
          ),
        );
      },
    );

    test('delegates to the repository once the mapping is valid', () async {
      final mapping = ProductImportMapping(
        hasHeaderRow: true,
        columnByField: const <ProductImportField, int>{
          ProductImportField.sku: 0,
          ProductImportField.reference: 1,
          ProductImportField.name: 2,
          ProductImportField.colorName: 3,
          ProductImportField.sizeLabel: 4,
        },
        sizeGridTemplateId: 'grid-1',
      );
      final job = ProductImportJob(
        id: 'job-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        fileName: 'produtos.csv',
        storagePath: 'organizations/org-1/productImports/job-1/source_produtos.csv',
        status: ProductImportJobStatus.queued,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
      );
      when(
        () => repository.startJob(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          fileName: any(named: 'fileName'),
          isXlsx: any(named: 'isXlsx'),
          fileBytes: any(named: 'fileBytes'),
          mapping: any(named: 'mapping'),
          lookup: any(named: 'lookup'),
          createMissingCategories: any(named: 'createMissingCategories'),
          createMissingCollections: any(named: 'createMissingCollections'),
          imageBytesByFileName: any(named: 'imageBytesByFileName'),
          templateId: any(named: 'templateId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<ProductImportJob>(job));

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        fileName: 'produtos.csv',
        isXlsx: false,
        fileBytes: Uint8List(0),
        mapping: mapping,
        lookup: const ProductImportLookup(),
        createMissingCategories: false,
        createMissingCollections: false,
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<ProductImportJob>>());
      verify(
        () => repository.startJob(
          organizationId: 'org-1',
          companyId: 'company-1',
          fileName: 'produtos.csv',
          isXlsx: false,
          fileBytes: any(named: 'fileBytes'),
          mapping: mapping,
          lookup: const ProductImportLookup(),
          createMissingCategories: false,
          createMissingCollections: false,
          imageBytesByFileName: null,
          templateId: null,
          createdBy: 'user-1',
        ),
      ).called(1);
    });
  });
}
