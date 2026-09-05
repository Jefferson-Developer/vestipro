import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

class _AggregationRepository extends Mock implements AggregationRepository {}

class _TargetRepository extends Mock implements TargetRepository {}

class _TeamRepository extends Mock implements TeamRepository {}

class _MembershipRepository extends Mock implements MembershipRepository {}

class _InsightRepository extends Mock implements InsightRepository {}

void main() {
  late _AggregationRepository aggregations;
  late _TargetRepository targets;
  late _TeamRepository teams;
  late _MembershipRepository memberships;
  late TargetVisibilityService visibility;
  late _InsightRepository insights;
  late LoadTargetsDashboardUseCase useCase;
  const filters = TargetsDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 1,
  );

  setUpAll(() {
    registerFallbackValue(TargetDimensionType.salesRep);
    registerFallbackValue(
      const InsightVisibilityFilter(
        organizationId: 'fallback',
        userId: 'fallback',
        mode: InsightVisibilityMode.none,
      ),
    );
  });

  setUp(() {
    aggregations = _AggregationRepository();
    targets = _TargetRepository();
    teams = _TeamRepository();
    memberships = _MembershipRepository();
    visibility = TargetVisibilityService(
      PortfolioVisibilityService(memberships, teams),
      teams,
    );
    insights = _InsightRepository();
    useCase = LoadTargetsDashboardUseCase(
      aggregations,
      targets,
      teams,
      visibility,
      insights,
      const RankingCalculationService(),
    );
    when(
      () => memberships.getByUser(
        organizationId: 'org-1',
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((invocation) async {
      final userId = invocation.namedArguments[#userId] as String;
      return AppSuccess<Membership>(
        Membership(
          id: 'membership-$userId',
          organizationId: 'org-1',
          userId: userId,
          roleId: userId == 'seller-1' ? 'SALES_REP' : 'ADMIN',
          roleName: userId == 'seller-1' ? 'SALES_REP' : 'ADMIN',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026),
          createdBy: 'admin-1',
          updatedAt: DateTime.utc(2026),
          updatedBy: 'admin-1',
        ),
      );
    });
    when(() => teams.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess<List<Team>>(<Team>[
        Team(
          id: 'team-a',
          organizationId: 'org-1',
          companyId: 'company-1',
          name: 'Equipe A',
          memberIds: const <String>['seller-1'],
          version: 1,
          createdAt: DateTime.utc(2026),
          createdBy: 'admin-1',
          updatedAt: DateTime.utc(2026),
          updatedBy: 'admin-1',
        ),
      ]),
    );
    when(
      () => aggregations.listByPeriod(
        organizationId: 'org-1',
        dimension: AggregationDimension.sellerMonthly,
        companyId: 'company-1',
        periodKey: '2026-01',
        limit: 500,
      ),
    ).thenAnswer(
      (_) async => AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[
        AggregationSnapshot(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimension: AggregationDimension.sellerMonthly,
          scopeId: 'seller-1',
          periodKey: '2026-01',
          revenueGross: 200,
          revenueNet: 200,
          discountAmount: 0,
          orderCount: 1,
          itemQuantity: 2,
          labels: const <String, String>{'sellerName': 'Ana'},
          generatedAt: DateTime.utc(2026, 1, 11),
          version: 1,
        ),
      ]),
    );
    when(
      () => insights.listPageByVisibility(
        organizationId: 'org-1',
        visibility: any(named: 'visibility'),
        limit: 100,
        type: InsightType.sellerBelowTarget,
      ),
    ).thenAnswer(
      (_) async => const AppSuccess<InsightPage>(
        InsightPage(insights: <Insight>[], hasMore: false),
      ),
    );
    when(
      () => targets.listByDimension(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: any(named: 'dimensionType'),
        dimensionId: any(named: 'dimensionId'),
        metricType: TargetMetricType.revenue,
      ),
    ).thenAnswer((invocation) async {
      final type =
          invocation.namedArguments[#dimensionType] as TargetDimensionType;
      final id = invocation.namedArguments[#dimensionId] as String;
      if (type == TargetDimensionType.salesRep && id == 'seller-1') {
        return AppSuccess<List<Target>>(<Target>[
          _target('seller-target', type, id),
        ]);
      }
      if (type == TargetDimensionType.team && id == 'team-a') {
        return AppSuccess<List<Target>>(<Target>[
          _target('team-target', type, id),
        ]);
      }
      if (type == TargetDimensionType.company) {
        return AppSuccess<List<Target>>(<Target>[
          _target('company-target', type, id),
        ]);
      }
      return const AppSuccess<List<Target>>(<Target>[]);
    });
  });

  test(
    'builds organization/team/seller hierarchy and uses TASK-131 projection formula',
    () async {
      final result = await useCase(
        organizationId: 'org-1',
        userId: 'admin-1',
        filters: filters,
        now: DateTime.utc(2026, 1, 11),
      );
      final snapshot = (result as AppSuccess<TargetsDashboardSnapshot>).value;
      final seller = snapshot.root.children.single.children.single;
      expect(seller.label, 'Ana');
      expect(seller.metric!.achievementPercentage, 20);
      final insightInput = InsightSalesRepBelowTargetSnapshot(
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'admin-1',
        sellerId: 'seller-1',
        sellerName: 'Ana',
        periodLabel: 'jan/2026',
        periodStartDate: DateTime.utc(2026),
        periodEndDate: DateTime.utc(2026, 2),
        targetValue: 1000,
        realizedValue: 200,
        elapsedRelevantDays: 10,
        totalRelevantDays: 31,
      );
      expect(seller.metric!.projectedValue, insightInput.projectedValue);
      expect(
        seller.metric!.projectedAchievementPercentage,
        insightInput.projectedAchievementPercentage,
      );
    },
  );

  test(
    'an active target absent from the queried period is rendered as not registered',
    () async {
      when(
        () => targets.listByDimension(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionType: TargetDimensionType.company,
          dimensionId: 'company-1',
          metricType: TargetMetricType.revenue,
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<Target>>(<Target>[
          _target(
            'future',
            TargetDimensionType.company,
            'company-1',
            start: DateTime.utc(2026, 2),
            end: DateTime.utc(2026, 3),
          ),
        ]),
      );
      final result = await useCase(
        organizationId: 'org-1',
        userId: 'admin-1',
        filters: filters,
      );
      expect(
        (result as AppSuccess<TargetsDashboardSnapshot>).value.root.metric,
        isNull,
      );
    },
  );

  test(
    'sales representative scope removes every other seller before target reads',
    () async {
      final result = await useCase(
        organizationId: 'org-1',
        userId: 'seller-1',
        filters: filters,
      );
      final snapshot = (result as AppSuccess<TargetsDashboardSnapshot>).value;
      expect(snapshot.availableSellerIds, <String>['seller-1']);
      expect(snapshot.ranking.map((entry) => entry.dimensionId), <String>[
        'seller-1',
      ]);
      expect(snapshot.root.metric, isNull);
      expect(snapshot.root.children.single.metric, isNull);
      expect(snapshot.root.children.single.children.single.metric, isNotNull);
    },
  );
}

Target _target(
  String id,
  TargetDimensionType type,
  String dimensionId, {
  DateTime? start,
  DateTime? end,
}) => Target(
  id: id,
  organizationId: 'org-1',
  companyId: 'company-1',
  dimensionType: type,
  dimensionId: dimensionId,
  periodGranularity: TargetPeriodGranularity.monthly,
  startDate: start ?? DateTime.utc(2026),
  endDate: end ?? DateTime.utc(2026, 2),
  metricType: TargetMetricType.revenue,
  targetValue: 1000,
  currency: 'BRL',
  status: TargetStatus.active,
  createdAt: DateTime.utc(2026),
  createdBy: 'admin-1',
  updatedAt: DateTime.utc(2026),
  updatedBy: 'admin-1',
  version: 1,
  syncStatus: TargetSyncStatus.synced,
);
