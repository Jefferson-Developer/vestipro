import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/after_sales/after_sales.dart';

void main() {
  group('PostSaleEventDto/PostSaleEventMapper', () {
    final createdAt = Timestamp.fromDate(DateTime.utc(2026, 6, 1, 10));

    PostSaleEventDto buildDto({
      String type = 'problem_reported',
      String source = 'manual',
      String? sourceRequestId,
      String? description = 'Cliente reportou avaria na peça.',
    }) {
      return PostSaleEventDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'orderId': 'order-1',
        'orderNumber': '000001',
        'customerId': 'customer-1',
        'sellerId': 'rep-1',
        'type': type,
        'description': description,
        'source': source,
        'sourceRequestId': sourceRequestId,
        'createdBy': 'rep-1',
        'createdByName': 'Rep One',
        'createdAt': createdAt,
        'notifiedSeller': true,
      }, id: 'event-1');
    }

    test('fromJson parses every field', () {
      final dto = buildDto();

      expect(dto.id, 'event-1');
      expect(dto.orderId, 'order-1');
      expect(dto.type, 'problem_reported');
      expect(dto.description, 'Cliente reportou avaria na peça.');
      expect(dto.source, 'manual');
      expect(dto.notifiedSeller, isTrue);
    });

    test('toDomain maps type/source codes to the domain enums', () {
      final domain = buildDto().toDomain();

      expect(domain.type, PostSaleEventType.problemReported);
      expect(domain.source, PostSaleEventSource.manual);
      expect(domain.isProblem, isTrue);
    });

    test(
      'toDomain maps a system-sourced devolução event, keeping the link '
      'to its returnRequestId',
      () {
        final domain = buildDto(
          type: 'return_requested',
          source: 'system',
          sourceRequestId: 'return-1',
          description: 'Devolução solicitada (motivo: defect).',
        ).toDomain();

        expect(domain.type, PostSaleEventType.returnRequested);
        expect(domain.source, PostSaleEventSource.system);
        expect(domain.sourceRequestId, 'return-1');
        expect(domain.isProblem, isFalse);
      },
    );

    test('toJson/fromJson round-trips every field', () {
      final dto = buildDto();
      final roundTripped = PostSaleEventDto.fromJson(
        dto.toJson(),
        id: dto.id,
      );

      expect(roundTripped.toDomain(), dto.toDomain());
    });
  });

  group('PostSaleEventType', () {
    test('manualValues carries exactly the six manual milestones', () {
      expect(
        PostSaleEventType.manualValues,
        containsAll(<PostSaleEventType>[
          PostSaleEventType.dispatched,
          PostSaleEventType.inTransit,
          PostSaleEventType.delivered,
          PostSaleEventType.problemReported,
          PostSaleEventType.inResolution,
          PostSaleEventType.resolved,
        ]),
      );
      expect(PostSaleEventType.manualValues, hasLength(6));
      expect(
        PostSaleEventType.manualValues.every((type) => type.isManual),
        isTrue,
      );
    });

    test('only problemReported requires a description', () {
      for (final type in PostSaleEventType.values) {
        expect(
          type.requiresDescription,
          type == PostSaleEventType.problemReported,
        );
      }
    });

    test('system types are never manual', () {
      expect(PostSaleEventType.returnRequested.isManual, isFalse);
      expect(PostSaleEventType.returnResolved.isManual, isFalse);
      expect(PostSaleEventType.exchangeRequested.isManual, isFalse);
      expect(PostSaleEventType.exchangeResolved.isManual, isFalse);
    });
  });
}
