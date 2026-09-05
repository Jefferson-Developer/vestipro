import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('ProcessOrderCommercialAlertUseCase', () {
    late _FakeOrderCommercialAlertDispatchRepository dispatchRepository;
    late _FakeNotificationInboxRepository notificationInboxRepository;
    late FakeCommunicationPreferencesRepository preferencesRepository;
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analyticsService;
    late ProcessOrderCommercialAlertUseCase useCase;

    setUp(() {
      dispatchRepository = _FakeOrderCommercialAlertDispatchRepository();
      notificationInboxRepository = _FakeNotificationInboxRepository();
      preferencesRepository = FakeCommunicationPreferencesRepository();
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      analyticsService = FakeAnalyticsService();
      useCase = ProcessOrderCommercialAlertUseCase(
        dispatchRepository,
        notificationInboxRepository,
        ShouldDispatchNotificationUseCase(preferencesRepository),
        permissionService,
        analyticsService,
      );
    });

    void mockMembership(String userId, String roleName) {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: userId,
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(_buildMembership(userId, roleName)),
      );
    }

    test('dispatches a critical notification for a rejected order, without the '
        'monetary value when the recipient lacks finance.view', () async {
      mockMembership('rep-1', 'SALES_REP');
      final order = _buildOrder(
        status: OrderStatus.rejected,
        rejectionReason: 'Fora da política de desconto',
      );

      final dispatched = await useCase(
        order: order,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );

      expect(dispatched, isTrue);
      expect(notificationInboxRepository.items, hasLength(1));
      final notification = notificationInboxRepository.items.single;
      expect(notification.category, AppNotificationCategory.commercial);
      expect(notification.priority, AppNotificationPriority.critical);
      expect(notification.body, contains('Fora da política de desconto'));
      expect(notification.body, isNot(contains('R\$')));
      expect(
        notification.deepLink,
        OrderHistoryRoute(
          orgId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
        ).location,
      );
      expect(
        analyticsService.loggedEvents.single.name,
        AnalyticsEvents.commercialOrderAlertTriggered,
      );
      expect(
        analyticsService.loggedEvents.single.parameters?.keys,
        isNot(contains('amount')),
      );
    });

    test(
      'includes the items amount when the recipient holds finance.view',
      () async {
        mockMembership('finance-1', 'FINANCE');
        final order = _buildOrder(
          status: OrderStatus.rejected,
          rejectionReason: 'Fora da política de desconto',
        );

        await useCase(
          order: order,
          recipientUserId: 'finance-1',
          now: DateTime.utc(2026, 6, 1),
        );

        expect(notificationInboxRepository.items.single.body, contains('R\$'));
      },
    );

    test(
      'dispatches a critical notification for a pedido that failed to sync',
      () async {
        mockMembership('rep-1', 'SALES_REP');
        final order = _buildOrder(syncStatus: OrderSyncStatus.failed);

        final dispatched = await useCase(
          order: order,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 1),
        );

        expect(dispatched, isTrue);
        expect(
          analyticsService.loggedEvents.single.parameters?['classification'],
          OrderCommercialAlertClassification.criticalSyncFailure.name,
        );
      },
    );

    test('does not notify a pedido with no problem', () async {
      mockMembership('rep-1', 'SALES_REP');
      final order = _buildOrder();

      final dispatched = await useCase(
        order: order,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });

    test(
      'never dispatches the same (order, classification, recipient) twice',
      () async {
        mockMembership('rep-1', 'SALES_REP');
        final order = _buildOrder(status: OrderStatus.rejected);

        await useCase(
          order: order,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 1),
        );
        final second = await useCase(
          order: order,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 2),
        );

        expect(second, isFalse);
        expect(notificationInboxRepository.items, hasLength(1));
      },
    );

    test('does not notify when the recipient disabled the commercial/central '
        'preference (TASK-154)', () async {
      mockMembership('rep-1', 'SALES_REP');
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'rep-1',
        ).withChannelFrequency(
          category: AppNotificationCategory.commercial,
          channel: CommunicationChannel.inApp,
          frequency: CommunicationFrequency.disabled,
        ),
      );
      final order = _buildOrder(status: OrderStatus.rejected);

      final dispatched = await useCase(
        order: order,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });
  });
}

Membership _buildMembership(String userId, String roleName) {
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

Order _buildOrder({
  OrderStatus status = OrderStatus.submitted,
  OrderSyncStatus syncStatus = OrderSyncStatus.synced,
  String? rejectionReason,
}) {
  final createdAt = DateTime.utc(2026, 5, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    orderNumber: '000456',
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
    items: <OrderItem>[
      const OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 50,
        subtotal: 100,
      ),
    ],
    status: status,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
    createdBy: 'rep-1',
    updatedAt: createdAt,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: syncStatus,
  );
}

final class _FakeOrderCommercialAlertDispatchRepository
    implements OrderCommercialAlertDispatchRepository {
  final Map<String, DateTime> _records = <String, DateTime>{};

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
  }) async {
    return AppSuccess<DateTime?>(
      _records['$organizationId::$orderId::$recipientUserId::'
          '${classification.name}'],
    );
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String orderId,
    required String recipientUserId,
    required OrderCommercialAlertClassification classification,
    required DateTime dispatchedAt,
  }) async {
    _records['$organizationId::$orderId::$recipientUserId::'
            '${classification.name}'] =
        dispatchedAt;
    return AppSuccess<DateTime>(dispatchedAt);
  }
}

final class _FakeNotificationInboxRepository
    implements NotificationInboxRepository {
  final List<AppNotification> items = <AppNotification>[];

  @override
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  }) async {
    items.add(notification);
    return AppSuccess<AppNotification>(notification);
  }

  @override
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  }) async => AppSuccess<List<AppNotification>>(items);

  @override
  Future<AppResult<void>> markAsRead({
    required String organizationId,
    required String userId,
    required String notificationId,
    DateTime? readAt,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> markAllAsRead({
    required String organizationId,
    required String userId,
    DateTime? readAt,
  }) async => const AppSuccess<void>(null);
}
