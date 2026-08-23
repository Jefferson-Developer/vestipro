import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _InMemoryAuditLogRepository auditLogRepository;

  Membership membership(String roleName) {
    return Membership(
      id: 'current-user',
      organizationId: 'org-1',
      userId: 'current-user',
      roleId: roleName,
      roleName: roleName,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime(2026, 1, 1),
      updatedBy: 'owner-1',
    );
  }

  Widget buildPage() {
    return AuditLogPage(
      organizationId: 'org-1',
      userId: 'current-user',
      permissionService: permissionService,
      createBloc: () => AuditLogBloc(
        listAuditLogEntries: ListAuditLogEntriesUseCase(
          auditLogRepository,
          permissionService,
        ),
      ),
    );
  }

  void setWidth(WidgetTester tester, double width) {
    final view = tester.view;
    view.physicalSize = Size(width, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  AuditLogEntry entry({
    required String id,
    DateTime? timestamp,
    String actorUserId = 'owner-1',
    String actorName = 'Ana Souza',
    AuditAction action = AuditAction.userRoleUpdated,
    String entityType = 'membership',
    String entityId = 'user-2',
    Map<String, Object?>? previousValue,
    Map<String, Object?>? newValue,
  }) {
    return AuditLogEntry(
      id: id,
      organizationId: 'org-1',
      actorUserId: actorUserId,
      actorName: actorName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      previousValue:
          previousValue ?? const <String, Object?>{'roleName': 'SALES_REP'},
      newValue: newValue ?? const <String, Object?>{'roleName': 'ADMIN'},
      timestamp: timestamp ?? DateTime(2026, 1, 10, 9, 30),
    );
  }

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    auditLogRepository = _InMemoryAuditLogRepository(<AuditLogEntry>[
      entry(id: 'log-1'),
    ]);
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'current-user',
      ),
    ).thenAnswer((_) async => AppSuccess<Membership>(membership('OWNER')));
  });

  group('AuditLogPage', () {
    testWidgets('renders an administrative table on desktop', (tester) async {
      setWidth(tester, 1300);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Auditoria de acessos'), findsOneWidget);
      expect(find.text('Data/hora'), findsOneWidget);
      expect(find.text('Ator'), findsOneWidget);
      expect(find.text('Ação'), findsWidgets);
      expect(find.text('Entidade afetada'), findsOneWidget);
      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('Role alterada'), findsOneWidget);
      expect(find.text('Perfil: SALES_REP -> ADMIN'), findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('renders audit entries as cards on mobile', (tester) async {
      setWidth(tester, 360);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Data/hora: '), findsOneWidget);
      expect(find.textContaining('Ator: '), findsOneWidget);
      expect(find.textContaining('Entidade afetada: '), findsOneWidget);
      expect(find.text('Data/hora'), findsNothing);
    });

    testWidgets('combines period, actor and action filters', (tester) async {
      setWidth(tester, 1300);
      auditLogRepository = _InMemoryAuditLogRepository(<AuditLogEntry>[
        entry(
          id: 'target',
          actorUserId: 'admin-a',
          actorName: 'Admin A',
          action: AuditAction.userRoleUpdated,
          timestamp: DateTime(2026, 1, 10, 10),
        ),
        entry(
          id: 'other-actor',
          actorUserId: 'owner-a',
          actorName: 'Owner A',
          action: AuditAction.userRoleUpdated,
          timestamp: DateTime(2026, 1, 10, 11),
        ),
        entry(
          id: 'other-action',
          actorUserId: 'admin-a',
          actorName: 'Admin A',
          action: AuditAction.userInvited,
          timestamp: DateTime(2026, 1, 10, 12),
        ),
        entry(
          id: 'other-period',
          actorUserId: 'admin-a',
          actorName: 'Admin A',
          action: AuditAction.userRoleUpdated,
          timestamp: DateTime(2026, 2, 1, 10),
        ),
      ]);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Role'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('audit_log_actor_filter')),
          matching: find.byType(EditableText),
        ),
        'admin-a',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('audit_log_from_filter')),
          matching: find.byType(EditableText),
        ),
        '2026-01-01',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('audit_log_to_filter')),
          matching: find.byType(EditableText),
        ),
        '2026-01-31',
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Admin A\nadmin-a'), findsOneWidget);
      expect(find.text('Owner A\nowner-a'), findsNothing);
      expect(find.text('Convite criado'), findsNothing);

      final request = auditLogRepository.requests.last;
      expect(request.actorUserId, 'admin-a');
      expect(request.from, DateTime(2026, 1));
      expect(request.to, DateTime(2026, 1, 31, 23, 59, 59, 999));
      expect(
        request.actions,
        containsAll(<AuditAction>[
          AuditAction.roleChanged,
          AuditAction.userRoleUpdated,
        ]),
      );
    });

    testWidgets('loads a large cursor-paginated volume without duplication', (
      tester,
    ) async {
      setWidth(tester, 1300);
      auditLogRepository = _InMemoryAuditLogRepository(
        List<AuditLogEntry>.generate(60, (index) {
          final number = index + 1;
          return entry(
            id: 'log-$number',
            actorName: 'Ator $number',
            actorUserId: 'actor-$number',
            timestamp: DateTime(
              2026,
              1,
              1,
              12,
            ).subtract(Duration(minutes: index)),
          );
        }),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<Object>('log-25')), findsOneWidget);
      expect(find.byKey(const ValueKey<Object>('log-26')), findsNothing);

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      for (var index = 1; index <= 60; index++) {
        expect(find.byKey(ValueKey<Object>('log-$index')), findsOneWidget);
      }
      expect(auditLogRepository.requests, hasLength(3));
    });

    testWidgets('shows the empty state', (tester) async {
      setWidth(tester, 1300);
      auditLogRepository = _InMemoryAuditLogRepository(const <AuditLogEntry>[]);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum evento de auditoria encontrado'),
        findsOneWidget,
      );
    });

    testWidgets('hides the page for roles without audit.log.view', (
      tester,
    ) async {
      setWidth(tester, 1300);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(membership('SALES_REP')),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Você não tem permissão para acessar esta página.'),
        findsOneWidget,
      );
      expect(find.text('Auditoria de acessos'), findsNothing);
      expect(auditLogRepository.requests, isEmpty);
    });
  });
}

