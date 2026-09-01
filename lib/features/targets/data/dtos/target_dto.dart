import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a Target ("meta comercial"), scoped by
/// organization at `organizations/{organizationId}/targets/{targetId}`
/// (`docs/architecture/firestore-schema.md`).
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] is duplicated in the payload so Security Rules
/// and queries can validate tenant scope without trusting a client value,
/// mirroring `OpportunityDto`.
final class TargetDto {
  const TargetDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.dimensionType,
    required this.dimensionId,
    required this.periodGranularity,
    required this.startDate,
    required this.endDate,
    required this.metricType,
    required this.targetValue,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  factory TargetDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final dimensionType = json['dimensionType'];
    final dimensionId = json['dimensionId'];
    final periodGranularity = json['periodGranularity'];
    final startDate = json['startDate'];
    final endDate = json['endDate'];
    final metricType = json['metricType'];
    final targetValue = json['targetValue'];
    final currency = json['currency'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        companyId is! String ||
        dimensionType is! String ||
        dimensionId is! String ||
        periodGranularity is! String ||
        startDate is! Timestamp ||
        endDate is! Timestamp ||
        metricType is! String ||
        targetValue is! num ||
        currency is! String ||
        status is! String ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid target payload.',
        code: 'invalid_target_payload',
      );
    }

    return TargetDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodGranularity: periodGranularity,
      startDate: startDate.toDate(),
      endDate: endDate.toDate(),
      metricType: metricType,
      targetValue: targetValue.toDouble(),
      currency: currency,
      status: status,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String dimensionType;
  final String dimensionId;
  final String periodGranularity;
  final DateTime startDate;
  final DateTime endDate;
  final String metricType;
  final double targetValue;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'dimensionType': dimensionType,
      'dimensionId': dimensionId,
      'periodGranularity': periodGranularity,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'metricType': metricType,
      'targetValue': targetValue,
      'currency': currency,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}
