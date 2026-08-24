import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

void main() {
  group('UpdateOpportunityStageUseCase', () {
    late _MockOpportunityRepository repository;
    late UpdateOpportunityStageUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildOpportunity(status: OpportunityStatus.open));
    });

    setUp(() {
      repository = _MockOpportunityRepository();
      useCase = UpdateOpportunityStageUseCase(repository);
    });

    test('moves an open opportunity to a new stage', () async {
      final opportunity = _buildOpportunity(status: OpportunityStatus.open);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));
      when(
        () => repository.update(opportunity: any(named: 'opportunity')),
      ).thenAnswer((invocation) async {
        return AppSuccess<Opportunity>(
          invocation.namedArguments[#opportunity] as Opportunity,
        );
      });

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        stageId: 'stage-negotiation',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Opportunity>>());
      final updated = (result as AppSuccess<Opportunity>).value;
      expect(updated.stageId, 'stage-negotiation');
      expect(updated.version, opportunity.version + 1);
    });

    test('blocks changing the stage of a won opportunity', () async {
      final opportunity = _buildOpportunity(status: OpportunityStatus.won);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        stageId: 'stage-negotiation',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      expect(
        (result as AppFailure<Opportunity>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
    });

    test('blocks changing the stage of a lost opportunity', () async {
      final opportunity = _buildOpportunity(status: OpportunityStatus.lost);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        stageId: 'stage-negotiation',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
    });
  });
}

Opportunity _buildOpportunity({required OpportunityStatus status}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: 'opportunity-1',
    organizationId: 'org-1',
    title: 'Reposição de inverno',
    customerId: 'customer-1',
    estimatedValue: 1000,
    probability: 50,
    revenueForecast: 500,
    responsibleUserId: 'user-1',
    stageId: 'stage-qualification',
    status: status,
    expectedCloseDate: DateTime.utc(2026, 2, 1),
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
}
