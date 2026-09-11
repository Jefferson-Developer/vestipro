import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

final class _FakeFulfillmentRepository implements FulfillmentRepository {
  _FakeFulfillmentRepository(this.shipments);

  final List<Shipment> shipments;

  @override
  Stream<AppResult<List<Shipment>>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  }) async* {
    yield AppSuccess<List<Shipment>>(shipments);
  }

  @override
  Stream<AppResult<List<TrackingEvent>>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  }) async* {
    yield const AppSuccess<List<TrackingEvent>>([]);
  }

  @override
  Stream<AppResult<List<LogisticsIssue>>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  }) async* {
    yield const AppSuccess<List<LogisticsIssue>>([]);
  }

  @override
  Future<AppResult<void>> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required bool resolved,
    String? resolutionNote,
  }) async => const AppSuccess<void>(null);
}

Shipment _buildShipment() => Shipment(
  id: 'shipment-1',
  organizationId: 'org-1',
  companyId: 'company-1',
  orderId: 'order-1',
  customerId: 'customer-1',
  sellerId: 'rep-1',
  carrierName: 'Transportadora Rápida',
  status: ShipmentStatus.shipped,
  hasOpenIssue: false,
  packages: const <ShipmentPackage>[
    ShipmentPackage(
      packageNumber: 1,
      items: <ShipmentPackageItem>[
        ShipmentPackageItem(
          orderItemId: 'item-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 10,
        ),
      ],
    ),
  ],
  deliveredQuantities: const <String, int>{},
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'rep-1',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'rep-1',
          organizationId: 'org-1',
          userId: 'rep-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'rep-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'rep-1',
        ),
      ),
    );
  });

  Widget buildApp(List<Shipment> shipments) {
    final repository = _FakeFulfillmentRepository(shipments);
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt'),
      home: Scaffold(
        body: OrderFulfillmentPanel(
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          userId: 'rep-1',
          permissionService: permissionService,
          createCubit: () => OrderFulfillmentCubit(
            WatchShipmentsForOrderUseCase(repository),
            WatchTrackingEventsUseCase(repository),
            WatchLogisticsIssuesUseCase(repository),
            RegisterLogisticsIssueUseCase(repository),
            ResolveLogisticsIssueUseCase(repository),
            FakeAnalyticsService(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the empty state when no shipment exists yet', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const <Shipment>[]));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma expedição registrada para este pedido ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('renders the shipment summary and a "Reportar ocorrência" '
      'action for an authorized SALES_REP', (tester) async {
    await tester.pumpWidget(buildApp(<Shipment>[_buildShipment()]));
    await tester.pumpAndSettle();

    expect(find.text('Transportadora Rápida'), findsOneWidget);
    expect(find.text('Expedido'), findsOneWidget);
    expect(find.text('Reportar ocorrência'), findsOneWidget);
  });
}
