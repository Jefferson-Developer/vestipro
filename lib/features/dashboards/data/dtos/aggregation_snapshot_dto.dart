import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/value_objects/aggregation_dimension.dart';

/// Wire shape of one document under
/// `organizations/{organizationId}/{salesDailyAggregates,
/// customerMonthlyAggregates, productMonthlyAggregates,
/// sellerMonthlyAggregates, regionMonthlyAggregates}/{docId}` — must match
/// `AggregateSnapshotDoc` in
/// `functions/src/aggregations/aggregation-shared.ts` field for field
/// (never written by the client — see `firestore.rules`, `allow create,
/// update, delete: if false` on every one of these five collections).
final class AggregationSnapshotDto {
  const AggregationSnapshotDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.dimension,
    required this.scopeId,
    required this.periodKey,
    required this.revenueGross,
    required this.revenueNet,
    required this.discountAmount,
    required this.orderCount,
    required this.itemQuantity,
    required this.labels,
    required this.generatedAt,
    required this.version,
  });

  factory AggregationSnapshotDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required AggregationDimension dimension,
  }) {
    String requireString(String field) {
      final value = json[field];
      if (value is String && value.trim().isNotEmpty) return value;
      throw ValidationException(
        'Invalid aggregation snapshot payload ($field).',
        code: 'invalid_aggregation_snapshot_payload',
      );
    }

    double numberOrZero(String field) {
      final value = json[field];
      return value is num ? value.toDouble() : 0;
    }

    int intOrZero(String field) {
      final value = json[field];
      return value is num ? value.toInt() : 0;
    }

    final generatedAtValue = json['generatedAt'];
    final generatedAt = generatedAtValue is Timestamp
        ? generatedAtValue.toDate()
        : throw ValidationException(
            'Invalid aggregation snapshot payload (generatedAt).',
            code: 'invalid_aggregation_snapshot_payload',
          );

    final rawLabels = json['labels'];
    final labels = <String, String>{
      if (rawLabels is Map)
        for (final entry in rawLabels.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
    };

    return AggregationSnapshotDto(
      id: id,
      organizationId: requireString('organizationId'),
      companyId: requireString('companyId'),
      dimension: dimension,
      scopeId: requireString('scopeId'),
      periodKey: requireString('periodKey'),
      revenueGross: numberOrZero('revenueGross'),
      revenueNet: numberOrZero('revenueNet'),
      discountAmount: numberOrZero('discountAmount'),
      orderCount: intOrZero('orderCount'),
      itemQuantity: intOrZero('itemQuantity'),
      labels: labels,
      generatedAt: generatedAt,
      version: intOrZero('version'),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final AggregationDimension dimension;
  final String scopeId;
  final String periodKey;
  final double revenueGross;
  final double revenueNet;
  final double discountAmount;
  final int orderCount;
  final int itemQuantity;
  final Map<String, String> labels;
  final DateTime generatedAt;
  final int version;
}
