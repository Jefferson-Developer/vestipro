import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class StockTurnoverMetricSnapshotDto {
  const StockTurnoverMetricSnapshotDto({
    required this.id,
    required this.organizationId,
    required this.scopeType,
    required this.scopeId,
    required this.periodStart,
    required this.periodEnd,
    required this.coveredDays,
    required this.sellThroughRate,
    required this.stockCoverageDays,
    required this.turnoverRate,
    required this.openingStockQuantity,
    required this.receivedQuantity,
    required this.soldQuantity,
    required this.closingStockQuantity,
    required this.averageStockQuantity,
    required this.averageDailySalesQuantity,
    required this.coverageStatus,
    required this.generatedAt,
  });

  factory StockTurnoverMetricSnapshotDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final scopeType = json['scopeType'];
    final scopeId = json['scopeId'];
    final periodStart = json['periodStart'];
    final periodEnd = json['periodEnd'];
    final coveredDays = json['coveredDays'];
    final sellThroughRate = json['sellThroughRate'];
    final stockCoverageDays = json['stockCoverageDays'];
    final turnoverRate = json['turnoverRate'];
    final openingStockQuantity = json['openingStockQuantity'];
    final receivedQuantity = json['receivedQuantity'];
    final soldQuantity = json['soldQuantity'];
    final closingStockQuantity = json['closingStockQuantity'];
    final averageStockQuantity = json['averageStockQuantity'];
    final averageDailySalesQuantity = json['averageDailySalesQuantity'];
    final coverageStatus = json['coverageStatus'];
    final generatedAt = json['generatedAt'];

    if (organizationId is! String ||
        scopeType is! String ||
        scopeId is! String ||
        periodStart is! Timestamp ||
        periodEnd is! Timestamp ||
        coveredDays is! int ||
        sellThroughRate is! num ||
        stockCoverageDays is! num ||
        turnoverRate is! num ||
        openingStockQuantity is! int ||
        receivedQuantity is! int ||
        soldQuantity is! int ||
        closingStockQuantity is! int ||
        averageStockQuantity is! num ||
        averageDailySalesQuantity is! num ||
        coverageStatus is! String ||
        generatedAt is! Timestamp) {
      throw const ValidationException(
        'Invalid stock turnover metric payload.',
        code: 'invalid_stock_turnover_metric_payload',
      );
    }

    return StockTurnoverMetricSnapshotDto(
      id: id,
      organizationId: organizationId,
      scopeType: scopeType,
      scopeId: scopeId,
      periodStart: periodStart.toDate(),
      periodEnd: periodEnd.toDate(),
      coveredDays: coveredDays,
      sellThroughRate: sellThroughRate.toDouble(),
      stockCoverageDays: stockCoverageDays.toDouble(),
      turnoverRate: turnoverRate.toDouble(),
      openingStockQuantity: openingStockQuantity,
      receivedQuantity: receivedQuantity,
      soldQuantity: soldQuantity,
      closingStockQuantity: closingStockQuantity,
      averageStockQuantity: averageStockQuantity.toDouble(),
      averageDailySalesQuantity: averageDailySalesQuantity.toDouble(),
      coverageStatus: coverageStatus,
      generatedAt: generatedAt.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String scopeType;
  final String scopeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int coveredDays;
  final double sellThroughRate;
  final double stockCoverageDays;
  final double turnoverRate;
  final int openingStockQuantity;
  final int receivedQuantity;
  final int soldQuantity;
  final int closingStockQuantity;
  final double averageStockQuantity;
  final double averageDailySalesQuantity;
  final String coverageStatus;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'scopeType': scopeType,
      'scopeId': scopeId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'coveredDays': coveredDays,
      'sellThroughRate': sellThroughRate,
      'stockCoverageDays': stockCoverageDays,
      'turnoverRate': turnoverRate,
      'openingStockQuantity': openingStockQuantity,
      'receivedQuantity': receivedQuantity,
      'soldQuantity': soldQuantity,
      'closingStockQuantity': closingStockQuantity,
      'averageStockQuantity': averageStockQuantity,
      'averageDailySalesQuantity': averageDailySalesQuantity,
      'coverageStatus': coverageStatus,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
