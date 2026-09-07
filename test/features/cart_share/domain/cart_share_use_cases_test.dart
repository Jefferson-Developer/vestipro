import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/cart_share/cart_share.dart';

class _Repository extends Mock implements CartShareRepository {}

void main() {
  late _Repository repository;
  const item = CartShareDraftItem(
    itemId: 'line-1',
    productId: 'product-1',
    productName: 'Camisa',
    variantId: 'blue-m',
    quantity: 2,
    unitPrice: 50,
  );

  setUpAll(() {
    registerFallbackValue(const <CartShareDraftItem>[]);
    registerFallbackValue(CartShareDecision.approved);
    registerFallbackValue(const <String>[]);
  });

  setUp(() => repository = _Repository());

  test(
    'creates a scoped cart snapshot with version and price preference',
    () async {
      final issued = IssuedCartShare(
        token: 'secure',
        expiresAt: DateTime.utc(2026),
        showPrices: true,
      );
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          sourceCartId: any(named: 'sourceCartId'),
          sourceCartVersion: any(named: 'sourceCartVersion'),
          items: any(named: 'items'),
          showPrices: any(named: 'showPrices'),
        ),
      ).thenAnswer((_) async => AppSuccess(issued));
      final result = await CreateCartShareUseCase(repository)(
        organizationId: ' org-1 ',
        sourceCartId: ' draft-1 ',
        sourceCartVersion: 4,
        items: const <CartShareDraftItem>[item],
        showPrices: true,
      );
      expect(result, isA<AppSuccess<IssuedCartShare>>());
      verify(
        () => repository.create(
          organizationId: 'org-1',
          sourceCartId: 'draft-1',
          sourceCartVersion: 4,
          items: const <CartShareDraftItem>[item],
          showPrices: true,
        ),
      ).called(1);
    },
  );

  test('rejects an empty cart before reaching infrastructure', () async {
    final result = await CreateCartShareUseCase(repository)(
      organizationId: 'org-1',
      sourceCartId: 'draft-1',
      sourceCartVersion: 1,
      items: const <CartShareDraftItem>[],
      showPrices: false,
    );
    expect(result, isA<AppFailure<IssuedCartShare>>());
    verifyNever(
      () => repository.create(
        organizationId: any(named: 'organizationId'),
        sourceCartId: any(named: 'sourceCartId'),
        sourceCartVersion: any(named: 'sourceCartVersion'),
        items: any(named: 'items'),
        showPrices: any(named: 'showPrices'),
      ),
    );
  });

  test('a change request requires a comment', () async {
    final result = await ReviewCartShareUseCase(repository)(
      token: 'token',
      decision: CartShareDecision.changesRequested,
    );
    expect(result, isA<AppFailure<void>>());
    verifyNever(
      () => repository.review(
        token: any(named: 'token'),
        decision: any(named: 'decision'),
        comment: any(named: 'comment'),
        rejectedItemIds: any(named: 'rejectedItemIds'),
      ),
    );
  });
}
