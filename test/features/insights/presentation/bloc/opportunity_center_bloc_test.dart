import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockInsightRepository extends Mock implements InsightRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('OpportunityCenterBloc', () {
    late _MockInsightRepository repository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late FakeAnalyticsService analytics;

    setUpAll(() {
      registerFallbackValue(InsightStatus.dismissed);
      registerFallbackValue(
        const InsightVisibilityFilter(
          organizationId: 'org-1',
          userId: 'user-1',
          mode: InsightVisibilityMode.ownOnly,
        ),
      );
    });

    setUp(() {
      repository = _MockInsightRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      analytics = FakeAnalyticsService();
    });

    OpportunityCenterBloc buildBloc() {
      return OpportunityCenterBloc(
        ListOpportunityCenterInsightsUseCase(
          InsightVisibilityService(
            PortfolioVisibilityService(membershipRepository, teamRepository),
            teamRepository,
          ),
          repository,
        ),
        UpdateInsightStatusUseCase(repository),
        analytics,
      );
    }

    void stubMembership(String userId, String roleName) {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: userId,
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          Membership(
            id: userId,
            organizationId: 'org-1',
            userId: userId,
            roleId: roleName,
            roleName: roleName,
            teamIds: const <String>[],
            status: MembershipStatus.active,
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: userId,
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: userId,
          ),
        ),
      );
    }

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'starts empty when the caller has no active insight',
      setUp: () {
        stubMembership('seller-1', 'SALES_REP');
        when(
          () => repository.listPageByVisibility(
            organizationId: 'org-1',
            visibility: any(named: 'visibility'),
            limit: 25,
            before: null,
            type: null,
          ),
        ).thenAnswer(
          (_) async => const AppSuccess<InsightPage>(
            InsightPage(insights: <Insight>[], hasMore: false),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OpportunityCenterStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'seller-1',
        ),
      ),
      expect: () => <Object>[
        isA<OpportunityCenterState>().having(
          (state) => state.status,
          'status',
          OpportunityCenterLoadStatus.loading,
        ),
        isA<OpportunityCenterState>()
            .having(
              (state) => state.status,
              'status',
              OpportunityCenterLoadStatus.ready,
            )
            .having(
              (state) => state.visibleInsights,
              'visibleInsights',
              isEmpty,
            ),
      ],
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'aggregates multiple insight types sorted by estimatedImpact by default',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        when(
          () => repository.listPageByVisibility(
            organizationId: 'org-1',
            visibility: any(named: 'visibility'),
            limit: 25,
            before: null,
            type: null,
          ),
        ).thenAnswer(
          (_) async => AppSuccess<InsightPage>(
            InsightPage(
              insights: <Insight>[
                _insight(
                  id: 'low-impact',
                  type: InsightType.crossSell,
                  amount: 100,
                ),
                _insight(
                  id: 'high-impact',
                  type: InsightType.churnRisk,
                  amount: 9000,
                ),
                _insight(
                  id: 'mid-impact',
                  type: InsightType.upSell,
                  amount: 500,
                ),
              ],
              hasMore: false,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OpportunityCenterStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'owner-1',
        ),
      ),
      verify: (bloc) {
        final ids = bloc.state.visibleInsights.map((i) => i.id).toList();
        expect(ids, <String>['high-impact', 'mid-impact', 'low-impact']);
      },
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'filters the already-loaded insights by type without a new fetch',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        when(
          () => repository.listPageByVisibility(
            organizationId: 'org-1',
            visibility: any(named: 'visibility'),
            limit: 25,
            before: null,
            type: null,
          ),
        ).thenAnswer(
          (_) async => AppSuccess<InsightPage>(
            InsightPage(
              insights: <Insight>[
                _insight(id: 'a', type: InsightType.crossSell, amount: 100),
                _insight(id: 'b', type: InsightType.churnRisk, amount: 200),
              ],
              hasMore: false,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const OpportunityCenterStarted(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'owner-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const OpportunityCenterFiltersChanged(
            OpportunityCenterFilters(
              types: <InsightType>{InsightType.churnRisk},
            ),
          ),
        );
      },
      verify: (bloc) {
        final ids = bloc.state.visibleInsights.map((i) => i.id).toList();
        expect(ids, <String>['b']);
        verify(
          () => repository.listPageByVisibility(
            organizationId: any(named: 'organizationId'),
            visibility: any(named: 'visibility'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            type: any(named: 'type'),
          ),
        ).called(1);
      },
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'paginates without losing already loaded insights',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
      },
      build: buildBloc,
      seed: () => OpportunityCenterState(
        status: OpportunityCenterLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        insights: <Insight>[_insight(id: 'a', amount: 100)],
        hasMore: true,
        nextCursor: DateTime.utc(2026, 1, 1),
      ),
      act: (bloc) {
        when(
          () => repository.listPageByVisibility(
            organizationId: 'org-1',
            visibility: any(named: 'visibility'),
            limit: 25,
            before: DateTime.utc(2026, 1, 1),
            type: null,
          ),
        ).thenAnswer(
          (_) async => AppSuccess<InsightPage>(
            InsightPage(
              insights: <Insight>[_insight(id: 'b', amount: 50)],
              hasMore: false,
            ),
          ),
        );
        bloc.add(const OpportunityCenterNextPageRequested());
      },
      expect: () => <Object>[
        isA<OpportunityCenterState>().having(
          (state) => state.status,
          'status',
          OpportunityCenterLoadStatus.loadingMore,
        ),
        isA<OpportunityCenterState>()
            .having(
              (state) => state.insights.map((i) => i.id).toList(),
              'insights',
              <String>['a', 'b'],
            )
            .having((state) => state.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'a SALES_REP only ever loads insights recipiented to their own carteira',
      setUp: () {
        stubMembership('seller-1', 'SALES_REP');
        when(
          () => repository.listPageByVisibility(
            organizationId: 'org-1',
            visibility: any(
              named: 'visibility',
              that: isA<InsightVisibilityFilter>()
                  .having((f) => f.mode, 'mode', InsightVisibilityMode.ownOnly)
                  .having(
                    (f) => f.recipientUserIds,
                    'recipientUserIds',
                    <String>{'seller-1'},
                  ),
            ),
            limit: 25,
            before: null,
            type: null,
          ),
        ).thenAnswer(
          (_) async => AppSuccess<InsightPage>(
            InsightPage(
              insights: <Insight>[_insight(id: 'own-1')],
              hasMore: false,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OpportunityCenterStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'seller-1',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.visibleInsights.map((i) => i.id).toList(), <String>[
          'own-1',
        ]);
      },
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'discards an insight optimistically and restores it via undo',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        when(
          () => repository.updateStatus(
            organizationId: 'org-1',
            insightId: 'a',
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const AppSuccess<void>(null));
      },
      build: buildBloc,
      seed: () => OpportunityCenterState(
        status: OpportunityCenterLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        insights: <Insight>[_insight(id: 'a', amount: 100)],
      ),
      act: (bloc) async {
        bloc.add(const OpportunityCenterInsightDismissed('a'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OpportunityCenterUndoRequested('a'));
      },
      expect: () => <Object>[
        isA<OpportunityCenterState>()
            .having((state) => state.insights, 'insights', isEmpty)
            .having((state) => state.pendingUndo, 'pendingUndo', isNotNull),
        isA<OpportunityCenterState>()
            .having((state) => state.insights, 'insights', isEmpty)
            .having((state) => state.pendingUndo, 'pendingUndo', isNull),
        isA<OpportunityCenterState>()
            .having(
              (state) => state.insights.map((i) => i.id).toList(),
              'insights',
              <String>['a'],
            )
            .having((state) => state.pendingUndo, 'pendingUndo', isNull),
      ],
      verify: (_) {
        verify(
          () => repository.updateStatus(
            organizationId: 'org-1',
            insightId: 'a',
            status: InsightStatus.dismissed,
          ),
        ).called(1);
        verify(
          () => repository.updateStatus(
            organizationId: 'org-1',
            insightId: 'a',
            status: InsightStatus.fresh,
          ),
        ).called(1);
      },
    );

    blocTest<OpportunityCenterBloc, OpportunityCenterState>(
      'logs insight_opened and insight_action_clicked with the right params',
      build: buildBloc,
      seed: () => OpportunityCenterState(
        organizationId: 'org-1',
        insights: <Insight>[_insight(id: 'a', type: InsightType.churnRisk)],
      ),
      act: (bloc) {
        bloc.add(const OpportunityCenterInsightOpened('a'));
        bloc.add(
          OpportunityCenterActionExecuted(
            insightId: 'a',
            action: const InsightAction(
              type: InsightActionType.openCustomer,
              label: 'Abrir cliente',
              customerId: 'customer-a',
            ),
          ),
        );
      },
      verify: (_) {
        expect(analytics.loggedEvents, hasLength(2));
        expect(analytics.loggedEvents[0].name, AnalyticsEvents.insightOpened);
        expect(
          analytics.loggedEvents[0].parameters,
          containsPair('insight_type', 'churnRisk'),
        );
        expect(
          analytics.loggedEvents[1].name,
          AnalyticsEvents.insightActionClicked,
        );
        expect(
          analytics.loggedEvents[1].parameters,
          containsPair('action_type', 'openCustomer'),
        );
      },
    );
  });
}

Insight _insight({
  required String id,
  InsightType type = InsightType.crossSell,
  double amount = 100,
}) {
  final generatedAt = DateTime.utc(2026, 1, 1);
  return Insight(
    id: id,
    type: type,
    title: 'Insight $id',
    description: 'Description $id',
    evidence: const <InsightEvidence>[
      InsightEvidence(code: 'ev', label: 'Evidência', value: '1'),
    ],
    estimatedImpact: InsightEstimatedImpact(amount: amount),
    severity: InsightSeverity.medium,
    confidenceScore: 0.8,
    recommendation: 'Recomendação $id',
    quickAction: const InsightAction(
      type: InsightActionType.openCustomer,
      label: 'Abrir cliente',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'seller-1',
    customerId: 'customer-$id',
    generatedAt: generatedAt,
    expiresAt: generatedAt.add(const Duration(days: 7)),
    status: InsightStatus.fresh,
  );
}
