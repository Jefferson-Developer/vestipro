import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';

class _MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  group('ConvertLeadToOpportunityUseCase', () {
    late _MockLeadRepository repository;
    late ConvertLeadToOpportunityUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildLead(status: LeadStatus.qualified));
    });

    setUp(() {
      repository = _MockLeadRepository();
      useCase = ConvertLeadToOpportunityUseCase(repository);
    });

    test(
      'converts a qualified lead, linking the given opportunityId',
      () async {
        final lead = _buildLead(status: LeadStatus.qualified);
        when(
          () => repository.getById(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
          ),
        ).thenAnswer((_) async => AppSuccess<Lead>(lead));
        when(() => repository.update(lead: any(named: 'lead'))).thenAnswer((
          invocation,
        ) async {
          return AppSuccess<Lead>(invocation.namedArguments[#lead] as Lead);
        });

        final result = await useCase.call(
          organizationId: 'org-1',
          leadId: 'lead-1',
          opportunityId: 'opportunity-1',
          convertedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Lead>>());
        final updated = (result as AppSuccess<Lead>).value;
        expect(updated.status, LeadStatus.converted);
        expect(updated.convertedOpportunityId, 'opportunity-1');
        expect(updated.convertedAt, isNotNull);
        expect(updated.version, lead.version + 1);
      },
    );

    test('blocks converting a lead that is not qualified yet', () async {
      final lead = _buildLead(status: LeadStatus.newLead);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Lead>(lead));

      final result = await useCase.call(
        organizationId: 'org-1',
        leadId: 'lead-1',
        opportunityId: 'opportunity-1',
        convertedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Lead>>());
      verifyNever(() => repository.update(lead: any(named: 'lead')));
    });

    test('rejects an empty opportunityId', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        leadId: 'lead-1',
        opportunityId: '   ',
        convertedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Lead>>());
      final failure = (result as AppFailure<Lead>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('opportunityId', 'OpportunityId is required.'),
      );
      verifyNever(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
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
