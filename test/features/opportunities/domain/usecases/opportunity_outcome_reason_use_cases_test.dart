import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  group('Opportunity outcome reason use cases', () {
    late _InMemoryOutcomeReasonRepository reasonRepository;
    late _InMemoryOpportunityRepository opportunityRepository;

    setUp(() {
      reasonRepository = _InMemoryOutcomeReasonRepository();
      opportunityRepository = _InMemoryOpportunityRepository();
    });

    test(
      'creates a configurable reason scoped by organization and type',
      () async {
        final useCase = CreateOpportunityOutcomeReasonUseCase(reasonRepository);

        final result = await useCase.call(
          id: 'reason-won-1',
          organizationId: 'org-1',
          type: OpportunityOutcomeType.won,
          description: ' Produto aderente a colecao ',
          createdBy: 'admin-1',
        );

        expect(result, isA<AppSuccess<OpportunityOutcomeReason>>());
        final created = (result as AppSuccess<OpportunityOutcomeReason>).value;
        expect(created.description, 'Produto aderente a colecao');
        expect(created.type, OpportunityOutcomeType.won);
        expect(created.isActive, isTrue);
      },
    );

    test(
      'deactivation hides a reason from active selection but keeps it in history',
      () async {
        reasonRepository.seed(
          _reason(
            id: 'reason-lost-1',
            type: OpportunityOutcomeType.lost,
            description: 'Sem verba no ciclo',
          ),
        );

        final deactivate = DeactivateOpportunityOutcomeReasonUseCase(
          reasonRepository,
        );
        final list = ListOpportunityOutcomeReasonsUseCase(reasonRepository);

        final result = await deactivate(
          organizationId: 'org-1',
          id: 'reason-lost-1',
          updatedBy: 'admin-1',
        );

        expect(result, isA<AppSuccess<OpportunityOutcomeReason>>());
        final active = await list(
          organizationId: 'org-1',
          type: OpportunityOutcomeType.lost,
        );
        expect(
          (active as AppSuccess<List<OpportunityOutcomeReason>>).value,
          isEmpty,
        );

        final historical = await list(
          organizationId: 'org-1',
          type: OpportunityOutcomeType.lost,
          includeInactive: true,
        );
        final reasons =
            (historical as AppSuccess<List<OpportunityOutcomeReason>>).value;
        expect(reasons.single.id, 'reason-lost-1');
        expect(reasons.single.isActive, isFalse);
      },
    );

    test(
      'rejects duplicated descriptions within the same outcome type',
      () async {
        reasonRepository.seed(
          _reason(
            id: 'reason-won-1',
            type: OpportunityOutcomeType.won,
            description: 'Mix de produto',
          ),
        );
        final useCase = CreateOpportunityOutcomeReasonUseCase(reasonRepository);

        final result = await useCase.call(
          id: 'reason-won-2',
          organizationId: 'org-1',
          type: OpportunityOutcomeType.won,
          description: ' mix de produto ',
          createdBy: 'admin-1',
        );

        expect(result, isA<AppFailure<OpportunityOutcomeReason>>());
        expect(
          (result as AppFailure<OpportunityOutcomeReason>).failure,
          isA<ConflictFailure>(),
        );
      },
    );

    test('aggregates the most frequent reasons by period and type', () async {
      reasonRepository
        ..seed(
          _reason(
            id: 'reason-lost-1',
            type: OpportunityOutcomeType.lost,
            description: 'Concorrente',
            isActive: false,
          ),
        )
        ..seed(
          _reason(
            id: 'reason-lost-2',
            type: OpportunityOutcomeType.lost,
            description: 'Sem verba',
          ),
        );
      opportunityRepository
        ..seed(
          _opportunity(
            id: 'opp-1',
            status: OpportunityStatus.lost,
            closedAt: DateTime.utc(2026, 8, 5),
            lostReasonId: 'reason-lost-1',
            lostReason: 'Concorrente',
          ),
        )
        ..seed(
          _opportunity(
            id: 'opp-2',
            status: OpportunityStatus.lost,
            closedAt: DateTime.utc(2026, 8, 6),
            lostReasonId: 'reason-lost-1',
            lostReason: 'Concorrente',
          ),
        )
        ..seed(
          _opportunity(
            id: 'opp-3',
            status: OpportunityStatus.lost,
            closedAt: DateTime.utc(2026, 8, 7),
            lostReasonId: 'reason-lost-2',
            lostReason: 'Sem verba',
          ),
        )
        ..seed(
          _opportunity(
            id: 'opp-open',
            status: OpportunityStatus.open,
            closedAt: null,
          ),
        );
      final useCase = ListTopOpportunityOutcomeReasonsUseCase(
        reasonRepository,
        opportunityRepository,
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        type: OpportunityOutcomeType.lost,
        from: DateTime.utc(2026, 8),
        to: DateTime.utc(2026, 8, 31, 23, 59, 59),
      );

      expect(result, isA<AppSuccess<List<OpportunityOutcomeReasonUsage>>>());
      final ranking =
          (result as AppSuccess<List<OpportunityOutcomeReasonUsage>>).value;
      expect(ranking.map((entry) => entry.reasonId), <String>[
        'reason-lost-1',
        'reason-lost-2',
      ]);
      expect(ranking.first.count, 2);
      expect(ranking.first.description, 'Concorrente');
    });
  });
}

