import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  group('AggregationSnapshotDto.fromJson', () {
    test('parses a well-formed document', () {
      final dto = AggregationSnapshotDto.fromJson(
        <String, dynamic>{
          'organizationId': 'org-1',
          'companyId': 'company-1',
          'scopeId': 'customer-1',
          'periodKey': '2026-08',
          'revenueGross': 1500.5,
          'revenueNet': 1400.25,
          'discountAmount': 100.25,
          'orderCount': 3,
          'itemQuantity': 12,
          'labels': <String, dynamic>{'customerName': 'Loja da Maria'},
          'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 15)),
          'version': 1,
        },
        id: 'company-1_customer-1_2026-08',
        dimension: AggregationDimension.customerMonthly,
      );

      expect(dto.organizationId, 'org-1');
      expect(dto.scopeId, 'customer-1');
      expect(dto.revenueGross, 1500.5);
      expect(dto.labels['customerName'], 'Loja da Maria');
      expect(dto.dimension, AggregationDimension.customerMonthly);
    });

    test('throws ValidationException for a missing required field', () {
      expect(
        () => AggregationSnapshotDto.fromJson(
          <String, dynamic>{'companyId': 'company-1'},
          id: 'doc-1',
          dimension: AggregationDimension.salesDaily,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('defaults numeric fields to zero when absent/malformed', () {
      final dto = AggregationSnapshotDto.fromJson(
        <String, dynamic>{
          'organizationId': 'org-1',
          'companyId': 'company-1',
          'scopeId': 'company-1',
          'periodKey': '2026-08-15',
          'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 15)),
        },
        id: 'doc-1',
        dimension: AggregationDimension.salesDaily,
      );
      expect(dto.revenueGross, 0);
      expect(dto.orderCount, 0);
      expect(dto.itemQuantity, 0);
      expect(dto.labels, isEmpty);
    });
  });

  group('AggregationSnapshotMapper', () {
    test('converts a dto into an entity, preserving every field', () {
      final dto = AggregationSnapshotDto.fromJson(
        <String, dynamic>{
          'organizationId': 'org-1',
          'companyId': 'company-1',
          'scopeId': 'seller-1',
          'periodKey': '2026-08',
          'revenueGross': 500,
          'revenueNet': 480,
          'discountAmount': 20,
          'orderCount': 1,
          'itemQuantity': 5,
          'labels': <String, dynamic>{'sellerName': 'João Vendedor'},
          'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 15)),
          'version': 1,
        },
        id: 'company-1_seller-1_2026-08',
        dimension: AggregationDimension.sellerMonthly,
      );

      final entity = const AggregationSnapshotMapper().toEntity(dto);
      expect(entity.scopeId, 'seller-1');
      expect(entity.dimension, AggregationDimension.sellerMonthly);
      expect(entity.labels['sellerName'], 'João Vendedor');
      expect(entity.generatedAt.toUtc(), DateTime.utc(2026, 8, 15));
    });
  });
}
