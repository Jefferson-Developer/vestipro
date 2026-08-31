import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockOrderListRepository extends Mock implements OrderListRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('GetOrderByIdUseCase', () {
    late _MockOrderListRepository orderListRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late PermissionService permissionService;
    late OrderVisibilityService visibilityService;
    late GetOrderByIdUseCase useCase;

    setUp(() {
      orderListRepository = _MockOrderListRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      permissionService = PermissionService(membershipRepository);
      visibilityService = OrderVisibilityService(
        PortfolioVisibilityService(membershipRepository, teamRepository),
        teamRepository,
      );
      useCase = GetOrderByIdUseCase(
        orderListRepository,
        visibilityService,
        permissionService,
      );
    });

    Membership buildMembership(String userId, String roleName) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: userId,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: userId,
      );
    }

    test('SALES_REP may read their own order', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-1', 'SALES_REP')),
      );
      when(
        () => orderListRepository.getById(
          organizationId: 'org-1',
          companyId: 'company-1',
          id: 'order-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Order?>(_order(id: 'order-1', sellerId: 'rep-1')),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
      );

      expect(result, isA<AppSuccess<Order>>());
      expect((result as AppSuccess<Order>).value.id, 'order-1');
    });

    test(
      'SALES_REP is denied when the order belongs to a different seller',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership('rep-1', 'SALES_REP')),
        );
        when(
          () => orderListRepository.getById(
            organizationId: 'org-1',
            companyId: 'company-1',
            id: 'order-2',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Order?>(_order(id: 'order-2', sellerId: 'rep-2')),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-2',
        );

        expect(result, isA<AppFailure<Order>>());
        expect((result as AppFailure<Order>).failure, isA<PermissionFailure>());
      },
    );

    test('OWNER may read any order of the company', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'owner-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('owner-1', 'OWNER')),
      );
      when(
        () => orderListRepository.getById(
          organizationId: 'org-1',
          companyId: 'company-1',
          id: 'order-3',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Order?>(_order(id: 'order-3', sellerId: 'rep-9')),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        orderId: 'order-3',
      );

      expect(result, isA<AppSuccess<Order>>());
    });

    test('a role without order.view (e.g. FINANCE) is denied without ever '
        'reaching the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'finance-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('finance-1', 'FINANCE')),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'finance-1',
        orderId: 'order-1',
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<PermissionFailure>());
      verifyNever(
        () => orderListRepository.getById(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          id: any(named: 'id'),
        ),
      );
    });

    test('returns a NotFoundFailure when the order does not exist', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'owner-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('owner-1', 'OWNER')),
      );
      when(
        () => orderListRepository.getById(
          organizationId: 'org-1',
          companyId: 'company-1',
          id: 'missing-order',
        ),
      ).thenAnswer((_) async => const AppSuccess<Order?>(null));

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        orderId: 'missing-order',
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<NotFoundFailure>());
    });

    test('returns a ValidationFailure without checking permissions when '
        'required fields are blank', () async {
      final result = await useCase(
        organizationId: '',
        companyId: '',
        userId: '',
        orderId: '',
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<ValidationFailure>());
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}

Order _order({required String id, required String sellerId}) {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: sellerId,
    deliveryAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    status: OrderStatus.submitted,
    createdAt: now,
    createdBy: sellerId,
    updatedAt: now,
    updatedBy: sellerId,
    version: 1,
    syncStatus: OrderSyncStatus.synced,
  );
}