OpportunityOutcomeReason _reason({
  required String id,
  required OpportunityOutcomeType type,
  required String description,
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
    createdBy: 'admin-1',
    updatedAt: now,
    updatedBy: 'admin-1',
    version: 1,
  );
}

Opportunity _opportunity({
  required String id,
  required OpportunityStatus status,
  DateTime? closedAt,
  String? wonReasonId,
  String? wonReason,
  String? lostReasonId,
  String? lostReason,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: id,
    organizationId: 'org-1',
    title: 'Oportunidade $id',
    customerId: 'customer-1',
    estimatedValue: 1000,
    probability: 50,
    revenueForecast: 500,
    responsibleUserId: 'user-1',
    stageId: 'stage-1',
    status: status,
    expectedCloseDate: DateTime.utc(2026, 9, 1),
    wonReasonId: wonReasonId,
    wonReason: wonReason,
    lostReasonId: lostReasonId,
    lostReason: lostReason,
    closedAt: closedAt,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
}

final class _InMemoryOutcomeReasonRepository
    implements OpportunityOutcomeReasonRepository {
  final List<OpportunityOutcomeReason> reasons = <OpportunityOutcomeReason>[];

  void seed(OpportunityOutcomeReason reason) => reasons.add(reason);

  @override
  Future<AppResult<OpportunityOutcomeReason>> create({
    required OpportunityOutcomeReason reason,
  }) async {
    reasons.add(reason);
    return AppSuccess<OpportunityOutcomeReason>(reason);
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> update({
    required OpportunityOutcomeReason reason,
  }) async {
    final index = reasons.indexWhere((existing) => existing.id == reason.id);
    if (index == -1) {
      return const AppFailure<OpportunityOutcomeReason>(
        NotFoundFailure(
          'Opportunity outcome reason not found.',
          code: 'opportunity_outcome_reason_not_found',
        ),
      );
    }
    reasons[index] = reason;
    return AppSuccess<OpportunityOutcomeReason>(reason);
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final reason in reasons) {
      if (reason.organizationId == organizationId && reason.id == id) {
        return AppSuccess<OpportunityOutcomeReason>(reason);
      }
    }
    return const AppFailure<OpportunityOutcomeReason>(
      NotFoundFailure(
        'Opportunity outcome reason not found.',
        code: 'opportunity_outcome_reason_not_found',
      ),
    );
  }

  @override
  Future<AppResult<List<OpportunityOutcomeReason>>> listByOrganization({
    required String organizationId,
    OpportunityOutcomeType? type,
    bool includeInactive = false,
  }) async {
    final visible = reasons
        .where(
          (reason) =>
              reason.organizationId == organizationId &&
              (type == null || reason.type == type) &&
              (includeInactive || reason.isActive),
        )
        .toList(growable: false);
    return AppSuccess<List<OpportunityOutcomeReason>>(visible);
  }
}

final class _InMemoryOpportunityRepository implements OpportunityRepository {
  final List<Opportunity> opportunities = <Opportunity>[];

  void seed(Opportunity opportunity) => opportunities.add(opportunity);

  @override
  Future<AppResult<Opportunity>> create({
    required Opportunity opportunity,
  }) async {
    opportunities.add(opportunity);
    return AppSuccess<Opportunity>(opportunity);
  }

  @override
  Future<AppResult<Opportunity>> update({
    required Opportunity opportunity,
  }) async {
    final index = opportunities.indexWhere(
      (existing) => existing.id == opportunity.id,
    );
    if (index == -1) {
      return const AppFailure<Opportunity>(
        NotFoundFailure(
          'Opportunity not found.',
          code: 'opportunity_not_found',
        ),
      );
    }
    opportunities[index] = opportunity;
    return AppSuccess<Opportunity>(opportunity);
  }

  @override
  Future<AppResult<Opportunity>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final opportunity in opportunities) {
      if (opportunity.organizationId == organizationId &&
          opportunity.id == id) {
        return AppSuccess<Opportunity>(opportunity);
      }
    }
    return const AppFailure<Opportunity>(
      NotFoundFailure('Opportunity not found.', code: 'opportunity_not_found'),
    );
  }

  @override
  Future<AppResult<List<Opportunity>>> listByOrganization({
    required String organizationId,
    String? companyId,
    Set<String> responsibleUserIds = const <String>{},
  }) async {
    final visible = opportunities
        .where((opportunity) => opportunity.organizationId == organizationId)
        .toList(growable: false);
    return AppSuccess<List<Opportunity>>(visible);
  }
}
