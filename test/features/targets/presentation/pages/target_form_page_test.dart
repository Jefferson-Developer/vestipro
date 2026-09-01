import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _InMemoryTargetRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _InMemoryTargetRepository();
  });

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

  Widget buildPage({String userId = 'manager-1'}) {
    return TargetFormPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: userId,
      actorName: 'Ana',
      permissionService: permissionService,
      createCubit: () => TargetFormCubit(
        repository,
        CreateTargetUseCase(
          repository,
          permissionService,
          FakeAnalyticsService(),
        ),
        UpdateTargetUseCase(
          repository,
          permissionService,
          _NoopAuditLogRepository(),
          FakeAnalyticsService(),
        ),
      ),
    );
  }

  testWidgets(
    'a SALES_REP without targetManage sees the forbidden page, never the '
    'cadastro form',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');

      await pumpApp(tester, buildPage(userId: 'rep-1'));
      await tester.pumpAndSettle();

      expect(find.text('Cadastro de metas'), findsNothing);
    },
  );

  testWidgets(
    'a SALES_MANAGER can search and see an already-cadastrada meta for a '
    'vendedor',
    (tester) async {
      stubMembership('manager-1', 'SALES_MANAGER');
      repository._items.add(
        _target(id: 'target-1', dimensionId: 'user-9', targetValue: 42000),
      );

      tester.view.physicalSize = const Size(1600, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Cadastro de metas'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Id do vendedor'),
          matching: find.byType(EditableText),
        ),
        'user-9',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar metas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('42000.00'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting a different dimension updates the dimension id field label',
    (tester) async {
      stubMembership('manager-1', 'SALES_MANAGER');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Id do vendedor'), findsOneWidget);

      await tester.tap(find.byType(AppDropdown<TargetDimensionType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equipe'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Id da equipe'), findsOneWidget);
    },
  );

  testWidgets(
    'submitting without a period shows a validation error and never calls '
    'the repository',
    (tester) async {
      stubMembership('manager-1', 'SALES_MANAGER');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Id do vendedor'),
          matching: find.byType(EditableText),
        ),
        'user-9',
      );
      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Valor da meta'),
          matching: find.byType(EditableText),
        ),
        '10000',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar meta'));
      await tester.pumpAndSettle();

      expect(find.text('Informe a data de início.'), findsOneWidget);
      expect(repository._items, isEmpty);
    },
  );
}

Target _target({
  required String id,
  required String dimensionId,
  required double targetValue,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: TargetDimensionType.salesRep,
    dimensionId: dimensionId,
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: DateTime.utc(2026, 1, 1),
    endDate: DateTime.utc(2026, 2, 1),
    metricType: TargetMetricType.revenue,
    targetValue: targetValue,
    currency: 'BRL',
    status: TargetStatus.active,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
}

final class _InMemoryTargetRepository implements TargetRepository {
  final List<Target> _items = <Target>[];

  @override
  Future<AppResult<Target>> create({required Target target}) async {
    _items.add(target);
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> update({required Target target}) async {
    final index = _items.indexWhere((item) => item.id == target.id);
    if (index >= 0) _items[index] = target;
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final item in _items) {
      if (item.id == id) return AppSuccess<Target>(item);
    }
    return const AppFailure<Target>(
      NotFoundFailure('Target not found.', code: 'target_not_found'),
    );
  }

  @override
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    return AppSuccess<List<Target>>(
      _items
          .where(
            (item) =>
                item.dimensionType == dimensionType &&
                item.dimensionId == dimensionId,
          )
          .toList(),
    );
  }
}

final class _NoopAuditLogRepository implements AuditLogRepository {
  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    return AppSuccess<AuditLogEntry>(entry);
  }
}