final class _AuditLogRequest {
  const _AuditLogRequest({
    required this.organizationId,
    required this.limit,
    required this.actions,
    this.before,
    this.from,
    this.to,
    this.actorUserId,
  });

  final String organizationId;
  final int limit;
  final Set<AuditAction> actions;
  final DateTime? before;
  final DateTime? from;
  final DateTime? to;
  final String? actorUserId;
}

final class _InMemoryAuditLogRepository implements AuditLogRepository {
  _InMemoryAuditLogRepository(List<AuditLogEntry> entries)
    : _entries = [...entries]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  final List<AuditLogEntry> _entries;
  final List<_AuditLogRequest> requests = <_AuditLogRequest>[];

  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  }) async {
    final result = await listPageByOrganization(
      organizationId: organizationId,
      limit: limit,
      before: before,
      from: from,
      to: to,
      actions: action == null ? const <AuditAction>{} : <AuditAction>{action},
      actorUserId: actorUserId,
    );
    return result.fold(
      onSuccess: (page) => AppSuccess<List<AuditLogEntry>>(page.entries),
      onFailure: AppFailure<List<AuditLogEntry>>.new,
    );
  }

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    return AppSuccess<AuditLogEntry>(entry);
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
  }) async {
    requests.add(
      _AuditLogRequest(
        organizationId: organizationId,
        limit: limit,
        before: before,
        from: from,
        to: to,
        actions: actions,
        actorUserId: actorUserId,
      ),
    );

    final filtered = _entries
        .where((entry) {
          final matchesOrganization = entry.organizationId == organizationId;
          final matchesCursor =
              before == null || entry.timestamp.isBefore(before);
          final matchesFrom = from == null || !entry.timestamp.isBefore(from);
          final matchesTo = to == null || !entry.timestamp.isAfter(to);
          final matchesAction =
              actions.isEmpty || actions.contains(entry.action);
          final matchesActor =
              actorUserId == null ||
              actorUserId.isEmpty ||
              entry.actorUserId == actorUserId;
          return matchesOrganization &&
              matchesCursor &&
              matchesFrom &&
              matchesTo &&
              matchesAction &&
              matchesActor;
        })
        .toList(growable: false);

    final pageEntries = filtered.take(limit).toList(growable: false);
    final hasMore = filtered.length > limit;
    return AppSuccess<AuditLogEntryPage>(
      AuditLogEntryPage(
        entries: pageEntries,
        hasMore: hasMore,
        nextCursor: hasMore && pageEntries.isNotEmpty
            ? pageEntries.last.timestamp
            : null,
      ),
    );
  }
}
