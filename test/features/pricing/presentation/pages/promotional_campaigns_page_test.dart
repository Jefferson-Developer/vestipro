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
  late _InMemoryPromotionalCampaignRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _InMemoryPromotionalCampaignRepository();
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
    return PromotionalCampaignsPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'user-1',
      actorName: 'Ana',
      permissionService: permissionService,
      createCubit: () => PromotionalCampaignCubit(
        repository,
        CreatePromotionalCampaignUseCase(repository, _NoopAuditLogRepository()),
        UpdatePromotionalCampaignUseCase(repository, _NoopAuditLogRepository()),
      ),
    );
  }

  testWidgets('creates a campaign and renders it in the table', (tester) async {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository._items.add(
      PromotionalCampaign(
        id: 'campaign-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Liquidação VIP',
        validFrom: DateTime.utc(2026, 8, 1),
        validTo: DateTime.utc(2026, 8, 31),
        customerSegment: 'vip',
        productIds: const <String>['product-1'],
        discountType: PromotionalDiscountType.percentage,
        discountValue: 10,
        stackableWithOtherCampaigns: false,
        priority: 10,
        status: PromotionalCampaignStatus.active,
        createdAt: DateTime.utc(2026, 8, 27),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 8, 27),
        updatedBy: 'user-1',
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Liquidação VIP'), findsOneWidget);
    expect(find.text('vip'), findsOneWidget);
  });
}

final class _InMemoryPromotionalCampaignRepository
    implements PromotionalCampaignRepository {
  final List<PromotionalCampaign> _items = <PromotionalCampaign>[];

  @override
  Future<AppResult<PromotionalCampaign>> create({
    required PromotionalCampaign campaign,
  }) async {
    _items.add(campaign);
    return AppSuccess<PromotionalCampaign>(campaign);
  }

  @override
  Future<AppResult<PromotionalCampaign?>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final item in _items) {
      if (item.id == id) return AppSuccess<PromotionalCampaign?>(item);
    }
    return const AppSuccess<PromotionalCampaign?>(null);
  }

  @override
  Future<AppResult<List<PromotionalCampaign>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PromotionalCampaign>>(
      _items.where((item) => item.companyId == companyId).toList(),
    );
  }

  @override
  Future<AppResult<PromotionalCampaign>> update({
    required PromotionalCampaign campaign,
  }) async {
    final index = _items.indexWhere((item) => item.id == campaign.id);
    if (index >= 0) _items[index] = campaign;
    return AppSuccess<PromotionalCampaign>(campaign);
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
