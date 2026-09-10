import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/returns/returns.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeReturnRequestRepository implements ReturnRequestRepository {
  int createCallCount = 0;

  @override
  Future<AppResult<ReturnRequestSubmissionResult>> createReturnRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls = const <String>[],
  }) async {
    createCallCount += 1;
    return AppSuccess<ReturnRequestSubmissionResult>(
      ReturnRequestSubmissionResult(
        returnRequestId: returnRequestId,
        orderId: orderId,
        reasonCategory: reasonCategory,
        refundAmount: 200,
        requestedAt: DateTime.utc(2026, 6, 1),
      ),
    );
  }

  @override
  Future<AppResult<ReturnRequestDecisionResult>> resolveReturnRequest({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds = const <String>{},
  }) {
    throw UnimplementedError();
  }
}

class _FakeStorageDataSource implements StorageDataSource {
  @override
  Future<void> deleteFile({required String path}) => throw UnimplementedError();

  @override
  Future<Uint8List> downloadBytes({
    required String path,
    int maxSizeBytes = 10 * 1024 * 1024,
  }) => throw UnimplementedError();

  @override
  Future<String> getDownloadUrl({required String path}) =>
      throw UnimplementedError();

  @override
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(StorageUploadProgress progress)? onProgress,
    StorageUploadCancelToken? cancelToken,
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
        variantId: 'variant-1',
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

Widget _buildApp(ReturnRequestFormCubit Function() createCubit) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('pt'),
    home: ReturnRequestFormPage(
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
  late _FakeReturnRequestRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _FakeReturnRequestRepository();
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

  ReturnRequestFormCubit createCubit() {
    return ReturnRequestFormCubit(
      CreateReturnRequestUseCase(repository, permissionService),
      FakeAnalyticsService(),
      _FakeStorageDataSource(),
      const ImageUploadCompressor(),
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

      expect(find.text('Selecione o motivo da devolução.'), findsOneWidget);
      expect(repository.createCallCount, 0);
    },
  );

  testWidgets('rejects submission without any item selected, never calling the '
      'repository', (tester) async {
    await tester.pumpWidget(_buildApp(createCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdown<ReturnReasonCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Defeito').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar solicitação'));
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione ao menos um item para devolver.'),
      findsOneWidget,
    );
    expect(repository.createCallCount, 0);
  });

  testWidgets(
    'submits successfully once a reason and at least one item are selected',
    (tester) async {
      await tester.pumpWidget(_buildApp(createCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdown<ReturnReasonCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Defeito').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar solicitação'));
      await tester.pumpAndSettle();

      expect(repository.createCallCount, 1);
    },
  );
}
