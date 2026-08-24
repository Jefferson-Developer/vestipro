import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

class _MockOutcomeReasonRepository extends Mock
    implements OpportunityOutcomeReasonRepository {}

void main() {
  group('MarkOpportunityWonUseCase', () {
    late _MockOpportunityRepository repository;
    late _MockOutcomeReasonRepository reasonRepository;
    late MarkOpportunityWonUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildOpportunity(status: OpportunityStatus.open));
    });

    setUp(() {
      repository = _MockOpportunityRepository();
      reasonRepository = _MockOutcomeReasonRepository();
      useCase = MarkOpportunityWonUseCase(repository, reasonRepository);
    });

    test(
      'marks an open opportunity as won with an active won reason',
      () async {
        final opportunity = _buildOpportunity(status: OpportunityStatus.open);
        _stubOpportunity(repository, opportunity);
        _stubReason(
          reasonRepository,
          _reason(
            id: 'reason-won-1',
            type: OpportunityOutcomeType.won,
            description: 'Preço competitivo e prazo de entrega',
          ),
        );
        _stubUpdate(repository);

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'opportunity-1',
          reasonId: 'reason-won-1',
          note: 'Cliente aprovou a grade completa',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Opportunity>>());
        final updated = (result as AppSuccess<Opportunity>).value;
        expect(updated.status, OpportunityStatus.won);
        expect(updated.wonReasonId, 'reason-won-1');
        expect(updated.wonReason, 'Preço competitivo e prazo de entrega');
        expect(updated.wonReasonNote, 'Cliente aprovou a grade completa');
        expect(updated.closedAt, isNotNull);
        expect(updated.version, opportunity.version + 1);
      },
    );

    test(
      'moves the opportunity onto the given stageId (TASK-058 board close)',
      () async {
        final opportunity = _buildOpportunity(status: OpportunityStatus.open);
        _stubOpportunity(repository, opportunity);
        _stubReason(
          reasonRepository,
          _reason(id: 'reason-won-1', type: OpportunityOutcomeType.won),
        );
        _stubUpdate(repository);

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'opportunity-1',
          reasonId: 'reason-won-1',
          updatedBy: 'user-2',
          stageId: 'stage-won',
        );

        final updated = (result as AppSuccess<Opportunity>).value;
        expect(updated.stageId, 'stage-won');
      },
    );

    test('rejects marking as won without a reason id', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        reasonId: '   ',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      final failure = (result as AppFailure<Opportunity>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('reasonId', 'ReasonId is required.'),
      );
      verifyNever(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
      verifyNever(
        () => reasonRepository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
    });

    test('rejects a lost reason when marking as won', () async {
      final opportunity = _buildOpportunity(status: OpportunityStatus.open);
      _stubOpportunity(repository, opportunity);
      _stubReason(
        reasonRepository,
        _reason(id: 'reason-lost-1', type: OpportunityOutcomeType.lost),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        reasonId: 'reason-lost-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      expect(
        (result as AppFailure<Opportunity>).failure.code,
        'opportunity_outcome_reason_type_mismatch',
      );
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
    });

    test('blocks marking an already-won opportunity as won again', () async {
      final opportunity = _buildOpportunity(status: OpportunityStatus.won);
      _stubOpportunity(repository, opportunity);

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        reasonId: 'reason-won-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Opportunity>>());
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
      verifyNever(
        () => reasonRepository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
    });
  });
}

void _stubOpportunity(
  _MockOpportunityRepository repository,
  Opportunity opportunity,
) {
  when(
    () => repository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));
}

void _stubReason(
  _MockOutcomeReasonRepository repository,
  OpportunityOutcomeReason reason,
) {
  when(
    () => repository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<OpportunityOutcomeReason>(reason));
}

void _stubUpdate(_MockOpportunityRepository repository) {
  when(
    () => repository.update(opportunity: any(named: 'opportunity')),
  ).thenAnswer((invocation) async {
    return AppSuccess<Opportunity>(
      invocation.namedArguments[#opportunity] as Opportunity,
    );
  });
}

OpportunityOutcomeReason _reason({
  required String id,
  required OpportunityOutcomeType type,
  String description = 'Motivo configurado',
  bool isActive = true,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return OpportunityOutcomeReason(
    id: id,
    organizationId: 'org-1',
    type: type,
    description: description,
    isActive: isActive,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
  );
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
