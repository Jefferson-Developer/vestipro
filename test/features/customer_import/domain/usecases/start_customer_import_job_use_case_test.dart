import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customer_import/customer_import.dart';

class _MockCustomerImportJobRepository extends Mock
    implements CustomerImportJobRepository {}

void main() {
  group('StartCustomerImportJobUseCase', () {
    late _MockCustomerImportJobRepository repository;
    late StartCustomerImportJobUseCase useCase;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        const CustomerImportMapping(
          hasHeaderRow: true,
          columnByField: <CustomerImportField, int>{
            CustomerImportField.document: 0,
          },
        ),
      );
    });

    setUp(() {
      repository = _MockCustomerImportJobRepository();
      useCase = StartCustomerImportJobUseCase(repository);
    });

    test(
      'never calls the repository when the mapping is missing a document column',
      () async {
        final mapping = CustomerImportMapping(
          hasHeaderRow: true,
          columnByField: const <CustomerImportField, int>{
            CustomerImportField.legalName: 0,
          },
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          fileName: 'clientes.csv',
          isXlsx: false,
          fileBytes: Uint8List(0),
          mapping: mapping,
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<CustomerImportJob>>());
        verifyNever(
          () => repository.startJob(
            organizationId: any(named: 'organizationId'),
            companyId: any(named: 'companyId'),
            fileName: any(named: 'fileName'),
            isXlsx: any(named: 'isXlsx'),
            fileBytes: any(named: 'fileBytes'),
            mapping: any(named: 'mapping'),
            templateId: any(named: 'templateId'),
            createdBy: any(named: 'createdBy'),
          ),
        );
      },
    );

    test('delegates to the repository once the mapping is valid', () async {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
          CustomerImportField.legalName: 1,
        },
      );
      final job = CustomerImportJob(
        id: 'job-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        fileName: 'clientes.csv',
        storagePath:
            'organizations/org-1/customerImports/job-1/source_clientes.csv',
        mapping: mapping,
        status: CustomerImportJobStatus.queued,
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
          templateId: any(named: 'templateId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<CustomerImportJob>(job));

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        fileName: 'clientes.csv',
        isXlsx: false,
        fileBytes: Uint8List(0),
        mapping: mapping,
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<CustomerImportJob>>());
      verify(
        () => repository.startJob(
          organizationId: 'org-1',
          companyId: 'company-1',
          fileName: 'clientes.csv',
          isXlsx: false,
          fileBytes: any(named: 'fileBytes'),
          mapping: mapping,
          templateId: null,
          createdBy: 'user-1',
        ),
      ).called(1);
    });
  });
}
