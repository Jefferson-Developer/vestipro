import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/exchanges/exchanges.dart';
import 'package:vestipro/features/inventory/inventory.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/domain/entities/product_variant.dart';
import 'package:vestipro/features/products/domain/repositories/product_variant_repository.dart';
import 'package:vestipro/features/products/domain/usecases/list_product_variants_by_product_use_case.dart';
import 'package:vestipro/features/products/domain/value_objects/ean.dart';
import 'package:vestipro/features/products/domain/value_objects/product_sync_status.dart';
import 'package:vestipro/features/products/domain/value_objects/product_variant_status.dart';
import 'package:vestipro/features/products/domain/value_objects/sku.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeExchangeRequestRepository implements ExchangeRequestRepository {
  int createCallCount = 0;

  @override
  Future<AppResult<ExchangeRequestSubmissionResult>> createExchangeRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  }) async {
    createCallCount += 1;
    return AppSuccess<ExchangeRequestSubmissionResult>(
      ExchangeRequestSubmissionResult(
        exchangeRequestId: exchangeRequestId,
        orderId: orderId,
        reasonCategory: reasonCategory,
        requestedAt: DateTime.utc(2026, 6, 1),
      ),
    );
  }

  @override
  Future<AppResult<ExchangeRequestDecisionResult>> resolveExchangeRequest({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds = const <String>{},
  }) {
    throw UnimplementedError();
  }
}

class _FakeProductVariantRepository implements ProductVariantRepository {
  final destinationVariant = ProductVariant(
    id: 'variant-destination',
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: 'color-2',
    sizeGridTemplateId: 'grid-1',
    sizeId: 'size-m',
    sku: Sku.parse('PROD1-DEST'),
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'owner-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'owner-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );

  @override
  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    return AppSuccess<List<ProductVariant>>(<ProductVariant>[
      destinationVariant,
    ]);
  }

  @override
  Future<AppResult<ProductVariant>> create({required ProductVariant variant}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  ) => throw UnimplementedError();

  @override
  Future<AppResult<ProductVariant>> update({required ProductVariant variant}) =>
      throw UnimplementedError();
}

class _FakeVariantStockBalanceRepository
    implements VariantStockBalanceRepository {
  @override
  Future<AppResult<VariantInventoryAvailability>> getAvailability({
    required String organizationId,
    required String variantId,
    String? warehouseId,
  }) async {
    return AppSuccess<VariantInventoryAvailability>(
      VariantInventoryAvailability(
        variantId: variantId,
        productId: 'product-1',
        totalSellableQuantity: 10,
        byWarehouse: const <VariantStockBalance>[],
      ),
    );
  }

  @override
  Future<AppResult<List<VariantStockBalance>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<VariantStockBalance>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<VariantStockBalance>>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  }) => throw UnimplementedError();
}

Order _buildOrder() {
  final now = DateTime.utc(2026, 1, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    orderNumber: '000001',
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
    paymentTermId: 'payment-term-1',
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        id: 'item-1',
        variantId: 'variant-origin',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
      ),
    ],
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.synced,
  );
}

Widget _buildApp(ExchangeRequestFormCubit Function() createCubit) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('pt'),
    home: ExchangeRequestFormPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'rep-1',
      order: _buildOrder(),
      createCubit: createCubit,
    ),
  );
}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _FakeExchangeRequestRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _FakeExchangeRequestRepository();
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

  ExchangeRequestFormCubit createCubit() {
    return ExchangeRequestFormCubit(
      CreateExchangeRequestUseCase(repository, permissionService),
      ListProductVariantsByProductUseCase(_FakeProductVariantRepository()),
      GetVariantInventoryAvailabilityUseCase(
        _FakeVariantStockBalanceRepository(),
      ),
      FakeAnalyticsService(),
    );
  }

  testWidgets(
    'rejects submission without a categorized reason, never calling the '
    'repository',
    (tester) async {
      await tester.pumpWidget(_buildApp(createCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar solicitação'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione o motivo da troca.'), findsOneWidget);
      expect(repository.createCallCount, 0);
    },
  );

  testWidgets('rejects submission without any item selected, never calling the '
      'repository', (tester) async {
    await tester.pumpWidget(_buildApp(createCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdown<ExchangeReasonCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamanho errado').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar solicitação'));
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione ao menos um item para trocar.'),
      findsOneWidget,
    );
    expect(repository.createCallCount, 0);
  });

  testWidgets(
    'submits successfully once a reason, an item and a destination variant '
    'are selected',
    (tester) async {
      await tester.pumpWidget(_buildApp(createCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdown<ExchangeReasonCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamanho errado').last);
      await tester.pumpAndSettle();

      // Bumps the item's own quantity stepper to 1, which reveals the
      // destination-variant dropdown (TASK-200's own real-time selector).
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PROD1-DEST').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar solicitação'));
      await tester.pumpAndSettle();

      expect(repository.createCallCount, 1);
    },
  );
}
