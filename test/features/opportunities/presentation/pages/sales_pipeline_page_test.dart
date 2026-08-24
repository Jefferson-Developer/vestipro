import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('SalesPipelinePage', () {
    late _MockMembershipRepository membershipRepository;
    late _InMemoryOpportunityRepository opportunityRepository;
    late _InMemoryPipelineStageRepository stageRepository;
    late _InMemoryOutcomeReasonRepository reasonRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      opportunityRepository = _InMemoryOpportunityRepository();
      stageRepository = _InMemoryPipelineStageRepository();
      reasonRepository = _InMemoryOutcomeReasonRepository();
      permissionService = PermissionService(membershipRepository);
      _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');

      stageRepository
        ..seed(_stage(id: 'stage-negotiation', name: 'Negociacao', order: 0))
        ..seed(_stage(id: 'stage-proposal', name: 'Proposta', order: 1));
      opportunityRepository.seed(
        _opportunity(
          id: 'opp-1',
          title: 'Boutique Aurora',
          stageId: 'stage-negotiation',
        ),
      );
    });

    SalesPipelineBloc buildBloc() {
      return SalesPipelineBloc(
        listStages: ListPipelineStagesUseCase(stageRepository),
        listOutcomeReasons: ListOpportunityOutcomeReasonsUseCase(
          reasonRepository,
        ),
        listOpportunities: ListPipelineOpportunitiesUseCase(
          opportunityRepository,
        ),
        updateStage: UpdateOpportunityStageUseCase(opportunityRepository),
        markWon: MarkOpportunityWonUseCase(
          opportunityRepository,
          reasonRepository,
        ),
        markLost: MarkOpportunityLostUseCase(
          opportunityRepository,
          reasonRepository,
        ),
      );
    }

    Widget buildPage() {
      return SalesPipelinePage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders forbidden for a role without opportunity.view', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_ASSISTANT');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets(
      'Web: dragging an opportunity card into another column moves it and '
      'updates the count/value of both stages',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sales-pipeline-board')), findsOneWidget);
        expect(find.text('Boutique Aurora'), findsOneWidget);
        _expectColumnCount(tester, stageId: 'stage-negotiation', count: 1);
        _expectColumnCount(tester, stageId: 'stage-proposal', count: 0);

        final source = find.byKey(const Key('pipeline-card-opp-1'));
        final target = find.byKey(const Key('pipeline-column-stage-proposal'));
        final gesture = await tester.startGesture(tester.getCenter(source));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(tester.getCenter(target));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(
          opportunityRepository.opportunities.single.stageId,
          'stage-proposal',
        );
        _expectColumnCount(tester, stageId: 'stage-negotiation', count: 0);
        _expectColumnCount(tester, stageId: 'stage-proposal', count: 1);
      },
    );

    testWidgets(
      'Mobile: moving an opportunity via the explicit "Mover" action (no '
      'gesture) moves it and updates the count of both stages',
      (tester) async {
        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(find.text('Boutique Aurora'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Mover'), findsOneWidget);
        _expectColumnCount(tester, stageId: 'stage-negotiation', count: 1);
        _expectColumnCount(tester, stageId: 'stage-proposal', count: 0);

        await tester.tap(find.widgetWithText(AppButton, 'Mover'));
        await tester.pumpAndSettle();

        expect(find.text('Proposta'), findsWidgets);
        await tester.tap(find.text('Proposta').last);
        await tester.pumpAndSettle();

        expect(
          opportunityRepository.opportunities.single.stageId,
          'stage-proposal',
        );
        _expectColumnCount(tester, stageId: 'stage-negotiation', count: 0);
        _expectColumnCount(tester, stageId: 'stage-proposal', count: 1);
      },
    );

    testWidgets(
      'Mobile: closing on a terminal stage requires an active catalog reason',
      (tester) async {
        stageRepository.seed(
          _stage(
            id: 'stage-won',
            name: 'Ganha',
            order: 2,
            terminalType: PipelineStageTerminalType.won,
          ),
        );
        reasonRepository.seed(
          _reason(
            id: 'reason-won-1',
            type: OpportunityOutcomeType.won,
            description: 'Produto aderente a colecao',
          ),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Mover'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ganha').last);
        await tester.pumpAndSettle();
        expect(find.text('Produto aderente a colecao'), findsOneWidget);

        await tester.tap(find.widgetWithText(AppButton, 'Marcar como ganha'));
        await tester.pumpAndSettle();

        final updated = opportunityRepository.opportunities.single;
        expect(updated.status, OpportunityStatus.won);
        expect(updated.stageId, 'stage-won');
        expect(updated.wonReasonId, 'reason-won-1');
        expect(updated.wonReason, 'Produto aderente a colecao');
      },
    );
  });
}

