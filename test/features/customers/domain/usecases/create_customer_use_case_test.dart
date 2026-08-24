import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  group('CreateCustomerUseCase', () {
    late _MockCustomerRepository repository;
    late CreateCustomerUseCase useCase;

    setUpAll(() {
      registerFallbackValue(CnpjCpf.parse('04.252.011/0001-10'));
      registerFallbackValue(_buildCustomer());
    });

    setUp(() {
      repository = _MockCustomerRepository();
      useCase = CreateCustomerUseCase(repository);
    });

    test(
      'creates a customer after trimming and validating the payload',
      () async {
        when(
          () => repository.existsByDocument(
            organizationId: any(named: 'organizationId'),
            document: any(named: 'document'),
          ),
        ).thenAnswer((_) async => const AppSuccess<bool>(false));
        when(
          () => repository.create(customer: any(named: 'customer')),
        ).thenAnswer((_) async => AppSuccess<Customer>(_buildCustomer()));

        final result = await useCase.call(
          id: ' customer-1 ',
          organizationId: ' org-1 ',
          companyId: ' company-1 ',
          type: CustomerType.legalEntity,
          document: ' 04.252.011/0001-10 ',
          legalName: ' Moda Sul Confeccoes Ltda ',
          tradeName: ' Moda Sul ',
          primaryEmail: ' compras@modasul.test ',
          primaryPhone: ' +55 47 99999-0000 ',
          classification: ' tier-a ',
          potential: ' high ',
          segment: ' multimarcas ',
          originChannel: ' field_sales ',
          responsibleSellerId: ' user-1 ',
          tags: const <String>[' vip ', '', 'vip', 'showroom'],
          customFields: const <String, Object?>{
            ' regionalCode ': 'SC-01',
            ' ': 'ignored',
          },
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Customer>>());
        final captured =
            verify(
                  () => repository.create(
                    customer: captureAny(named: 'customer'),
                  ),
                ).captured.single
                as Customer;
        expect(captured.id, 'customer-1');
        expect(captured.organizationId, 'org-1');
        expect(captured.companyId, 'company-1');
        expect(captured.document.digits, '04252011000110');
        expect(captured.legalName, 'Moda Sul Confeccoes Ltda');
        expect(captured.tradeName, 'Moda Sul');
        expect(captured.status, CustomerStatus.prospect);
        expect(captured.tags, const <String>['vip', 'showroom']);
        expect(captured.customFields, const <String, Object?>{
          'regionalCode': 'SC-01',
        });
        expect(captured.createdBy, 'user-1');
        expect(captured.updatedBy, 'user-1');
        expect(captured.version, 1);
        expect(captured.syncStatus, CustomerSyncStatus.pending);
      },
    );

    test('blocks duplicate documents inside the same organization', () async {
      when(
        () => repository.existsByDocument(
          organizationId: any(named: 'organizationId'),
          document: any(named: 'document'),
        ),
      ).thenAnswer((_) async => const AppSuccess<bool>(true));

      final result = await useCase.call(
        id: 'customer-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        type: CustomerType.legalEntity,
        document: '04.252.011/0001-10',
        legalName: 'Moda Sul Confeccoes Ltda',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Customer>>());
      expect((result as AppFailure<Customer>).failure, isA<ConflictFailure>());
      verifyNever(() => repository.create(customer: any(named: 'customer')));
    });

    test(
      'rejects a legal entity with a CPF before hitting the repository',
      () async {
        final result = await useCase.call(
          id: 'customer-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          type: CustomerType.legalEntity,
          document: '529.982.247-25',
          legalName: 'Ana Souza ME',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Customer>>());
        final failure = (result as AppFailure<Customer>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors['document'],
          'Legal entities require a valid CNPJ.',
        );
        verifyNever(
          () => repository.existsByDocument(
            organizationId: any(named: 'organizationId'),
            document: any(named: 'document'),
          ),
        );
        verifyNever(() => repository.create(customer: any(named: 'customer')));
      },
    );

    test(
      'rejects an individual with a CNPJ before hitting the repository',
      () async {
        final result = await useCase.call(
          id: 'customer-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          type: CustomerType.individual,
          document: '04.252.011/0001-10',
          fullName: 'Ana Souza',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Customer>>());
        final failure = (result as AppFailure<Customer>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors['document'],
          'Individuals require a valid CPF.',
        );
        verifyNever(
          () => repository.existsByDocument(
            organizationId: any(named: 'organizationId'),
            document: any(named: 'document'),
          ),
        );
        verifyNever(() => repository.create(customer: any(named: 'customer')));
      },
    );

    test('rejects an absent or invalid organization id', () async {
      final result = await useCase.call(
        id: 'customer-1',
        organizationId: '  ',
        companyId: 'company-1',
        type: CustomerType.individual,
        document: '529.982.247-25',
        fullName: 'Ana Souza',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Customer>>());
      final failure = (result as AppFailure<Customer>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('organizationId', 'OrganizationId is required.'),
      );
      verifyNever(
        () => repository.existsByDocument(
          organizationId: any(named: 'organizationId'),
          document: any(named: 'document'),
        ),
      );
      verifyNever(() => repository.create(customer: any(named: 'customer')));
    });
  });
}

Customer _buildCustomer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Moda Sul Confeccoes Ltda',
    tradeName: 'Moda Sul',
    status: CustomerStatus.prospect,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}
