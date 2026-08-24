import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/leads/leads.dart';

class _MockLeadRepository extends Mock implements LeadRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  group('ConvertLeadToCustomerUseCase', () {
    late _MockLeadRepository leadRepository;
    late _MockCustomerRepository customerRepository;
    late ConvertLeadToCustomerUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildLead(status: LeadStatus.qualified));
      registerFallbackValue(CnpjCpf.parse('04.252.011/0001-10'));
      registerFallbackValue(_buildCustomer());
    });

    setUp(() {
      leadRepository = _MockLeadRepository();
      customerRepository = _MockCustomerRepository();
      useCase = ConvertLeadToCustomerUseCase(
        leadRepository,
        CreateCustomerUseCase(customerRepository),
      );
    });

    test(
      'converts a qualified lead into a customer with sourceLeadId set',
      () async {
        final lead = _buildLead(status: LeadStatus.qualified);
        when(
          () => leadRepository.getById(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
          ),
        ).thenAnswer((_) async => AppSuccess<Lead>(lead));
        when(
          () => customerRepository.existsByDocument(
            organizationId: any(named: 'organizationId'),
            document: any(named: 'document'),
          ),
        ).thenAnswer((_) async => const AppSuccess<bool>(false));
        when(
          () => customerRepository.create(customer: any(named: 'customer')),
        ).thenAnswer((invocation) async {
          return AppSuccess<Customer>(
            invocation.namedArguments[#customer] as Customer,
          );
        });
        when(() => leadRepository.update(lead: any(named: 'lead'))).thenAnswer((
          invocation,
        ) async {
          return AppSuccess<Lead>(invocation.namedArguments[#lead] as Lead);
        });

        final result = await useCase.call(
          organizationId: 'org-1',
          leadId: 'lead-1',
          customerId: 'customer-1',
          companyId: 'company-1',
          customerType: CustomerType.legalEntity,
          document: '04.252.011/0001-10',
          legalName: 'Loja Vitrine Moda Ltda',
          tradeName: 'Loja Vitrine Moda',
          convertedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<LeadToCustomerConversion>>());
        final conversion =
            (result as AppSuccess<LeadToCustomerConversion>).value;
        expect(conversion.customer.sourceLeadId, 'lead-1');
        expect(conversion.lead.status, LeadStatus.converted);
        expect(conversion.lead.convertedCustomerId, 'customer-1');
        expect(conversion.lead.convertedAt, isNotNull);
        expect(conversion.lead.version, lead.version + 1);
      },
    );

    test('blocks converting a lead that is not qualified yet', () async {
      final lead = _buildLead(status: LeadStatus.contacted);
      when(
        () => leadRepository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Lead>(lead));

      final result = await useCase.call(
        organizationId: 'org-1',
        leadId: 'lead-1',
        customerId: 'customer-1',
        companyId: 'company-1',
        customerType: CustomerType.legalEntity,
        document: '04.252.011/0001-10',
        legalName: 'Loja Vitrine Moda Ltda',
        convertedBy: 'user-2',
      );

      expect(result, isA<AppFailure<LeadToCustomerConversion>>());
      expect(
        (result as AppFailure<LeadToCustomerConversion>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => customerRepository.create(customer: any(named: 'customer')),
      );
      verifyNever(() => leadRepository.update(lead: any(named: 'lead')));
    });
  });
}

Lead _buildLead({required LeadStatus status}) {
  final now = DateTime.utc(2026, 1, 1);
  return Lead(
    id: 'lead-1',
    organizationId: 'org-1',
    name: 'Loja Vitrine Moda',
    source: LeadSource.website,
    responsibleUserId: 'user-1',
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}

Customer _buildCustomer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Loja Vitrine Moda Ltda',
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
