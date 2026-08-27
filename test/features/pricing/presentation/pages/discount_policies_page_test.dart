import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/pricing.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _InMemoryDiscountPolicyRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _InMemoryDiscountPolicyRepository();
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'user-1',
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'FINANCE',
          roleName: 'FINANCE',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
    );
  });

  Widget buildPage() {
    return DiscountPoliciesPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'user-1',
      actorName: 'Ana',
      permissionService: permissionService,
      createCubit: () => DiscountPolicyCubit(
        repository,
        CreateDiscountPolicyUseCase(repository, _NoopAuditLogRepository()),
        UpdateDiscountPolicyUseCase(repository, _NoopAuditLogRepository()),
      ),
    );
  }

  testWidgets('creates a policy and renders it in the table', (tester) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Perfil da política de desconto'),
        matching: find.byType(EditableText),
      ),
      'SALES_REP',
    );
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Limite máximo de desconto'),
        matching: find.byType(EditableText),
      ),
      '15',
    );
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Gatilho de aprovação do desconto'),
        matching: find.byType(EditableText),
      ),
      '10',
    );
    await tester.tap(find.text('Criar política'));
    await tester.pumpAndSettle();

    expect(find.text('SALES_REP'), findsWidgets);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
  });
}

final class _InMemoryDiscountPolicyRepository
    implements DiscountPolicyRepository {
  final List<DiscountPolicy> _items = <DiscountPolicy>[];

  @override
  Future<AppResult<DiscountPolicy>> create({
    required DiscountPolicy discountPolicy,
  }) async {
    _items.add(discountPolicy);
    return AppSuccess<DiscountPolicy>(discountPolicy);
  }

  @override
  Future<AppResult<DiscountPolicy?>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final item in _items) {
      if (item.id == id) return AppSuccess<DiscountPolicy?>(item);
    }
    return const AppSuccess<DiscountPolicy?>(null);
  }

  @override
  Future<AppResult<List<DiscountPolicy>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<DiscountPolicy>>(
      _items.where((item) => item.companyId == companyId).toList(),
    );
  }

  @override
  Future<AppResult<DiscountPolicy>> update({
    required DiscountPolicy discountPolicy,
  }) async {
    final index = _items.indexWhere((item) => item.id == discountPolicy.id);
    if (index >= 0) _items[index] = discountPolicy;
    return AppSuccess<DiscountPolicy>(discountPolicy);
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