void _expectColumnCount(
  WidgetTester tester, {
  required String stageId,
  required int count,
}) {
  final header = find.byKey(Key('pipeline-column-header-$stageId'));
  expect(header, findsOneWidget);
  expect(
    find.descendant(
      of: header,
      matching: find.textContaining('$count oportunidades'),
    ),
    findsOneWidget,
  );
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

PipelineStage _stage({
  required String id,
  required String name,
  required int order,
  PipelineStageTerminalType terminalType = PipelineStageTerminalType.none,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PipelineStage(
    id: id,
    organizationId: 'org-1',
    name: name,
    order: order,
    colorHex: '#2563EB',
    terminalType: terminalType,
    createdAt: now,
    createdBy: 'current-user',
    updatedAt: now,
    updatedBy: 'current-user',
    version: 1,
  );
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
    createdBy: 'current-user',
    updatedAt: now,
    updatedBy: 'current-user',
    version: 1,
  );
}

Opportunity _opportunity({
  required String id,
  required String title,
  required String stageId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: id,
    organizationId: 'org-1',
    title: title,
    customerId: 'customer-1',
    estimatedValue: 1000,
    probability: 50,
    revenueForecast: 500,
    responsibleUserId: 'current-user',
    stageId: stageId,
    status: OpportunityStatus.open,
    expectedCloseDate: DateTime.utc(2026, 2, 1),
    createdAt: now,
    createdBy: 'current-user',
    updatedAt: now,
    updatedBy: 'current-user',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
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
      if (opportunity.id == id) return AppSuccess<Opportunity>(opportunity);
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

final class _InMemoryPipelineStageRepository
    implements PipelineStageRepository {
  final List<PipelineStage> stages = <PipelineStage>[];

  void seed(PipelineStage stage) => stages.add(stage);

  @override
  Future<AppResult<PipelineStage>> create({
    required PipelineStage stage,
  }) async {
    stages.add(stage);
    return AppSuccess<PipelineStage>(stage);
  }

  @override
  Future<AppResult<PipelineStage>> update({
    required PipelineStage stage,
  }) async {
    final index = stages.indexWhere((existing) => existing.id == stage.id);
    if (index == -1) {
      return const AppFailure<PipelineStage>(
        NotFoundFailure(
          'Pipeline stage not found.',
          code: 'pipeline_stage_not_found',
        ),
      );
    }
    stages[index] = stage;
    return AppSuccess<PipelineStage>(stage);
  }

  @override
  Future<AppResult<List<PipelineStage>>> listByOrganization({
    required String organizationId,
  }) async {
    final visible = stages
        .where((stage) => stage.organizationId == organizationId)
        .toList(growable: false);
    return AppSuccess<List<PipelineStage>>(visible);
  }

  @override
  Future<AppResult<List<PipelineStage>>> reorder({
    required String organizationId,
    required List<String> orderedStageIds,
    required String updatedBy,
  }) async {
    final byId = <String, PipelineStage>{
      for (final stage in stages) stage.id: stage,
    };
    final reordered = <PipelineStage>[
      for (var index = 0; index < orderedStageIds.length; index++)
        byId[orderedStageIds[index]]!.copyWith(order: index),
    ];
    stages
      ..clear()
      ..addAll(reordered);
    return AppSuccess<List<PipelineStage>>(reordered);
  }
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
