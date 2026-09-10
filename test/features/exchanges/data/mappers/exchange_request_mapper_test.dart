import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/exchanges/exchanges.dart';

void main() {
  group('ExchangeRequestDto/ExchangeRequestMapper', () {
    final requestedAt = Timestamp.fromDate(DateTime.utc(2026, 6, 1, 10));
    final decidedAt = Timestamp.fromDate(DateTime.utc(2026, 6, 2, 15));

    ExchangeRequestDto buildDto() {
      return ExchangeRequestDto.fromJson(<String, dynamic>{
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
            'originProductId': 'product-1',
            'originVariantId': 'variant-origin',
            'originUnitPrice': 100.0,
            'destinationVariantId': 'variant-destination',
            'destinationProductId': 'product-1',
            'quantity': 2,
          },
        ],
        'reasonCategory': 'size_issue',
        'reasonDetails': 'Cliente pediu um tamanho maior.',
        'status': 'approved',
        'priceDifferenceAmount': 50.0,
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
      }, id: 'exchange-1');
    }

    test('fromJson parses every field', () {
      final dto = buildDto();

      expect(dto.id, 'exchange-1');
      expect(dto.orderId, 'order-1');
      expect(dto.items, hasLength(1));
      expect(dto.items.single.destinationVariantId, 'variant-destination');
      expect(dto.priceDifferenceAmount, 50.0);
      expect(dto.decisions, hasLength(1));
      expect(dto.decisions.single.actorId, 'manager-1');
    });

    test(
      'toDomain maps status/reasonCategory codes and every nested field',
      () {
        final domain = buildDto().toDomain();

        expect(domain.id, 'exchange-1');
        expect(domain.status, ExchangeRequestStatus.approved);
        expect(domain.reasonCategory, ExchangeReasonCategory.sizeIssue);
        expect(domain.items.single.orderItemId, 'item-1');
        expect(domain.items.single.originVariantId, 'variant-origin');
        expect(domain.items.single.destinationVariantId, 'variant-destination');
        expect(domain.items.single.quantity, 2);
        expect(
          domain.decisions.single.decision,
          ExchangeRequestDecisionValue.approved,
        );
        expect(domain.decidedBy, 'manager-1');
        expect(domain.priceDifferenceAmount, 50.0);
        expect(domain.totalRequestedQuantity, 2);
      },
    );

    test('toJson/fromJson round-trips every field', () {
      final original = buildDto();

      final roundTripped = ExchangeRequestDto.fromJson(
        original.toJson(),
        id: original.id,
      );

      expect(roundTripped.toDomain(), original.toDomain());
    });

    test('fromJson defaults reasonCategory to "other" when unknown', () {
      final domain = ExchangeRequestDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'orderId': 'order-1',
        'customerId': 'customer-1',
        'sellerId': 'rep-1',
        'currency': 'BRL',
        'reasonCategory': 'not_a_real_category',
        'status': 'requested',
        'requestedBy': 'rep-1',
        'requestedAt': requestedAt,
      }, id: 'exchange-2').toDomain();

      expect(domain.reasonCategory, ExchangeReasonCategory.other);
      expect(domain.status, ExchangeRequestStatus.requested);
      expect(domain.items, isEmpty);
      expect(domain.decisions, isEmpty);
      expect(domain.priceDifferenceAmount, isNull);
    });
  });
}
