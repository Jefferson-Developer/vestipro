import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/storage/storage.dart';

void main() {
  group('StoragePaths', () {
    test('productFile builds organizations/{org}/products/{id}/{file}', () {
      final path = StoragePaths.productFile(
        organizationId: 'org-1',
        productId: 'product-1',
        fileName: 'front.jpg',
      );

      expect(path, 'organizations/org-1/products/product-1/front.jpg');
    });

    test(
      'orderAttachment builds organizations/{org}/orders/{id}/attachments/{file}',
      () {
        final path = StoragePaths.orderAttachment(
          organizationId: 'org-1',
          orderId: 'order-1',
          fileName: 'invoice.pdf',
        );

        expect(
          path,
          'organizations/org-1/orders/order-1/attachments/invoice.pdf',
        );
      },
    );

    test('userAvatar builds organizations/{org}/users/{id}/avatar', () {
      final path = StoragePaths.userAvatar(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(path, 'organizations/org-1/users/user-1/avatar');
    });

    test('productFile throws ArgumentError for empty organizationId', () {
      expect(
        () => StoragePaths.productFile(
          organizationId: '',
          productId: 'product-1',
          fileName: 'front.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('orderAttachment throws ArgumentError for empty organizationId', () {
      expect(
        () => StoragePaths.orderAttachment(
          organizationId: '   ',
          orderId: 'order-1',
          fileName: 'invoice.pdf',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('userAvatar throws ArgumentError for empty organizationId', () {
      expect(
        () => StoragePaths.userAvatar(organizationId: '', userId: 'user-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('productFile throws ArgumentError for empty productId', () {
      expect(
        () => StoragePaths.productFile(
          organizationId: 'org-1',
          productId: '',
          fileName: 'front.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('productFile throws ArgumentError for empty fileName', () {
      expect(
        () => StoragePaths.productFile(
          organizationId: 'org-1',
          productId: 'product-1',
          fileName: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('campaignFile builds organizations/{org}/campaigns/{id}/{file}', () {
      final path = StoragePaths.campaignFile(
        organizationId: 'org-1',
        campaignId: 'campaign-1',
        fileName: 'cover.jpg',
      );

      expect(path, 'organizations/org-1/campaigns/campaign-1/cover.jpg');
    });

    test('campaignFile throws ArgumentError for empty campaignId', () {
      expect(
        () => StoragePaths.campaignFile(
          organizationId: 'org-1',
          campaignId: '',
          fileName: 'cover.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
