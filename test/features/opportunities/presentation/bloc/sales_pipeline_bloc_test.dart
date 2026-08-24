import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

class _MockPipelineStageRepository extends Mock
    implements PipelineStageRepository {}

void main() {
  group('SalesPipelineBloc', () {
    late _MockOpportunityRepository opportunityRepository;
    late _MockPipelineStageRepository stageRepository;

    setUpAll(() {
      registerFallbackValue(_opportunity(status: OpportunityStatus.open));
    });

    setUp(() {
      opportunityRepository = _MockOpportunityRepository();
      stageRepository = _MockPipelineStageRepository();
    });

    SalesPipelineBloc buildBloc() {
      return SalesPipelineBloc(
        listStages: ListPipelineStagesUseCase(stageRepository),
        listOpportunities: ListPipelineOpportunitiesUseCase(
          opportunityRepository,
        ),
        updateStage: UpdateOpportunityStageUseCase(opportunityRepository),
        markWon: MarkOpportunityWonUseCase(opportunityRepository),
        markLost: MarkOpportunityLostUseCase(opportunityRepository),
      );
    }

    final stages = <PipelineStage>[
      _stage(id: 'stage-negotiation', order: 0),
      _stage(
        id: 'stage-won',
        order: 1,
        terminalType: PipelineStageTerminalType.won,
      ),
    ];

    blocTest<SalesPipelineBloc, SalesPipelineState>(
      'loads stages/opportunities and builds board columns on start',
      build: () {
        when(
          () => stageRepository.listByOrganization(
            organizationId: any(named: 'organizationId'),
          ),
        ).thenAnswer((_) async => AppSuccess<List<PipelineStage>>(stages));
        when(
          () => opportunityRepository.listByOrganization(
            organizationId: any(named: 'organizationId'),
            companyId: any(named: 'companyId'),
            responsibleUserIds: any(named: 'responsibleUserIds'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<Opportunity>>(<Opportunity>[
            _opportunity(
              id: 'opp-1',
              stageId: 'stage-negotiation',
              status: OpportunityStatus.open,
            ),
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SalesPipelineStarted(organizationId: 'org-1', userId: 'user-1'),
      ),
      expect: () => <Object>[
        isA<SalesPipelineState>().having(
          (state) => state.status,
          'status',
          SalesPipelineLoadStatus.loading,
        ),
        isA<SalesPipelineState>()
            .having(
              (state) => state.status,
              'status',
              SalesPipelineLoadStatus.ready,
            )
            .having(
              (state) => state.columns.map((c) => c.stage.id),
              'columns',
              <String>['stage-negotiation', 'stage-won'],
            )
            .having(
              (state) => state.columns.first.activeCount,
              'first column active count',
              1,
            ),
      ],
    );

    blocTest<SalesPipelineBloc, SalesPipelineState>(
      'rejects a direct move onto a terminal stage without calling any '
      'use case, instead of silently moving it',
      build: buildBloc,
      seed: () => SalesPipelineState(
        status: SalesPipelineLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'user-1',
        stages: stages,
        opportunities: <Opportunity>[
          _opportunity(
            id: 'opp-1',
            stageId: 'stage-negotiation',
            status: OpportunityStatus.open,
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        const SalesPipelineOpportunityMoveRequested(
          opportunityId: 'opp-1',
          targetStageId: 'stage-won',
        ),
      ),
      expect: () => <Object>[
        isA<SalesPipelineState>()
            .having(
              (state) => state.actionStatus,
              'actionStatus',
              SalesPipelineActionStatus.failure,
            )
            .having(
              (state) => state.actionFailure?.code,
              'actionFailure.code',
              'opportunity_move_requires_reason',
            ),
      ],
      verify: (_) {
        verifyNever(
          () => opportunityRepository.update(
            opportunity: any(named: 'opportunity'),
          ),
        );
      },
    );

    blocTest<SalesPipelineBloc, SalesPipelineState>(
      'closes an opportunity onto a terminal stage with a reason via '
      'MarkOpportunityWonUseCase',
      build: () {
        when(
          () => opportunityRepository.getById(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Opportunity>(
            _opportunity(
              id: 'opp-1',
              stageId: 'stage-negotiation',
              status: OpportunityStatus.open,
            ),
          ),
        );
        when(
          () => opportunityRepository.update(
            opportunity: any(named: 'opportunity'),
          ),
        ).thenAnswer((invocation) async {
          return AppSuccess<Opportunity>(
            invocation.namedArguments[#opportunity] as Opportunity,
          );
        });
        return buildBloc();
      },
      seed: () => SalesPipelineState(
        status: SalesPipelineLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'user-1',
        stages: stages,
        opportunities: <Opportunity>[
          _opportunity(
            id: 'opp-1',
            stageId: 'stage-negotiation',
            status: OpportunityStatus.open,
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        const SalesPipelineOpportunityClosedWithReason(
          opportunityId: 'opp-1',
          targetStageId: 'stage-won',
          reason: 'Preco competitivo',
        ),
      ),
      expect: () => <Object>[
        isA<SalesPipelineState>().having(
          (state) => state.actionStatus,
          'actionStatus',
          SalesPipelineActionStatus.inProgress,
        ),
        isA<SalesPipelineState>()
            .having(
              (state) => state.actionStatus,
              'actionStatus',
              SalesPipelineActionStatus.idle,
            )
            .having(
              (state) => state.opportunities.single.status,
              'opportunities.single.status',
              OpportunityStatus.won,
            )
            .having(
              (state) => state.opportunities.single.stageId,
              'opportunities.single.stageId',
              'stage-won',
            )
            .having(
              (state) => state.columns
                  .firstWhere((c) => c.stage.id == 'stage-won')
                  .activeCount,
              'won column active count',
              1,
            ),
      ],
    );
  });
}

PipelineStage _stage({
  required String id,
  required int order,
  PipelineStageTerminalType terminalType = PipelineStageTerminalType.none,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PipelineStage(
    id: id,
    organizationId: 'org-1',
    name: 'Estagio $id',
    order: order,
    colorHex: '#2563EB',
    terminalType: terminalType,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
  );
}

Opportunity _opportunity({
  String id = 'opp-1',
  String stageId = 'stage-negotiation',
  required OpportunityStatus status,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: id,
    organizationId: 'org-1',
    title: 'Reposicao de inverno',
    customerId: 'customer-1',
    estimatedValue: 1000,
    probability: 50,
    revenueForecast: 500,
    responsibleUserId: 'user-1',
    stageId: stageId,
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
