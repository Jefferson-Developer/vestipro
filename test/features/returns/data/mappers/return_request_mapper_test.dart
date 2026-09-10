import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/returns/returns.dart';

void main() {
  group('ReturnRequestDto/ReturnRequestMapper', () {
    final requestedAt = Timestamp.fromDate(DateTime.utc(2026, 6, 1, 10));
    final decidedAt = Timestamp.fromDate(DateTime.utc(2026, 6, 2, 15));

    ReturnRequestDto buildDto() {
      return ReturnRequestDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'orderId': 'order-1',
        'orderNumber': '000001',
        'customerId': 'customer-1',
        'sellerId': 'rep-1',
        'currency': 'BRL',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'orderItemId': 'item-1',
            'productId': 'product-1',
            'variantId': 'variant-1',
            'quantity': 2,
            'unitPrice': 100.0,
            'subtotal': 200.0,
            'warehouseId': 'wh-1',
          },
        ],
        'reasonCategory': 'defect',
        'reasonDetails': 'Produto veio com defeito na costura.',
        'evidenceUrls': <String>['https://files.example.com/evidence.jpg'],
        'status': 'approved',
        'refundAmount': 200.0,
        'requestedBy': 'rep-1',
        'requestedByName': 'Rep One',
        'requestedAt': requestedAt,
        'decisions': <Map<String, dynamic>>[
          <String, dynamic>{
            'decision': 'approved',
            'actorId': 'manager-1',
            'actorName': 'Manager One',
            'reason': null,
            'decidedAt': decidedAt,
          },
        ],
        'decidedBy': 'manager-1',
        'decidedAt': decidedAt,
        'decisionReason': null,
      }, id: 'return-1');
    }

    test('fromJson parses every field', () {
      final dto = buildDto();

      expect(dto.id, 'return-1');
      expect(dto.orderId, 'order-1');
      expect(dto.items, hasLength(1));
      expect(dto.items.single.warehouseId, 'wh-1');
      expect(dto.decisions, hasLength(1));
      expect(dto.decisions.single.actorId, 'manager-1');
    });

    test(
      'toDomain maps status/reasonCategory codes and every nested field',
      () {
        final domain = buildDto().toDomain();

        expect(domain.id, 'return-1');
        expect(domain.status, ReturnRequestStatus.approved);
        expect(domain.reasonCategory, ReturnReasonCategory.defect);
        expect(domain.items.single.orderItemId, 'item-1');
        expect(domain.items.single.quantity, 2);
        expect(domain.items.single.warehouseId, 'wh-1');
        expect(
          domain.decisions.single.decision,
          ReturnRequestDecisionValue.approved,
        );
        expect(domain.decisions.single.actorId, 'manager-1');
        expect(domain.decidedBy, 'manager-1');
        expect(domain.refundAmount, 200.0);
        expect(domain.totalRequestedQuantity, 2);
      },
    );

    test('toJson/fromJson round-trips every field', () {
      final original = buildDto();

      final roundTripped = ReturnRequestDto.fromJson(
        original.toJson(),
        id: original.id,
      );

      expect(roundTripped.toDomain(), original.toDomain());
    });

    test('fromJson defaults reasonCategory to "other" when unknown', () {
      final domain = ReturnRequestDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'orderId': 'order-1',
        'customerId': 'customer-1',
        'sellerId': 'rep-1',
        'currency': 'BRL',
        'reasonCategory': 'not_a_real_category',
        'status': 'requested',
        'refundAmount': 0.0,
        'requestedBy': 'rep-1',
        'requestedAt': requestedAt,
      }, id: 'return-2').toDomain();

      expect(domain.reasonCategory, ReturnReasonCategory.other);
      expect(domain.status, ReturnRequestStatus.requested);
      expect(domain.items, isEmpty);
      expect(domain.decisions, isEmpty);
    });
  });
}
