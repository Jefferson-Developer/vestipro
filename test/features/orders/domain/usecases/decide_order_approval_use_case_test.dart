import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeOrderApprovalRepository implements OrderApprovalRepository {
  _FakeOrderApprovalRepository(this._result);

  final AppResult<OrderApprovalDecisionResult> _result;
  String? lastOrderId;
  OrderApprovalDecisionValue? lastDecision;
  String? lastReason;
  int callCount = 0;

  @override
  Future<AppResult<OrderApprovalDecisionResult>> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  }) async {
    callCount += 1;
    lastOrderId = orderId;
    lastDecision = decision;
    lastReason = reason;
    return _result;
  }
}

void main() {
  group('DecideOrderApprovalUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'manager-1',
        organizationId: 'org-1',
        userId: 'manager-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'manager-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'manager-1',
      );
    }

    test(
      'approves through the repository and logs orderApproved on success',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeOrderApprovalRepository(
          AppSuccess<OrderApprovalDecisionResult>(
            _result(status: OrderStatus.approved),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideOrderApprovalUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'manager-1',
          decision: OrderApprovalDecisionValue.approved,
        );

        expect(result, isA<AppSuccess<OrderApprovalDecisionResult>>());
        expect(repository.lastDecision, OrderApprovalDecisionValue.approved);
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.orderApproved,
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects with a reason through the repository and logs orderRejected',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeOrderApprovalRepository(
          AppSuccess<OrderApprovalDecisionResult>(
            _result(status: OrderStatus.rejected, reason: 'Fora da política'),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideOrderApprovalUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'manager-1',
          decision: OrderApprovalDecisionValue.rejected,
          reason: 'Fora da política',
        );

        expect(result, isA<AppSuccess<OrderApprovalDecisionResult>>());
        expect(repository.lastReason, 'Fora da política');
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.orderRejected,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails without calling the repository when rejecting without a reason',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeOrderApprovalRepository(
          AppSuccess<OrderApprovalDecisionResult>(
            _result(status: OrderStatus.rejected),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideOrderApprovalUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'manager-1',
          decision: OrderApprovalDecisionValue.rejected,
        );

        expect(result, isA<AppFailure<OrderApprovalDecisionResult>>());
        expect(
          (result as AppFailure<OrderApprovalDecisionResult>).failure.code,
          'invalid_order_approval_decision_payload',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'fails without calling the repository when the caller lacks order.approve',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership('SALES_REP').copyWith(id: 'rep-1', userId: 'rep-1'),
          ),
        );
        final repository = _FakeOrderApprovalRepository(
          AppSuccess<OrderApprovalDecisionResult>(
            _result(status: OrderStatus.approved),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideOrderApprovalUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'rep-1',
          decision: OrderApprovalDecisionValue.approved,
        );

        expect(result, isA<AppFailure<OrderApprovalDecisionResult>>());
        expect(
          (result as AppFailure<OrderApprovalDecisionResult>).failure.code,
          'order_approve_denied',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'propagates a server-side decision failure without logging analytics',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeOrderApprovalRepository(
          const AppFailure<OrderApprovalDecisionResult>(
            ValidationFailure(
              'Este pedido não está aguardando aprovação.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideOrderApprovalUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'manager-1',
          decision: OrderApprovalDecisionValue.approved,
        );

        expect(result, isA<AppFailure<OrderApprovalDecisionResult>>());
        expect(analytics.loggedEvents, isEmpty);
      },
    );
  });
}

OrderApprovalDecisionResult _result({
  required OrderStatus status,
  String? reason,
}) {
  return OrderApprovalDecisionResult(
    orderId: 'order-1',
    status: status,
    approverId: 'manager-1',
    decidedAt: DateTime.utc(2026, 6, 1, 12),
    reason: reason,
  );
}
