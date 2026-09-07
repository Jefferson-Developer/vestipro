import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/cart_share/cart_share.dart';

final class _Repository implements CartShareRepository {
  CartShareDecision? lastDecision;
  @override
  Future<AppResult<CartSharePreview>> preview({required String token}) async =>
      const AppSuccess(
        CartSharePreview(
          outcome: CartShareOutcome.valid,
          organizationName: 'Moda Ltda',
          showPrices: true,
          total: 100,
          items: <CartShareItem>[
            CartShareItem(
              itemId: 'line-1',
              productName: 'Camisa',
              variantId: 'azul-m',
              quantity: 2,
              subtotal: 100,
            ),
          ],
        ),
      );

  @override
  Future<AppResult<void>> review({
    required String token,
    required CartShareDecision decision,
    String? comment,
    List<String> rejectedItemIds = const <String>[],
  }) async {
    lastDecision = decision;
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<IssuedCartShare>> create({
    required String organizationId,
    required String sourceCartId,
    required int sourceCartVersion,
    required List<CartShareDraftItem> items,
    required bool showPrices,
  }) => throw UnimplementedError();
}

final class _Analytics implements AnalyticsService {
  final events = <String>[];
  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async => events.add(name);
  @override
  Future<void> setUserId(String? userId) async {}
  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}

void main() {
  testWidgets(
    'customer reviews quantities/prices and approval remains only a signal',
    (tester) async {
      final repository = _Repository();
      final analytics = _Analytics();
      CartShareCubit createCubit() => CartShareCubit(
        createCartShare: CreateCartShareUseCase(repository),
        previewCartShare: PreviewCartShareUseCase(repository),
        reviewCartShare: ReviewCartShareUseCase(repository),
        analytics: analytics,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CartSharePublicPage(token: 'token', createCubit: createCubit),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Camisa'), findsOneWidget);
      expect(find.textContaining('2 un.'), findsOneWidget);
      expect(find.textContaining('Total:'), findsOneWidget);
      await tester.tap(find.text('Aprovar seleção'));
      await tester.pumpAndSettle();
      expect(repository.lastDecision, CartShareDecision.approved);
      expect(find.text('Resposta enviada'), findsOneWidget);
      expect(analytics.events, contains(AnalyticsEvents.cartShareReviewed));
    },
  );
}
