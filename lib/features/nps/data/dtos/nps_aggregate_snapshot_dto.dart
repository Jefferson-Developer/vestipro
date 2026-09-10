import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Wire shape of one document under
/// `organizations/{organizationId}/npsMonthlyAggregates/{docId}` — must
/// match the payload `recomputeNpsMonthlyAggregates`
/// (`functions/src/nps/recompute-nps-monthly-aggregates.ts`) writes, field
/// for field (never written by the client — `firestore.rules`, `allow
/// create, update, delete: if false`).
final class NpsAggregateSnapshotDto {
  const NpsAggregateSnapshotDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.scope,
    required this.scopeId,
    required this.periodKey,
    required this.promoters,
    required this.passives,
    required this.detractors,
    required this.totalResponses,
    required this.npsScore,
    required this.generatedAt,
    required this.version,
  });

  factory NpsAggregateSnapshotDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    String requireString(String field) {
      final value = json[field];
      if (value is String && value.trim().isNotEmpty) return value;
      throw ValidationException(
        'Invalid NPS aggregate snapshot payload ($field).',
        code: 'invalid_nps_aggregate_snapshot_payload',
      );
    }

    int intOrZero(String field) {
      final value = json[field];
      return value is num ? value.toInt() : 0;
    }

    final generatedAtValue = json['generatedAt'];
    final generatedAt = generatedAtValue is Timestamp
        ? generatedAtValue.toDate()
        : throw ValidationException(
            'Invalid NPS aggregate snapshot payload (generatedAt).',
            code: 'invalid_nps_aggregate_snapshot_payload',
          );

    final npsScoreValue = json['npsScore'];

    return NpsAggregateSnapshotDto(
      id: id,
      organizationId: requireString('organizationId'),
      companyId: requireString('companyId'),
      scope: requireString('scope'),
      scopeId: requireString('scopeId'),
      periodKey: requireString('periodKey'),
      promoters: intOrZero('promoters'),
      passives: intOrZero('passives'),
      detractors: intOrZero('detractors'),
      totalResponses: intOrZero('totalResponses'),
      npsScore: npsScoreValue is num ? npsScoreValue.toDouble() : null,
      generatedAt: generatedAt,
      version: intOrZero('version'),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String scope;
  final String scopeId;
  final String periodKey;
  final int promoters;
  final int passives;
  final int detractors;
  final int totalResponses;
  final double? npsScore;
  final DateTime generatedAt;
  final int version;
}
