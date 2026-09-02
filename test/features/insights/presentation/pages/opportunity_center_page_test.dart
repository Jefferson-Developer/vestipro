import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late PermissionService permissionService;
  late _InMemoryInsightRepository repository;
  late FakeAnalyticsService analytics;

  Membership membership(String roleName) {
    return Membership(
      id: 'current-user',
      organizationId: 'org-1',
      userId: 'current-user',
      roleId: roleName,
      roleName: roleName,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime(2026, 8, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime(2026, 8, 1),
      updatedBy: 'owner-1',
    );
  }

  void setWidth(WidgetTester tester, double width) {
    final view = tester.view;
    view.physicalSize = Size(width, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  Insight insight({
    required String id,
    InsightType type = InsightType.crossSell,
    double amount = 100,
  }) {
    final generatedAt = DateTime.utc(2026, 8, 1);
    return Insight(
      id: id,
      type: type,
      title: 'Insight $id',
      description: 'Descrição do insight $id',
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
        customerId: 'customer-1',
      ),
      organizationId: 'org-1',
      companyId: 'company-1',
      recipientUserId: 'current-user',
      customerId: 'customer-$id',
      generatedAt: generatedAt,
      expiresAt: generatedAt.add(const Duration(days: 7)),
      status: InsightStatus.fresh,
    );
  }

  Widget buildPage() {
    return OpportunityCenterPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'current-user',
      permissionService: permissionService,
      createBloc: () => OpportunityCenterBloc(
        ListOpportunityCenterInsightsUseCase(
          InsightVisibilityService(
            PortfolioVisibilityService(membershipRepository, teamRepository),
            teamRepository,
          ),
          repository,
        ),
        UpdateInsightStatusUseCase(repository),
        analytics,
      ),
      onActionExecuted: (_, _) {},
    );
  }

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    permissionService = PermissionService(membershipRepository);
    analytics = FakeAnalyticsService();
    repository = _InMemoryInsightRepository(<Insight>[
      insight(id: 'a', type: InsightType.crossSell, amount: 100),
    ]);
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'current-user',
      ),
    ).thenAnswer((_) async => AppSuccess<Membership>(membership('OWNER')));
  });

  group('OpportunityCenterPage', () {
    testWidgets('renders the opportunities as a dense table on desktop', (
      tester,
    ) async {
      setWidth(tester, 1300);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Central de oportunidades'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Recomendação'), findsOneWidget);
      expect(find.text('Insight a'), findsOneWidget);
    });

    testWidgets('renders the opportunities as cards on mobile', (tester) async {
      setWidth(tester, 360);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Tipo'), findsNothing);
      expect(find.text('Recomendação'), findsNothing);
      expect(find.text('Insight a'), findsWidgets);
    });

    testWidgets('hides the page for roles without insight.view', (
      tester,
    ) async {
      setWidth(tester, 1300);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(membership('SALES_ASSISTANT')),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Você não tem permissão para acessar esta página.'),
        findsOneWidget,
      );
      expect(find.text('Central de oportunidades'), findsNothing);
    });

    testWidgets('discards an insight and offers undo', (tester) async {
      setWidth(tester, 1300);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Descartar insight'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Insight descartado.'), findsOneWidget);
      expect(find.text('Insight a'), findsNothing);

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();

      expect(find.text('Insight a'), findsOneWidget);
    });
  });
}

final class _InMemoryInsightRepository implements InsightRepository {
  _InMemoryInsightRepository(List<Insight> insights)
    : _insights = [...insights];

  final List<Insight> _insights;

  @override
  Future<AppResult<void>> saveAll({
    required String organizationId,
    required List<Insight> insights,
  }) async {
    _insights.addAll(insights);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<InsightPage>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    InsightType? type,
    InsightStatus? status,
  }) async {
    return AppSuccess<InsightPage>(
      InsightPage(insights: List<Insight>.of(_insights), hasMore: false),
    );
  }

  @override
  Future<AppResult<InsightPage>> listPageByVisibility({
    required String organizationId,
    required InsightVisibilityFilter visibility,
    int limit = 25,
    DateTime? before,
    InsightType? type,
  }) async {
    if (!visibility.canViewAny) {
      return const AppSuccess<InsightPage>(
        InsightPage(insights: <Insight>[], hasMore: false),
      );
    }
    final recipientUserIds = visibility.recipientUserIds;
    final filtered = _insights
        .where((item) => item.organizationId == organizationId)
        .where(
          (item) =>
              recipientUserIds == null ||
              recipientUserIds.contains(item.recipientUserId),
        )
        .where(
          (item) =>
              item.status != InsightStatus.dismissed &&
              item.status != InsightStatus.resolved,
        )
        .toList(growable: false);
    return AppSuccess<InsightPage>(
      InsightPage(insights: filtered, hasMore: false),
    );
  }

  @override
  Future<AppResult<void>> updateStatus({
    required String organizationId,
    required String insightId,
    required InsightStatus status,
  }) async {
    final index = _insights.indexWhere((item) => item.id == insightId);
    if (index != -1) {
      _insights[index] = _insights[index].copyWith(status: status);
    }
    return const AppSuccess<void>(null);
  }
}
