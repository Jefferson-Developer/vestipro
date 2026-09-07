import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

/// A tiny (8x8), genuinely decodable PNG — rasterized through the exact
/// same `dart:ui` `PictureRecorder`/`Canvas`/`toImage`/`toByteData(png)`
/// pipeline `OrderSignaturePad.exportPng` uses in production, never a
/// hand-typed/garbage byte array: `pw.MemoryImage` actually decodes this
/// during `encodeToBytes`, so this exercises the real "assinatura embutida
/// no comprovante" path end to end instead of only asserting it does not
/// throw on nonsense input.
Future<Uint8List> _renderTinyPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = const Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  group('OrderReceiptPdfEncoder (TASK-180)', () {
    const encoder = OrderReceiptPdfEncoder();
    late Uint8List signatureImageBytes;

    setUpAll(() async {
      signatureImageBytes = await _renderTinyPng();
    });

    test(
      'produces a non-empty, valid PDF for an order with no signature yet',
      () async {
        final bytes = await encoder.encodeToBytes(order: _order());

        expect(bytes, isNotEmpty);
        // Every PDF starts with the "%PDF-" magic header.
        expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      },
    );

    test('produces a larger document once a signature is embedded', () async {
      final withoutSignature = await encoder.encodeToBytes(order: _order());
      final withSignature = await encoder.encodeToBytes(
        order: _order(),
        signature: _signature(signatureImageBytes),
      );

      expect(withSignature.length, greaterThan(withoutSignature.length));
    });
  });
}

Order _order() {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
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
    paymentTermId: 'term-1',
    items: const <OrderItem>[
      OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 88,
        discountAmount: 12,
        subtotal: 176,
      ),
    ],
    discountAmount: 24,
    status: OrderStatus.submitted,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.synced,
  );
}

OrderSignature _signature(Uint8List imageBytes) {
  final now = DateTime.utc(2026, 6, 1, 12);
  return OrderSignature(
    id: 'signature-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    signerRole: OrderSignerRole.customer,
    signedByUserId: 'seller-1',
    signedByName: 'Maria Cliente',
    method: OrderSignatureMethod.canvasDrawn,
    imageBytes: imageBytes,
    contentHash: 'hash-1',
    orderVersionAtSignature: 1,
    signedAt: now,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSignatureSyncStatus.synced,
  );
}
