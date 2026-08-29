import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('StockTurnoverMetricSnapshotDto', () {
    test('round-trips a stable payload shape', () {
      final dto = StockTurnoverMetricSnapshotDto(
        id: 'product_product-1_2026-08-01_2026-08-30',
        organizationId: 'org-1',
        scopeType: 'product',
        scopeId: 'product-1',
        periodStart: DateTime.utc(2026, 8, 1),
        periodEnd: DateTime.utc(2026, 8, 30),
        coveredDays: 30,
        sellThroughRate: 0.45,
        stockCoverageDays: 12.5,
        turnoverRate: 1.8,
        openingStockQuantity: 100,
        receivedQuantity: 20,
        soldQuantity: 54,
        closingStockQuantity: 66,
        averageStockQuantity: 30.0,
        averageDailySalesQuantity: 1.8,
        coverageStatus: 'ready',
        generatedAt: DateTime.utc(2026, 8, 31),
      );

      final json = dto.toJson();

      expect(
        json.keys,
        containsAll(<String>[
          'organizationId',
          'scopeType',
          'scopeId',
          'periodStart',
          'periodEnd',
          'coveredDays',
          'sellThroughRate',
          'stockCoverageDays',
          'turnoverRate',
          'openingStockQuantity',
          'receivedQuantity',
          'soldQuantity',
          'closingStockQuantity',
          'averageStockQuantity',
          'averageDailySalesQuantity',
          'coverageStatus',
          'generatedAt',
        ]),
      );

      final reparsed = StockTurnoverMetricSnapshotDto.fromJson(
        Map<String, dynamic>.from(json),
        id: dto.id,
      );

      expect(reparsed.scopeType, 'product');
      expect(reparsed.scopeId, 'product-1');
      expect(reparsed.coverageStatus, 'ready');
      expect(reparsed.sellThroughRate, closeTo(0.45, 0.0001));
      expect(json['periodStart'], isA<Timestamp>());
      expect(json['generatedAt'], isA<Timestamp>());
    });
  });
}
