import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customer_portal/customer_portal.dart';

final class _FakeRepository implements CustomerPortalRepository {
  _FakeRepository(this.snapshot);
  final CustomerPortalSnapshot snapshot;
  @override
  Future<CustomerPortalSnapshot> load(String organizationId) async => snapshot;
  @override
  Future<List<RevalidatedPortalItem>> repeatOrder({
    required String organizationId,
    required String orderId,
  }) async => const [
    RevalidatedPortalItem(
      productId: 'p1',
      variantId: 'v1',
      quantity: 1,
      unitPrice: 129.9,
    ),
  ];
  @override
  Future<String> createInvite({
    required String organizationId,
    required String customerId,
    required String email,
  }) async => 'token';
  @override
  Future<void> acceptInvite(String token) async {}
}

void main() {
  const snapshot = CustomerPortalSnapshot(
    customerId: 'customer-a',
    branding: CustomerPortalBranding(name: 'Moda da Loja'),
    products: [CustomerPortalProduct(id: 'p1', name: 'Vestido')],
    orders: [
      CustomerPortalOrder(
        id: 'o1',
        orderNumber: '42',
        status: 'em trânsito',
        total: 129.9,
      ),
    ],
  );

  testWidgets(
    'exibe tema, catálogo, histórico e repete pedido em mobile e web',
    (tester) async {
      final repository = _FakeRepository(snapshot);
      final cubit = CustomerPortalCubit(
        LoadCustomerPortalUseCase(repository),
        RepeatCustomerPortalOrderUseCase(repository),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerPortalPage(organizationId: 'org-a', cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Moda da Loja'), findsOneWidget);
      expect(find.text('Vestido'), findsOneWidget);
      expect(find.text('Pedido 42'), findsOneWidget);
      await tester.tap(find.text('Repetir pedido'));
      await tester.pumpAndSettle();
      expect(find.textContaining('preço e estoque atuais'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pump();
      expect(find.text('Catálogo'), findsOneWidget);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    },
  );

  test('provisionamento normaliza e valida e-mail', () async {
    final useCase = ProvisionCustomerPortalAccessUseCase(
      _FakeRepository(snapshot),
    );
    expect(
      await useCase(
        organizationId: 'org-a',
        customerId: 'customer-a',
        email: ' Buyer@Store.com ',
      ),
      'token',
    );
    expect(
      () => useCase(
        organizationId: 'org-a',
        customerId: 'customer-a',
        email: 'invalid',
      ),
      throwsArgumentError,
    );
  });
}
