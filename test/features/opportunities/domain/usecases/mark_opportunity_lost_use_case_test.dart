import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

void main() {
  group('MarkOpportunityLostUseCase', () {
    late _MockOpportunityRepository repository;
    late MarkOpportunityLostUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildOpportunity(status: OpportunityStatus.open));
    });

    setUp(() {
      repository = _MockOpportunityRepository();
      useCase = MarkOpportunityLostUseCase(repository);
    });

    test('marks an open opportunity as lost with a reason', () async {
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
        lostReason: 'Concorrente com preço menor',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Opportunity>>());
      final updated = (result as AppSuccess<Opportunity>).value;
      expect(updated.status, OpportunityStatus.lost);
      expect(updated.lostReason, 'Concorrente com preço menor');
      expect(updated.closedAt, isNotNull);
      expect(updated.version, opportunity.version + 1);
    });

    test(
      'moves the opportunity onto the given stageId (TASK-058 board close)',
      () async {
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
          lostReason: 'Concorrente com preço menor',
          updatedBy: 'user-2',
          stageId: 'stage-lost',
        );

        final updated = (result as AppSuccess<Opportunity>).value;
        expect(updated.stageId, 'stage-lost');
      },
    );

    test('rejects marking as lost without a reason', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        lostReason: '',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      final failure = (result as AppFailure<Opportunity>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('lostReason', 'Lost reason is required.'),
      );
      verifyNever(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
    });

    test('blocks marking an already-lost opportunity as lost again', () async {
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
        lostReason: 'Motivo qualquer',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
    });

    test('blocks marking a won opportunity as lost', () async {
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
        lostReason: 'Motivo qualquer',
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
