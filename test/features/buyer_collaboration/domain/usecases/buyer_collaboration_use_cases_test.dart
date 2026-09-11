import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/buyer_collaboration/buyer_collaboration.dart';

class _Repository extends Mock implements BuyerCollaborationRepository {}

void main() {
  late _Repository repository;

  const item = BuyerCollaborationItem(
    itemId: 'line-1',
    productId: 'product-1',
    productName: 'Vestido Floral',
    variantId: 'variant-1',
    quantity: 10,
    unitPrice: 100,
    subtotal: 1000,
  );

  setUpAll(() {
    registerFallbackValue(const <BuyerCollaborationItem>[]);
    registerFallbackValue(BuyerCollaborationSourceType.orderDraft);
    registerFallbackValue(BuyerCollaborationCommentVisibility.shared);
    registerFallbackValue(const <BuyerCollaborationAttachment>[]);
    registerFallbackValue(const <String>[]);
    registerFallbackValue(const <BuyerCollaborationProposedChange>[]);
  });

  setUp(() => repository = _Repository());

  group('CreateBuyerCollaborationSessionUseCase', () {
    test('rejects an empty selection before reaching infrastructure', () async {
      final result = await CreateBuyerCollaborationSessionUseCase(repository)(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        priceListId: 'price-list-1',
        sourceType: BuyerCollaborationSourceType.orderDraft,
        sourceId: 'draft-1',
        items: const <BuyerCollaborationItem>[],
        showPrices: true,
      );
      expect(result, isA<AppFailure<String>>());
      verifyNever(
        () => repository.createSession(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          customerId: any(named: 'customerId'),
          priceListId: any(named: 'priceListId'),
          sourceType: any(named: 'sourceType'),
          sourceId: any(named: 'sourceId'),
          items: any(named: 'items'),
          showPrices: any(named: 'showPrices'),
        ),
      );
    });

    test('forwards a non-empty selection to the repository', () async {
      when(
        () => repository.createSession(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          customerId: any(named: 'customerId'),
          priceListId: any(named: 'priceListId'),
          sourceType: any(named: 'sourceType'),
          sourceId: any(named: 'sourceId'),
          items: any(named: 'items'),
          showPrices: any(named: 'showPrices'),
        ),
      ).thenAnswer((_) async => const AppSuccess<String>('session-1'));

      final result = await CreateBuyerCollaborationSessionUseCase(repository)(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        priceListId: 'price-list-1',
        sourceType: BuyerCollaborationSourceType.orderDraft,
        sourceId: 'draft-1',
        items: const <BuyerCollaborationItem>[item],
        showPrices: true,
      );
      expect(result, isA<AppSuccess<String>>());
    });
  });

  group('ShareBuyerCollaborationSessionUseCase', () {
    test('rejects an explicitly empty item list', () async {
      final result = await ShareBuyerCollaborationSessionUseCase(repository)(
        organizationId: 'org-1',
        sessionId: 'session-1',
        items: const <BuyerCollaborationItem>[],
      );
      expect(result, isA<AppFailure<void>>());
      verifyNever(
        () => repository.shareSession(
          organizationId: any(named: 'organizationId'),
          sessionId: any(named: 'sessionId'),
          items: any(named: 'items'),
          note: any(named: 'note'),
        ),
      );
    });

    test('allows sharing without replacing the item snapshot', () async {
      when(
        () => repository.shareSession(
          organizationId: any(named: 'organizationId'),
          sessionId: any(named: 'sessionId'),
          items: any(named: 'items'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await ShareBuyerCollaborationSessionUseCase(repository)(
        organizationId: 'org-1',
        sessionId: 'session-1',
      );
      expect(result, isA<AppSuccess<void>>());
    });
  });

  group('AddBuyerCollaborationCommentUseCase', () {
    test('rejects a blank comment', () async {
      final result = await AddBuyerCollaborationCommentUseCase(repository)(
        organizationId: 'org-1',
        sessionId: 'session-1',
        body: '   ',
      );
      expect(result, isA<AppFailure<void>>());
      verifyNever(
        () => repository.addComment(
          organizationId: any(named: 'organizationId'),
          sessionId: any(named: 'sessionId'),
          body: any(named: 'body'),
          itemId: any(named: 'itemId'),
          visibility: any(named: 'visibility'),
          attachments: any(named: 'attachments'),
          mentionedMemberIds: any(named: 'mentionedMemberIds'),
        ),
      );
    });
  });

  group('RequestBuyerCollaborationChangesUseCase', () {
    test('rejects a change request without an explanation', () async {
      final result = await RequestBuyerCollaborationChangesUseCase(repository)(
        organizationId: 'org-1',
        sessionId: 'session-1',
        comment: '',
      );
      expect(result, isA<AppFailure<void>>());
      verifyNever(
        () => repository.requestChanges(
          organizationId: any(named: 'organizationId'),
          sessionId: any(named: 'sessionId'),
          comment: any(named: 'comment'),
          proposedChanges: any(named: 'proposedChanges'),
        ),
      );
    });
  });
}
