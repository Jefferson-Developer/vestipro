import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class PortfolioAssignmentDto {
  const PortfolioAssignmentDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.teamId,
    required this.scopeType,
    this.customerId,
    this.region,
    this.segment,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.endedAt,
    this.endedBy,
    this.deletedAt,
  });

  factory PortfolioAssignmentDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final userId = json['userId'];
    final teamId = json['teamId'];
    final scopeType = json['scopeType'];
    final customerId = json['customerId'];
    final region = json['region'];
    final segment = json['segment'];
    final status = json['status'];
    final version = json['version'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final endedAt = json['endedAt'];
    final endedBy = json['endedBy'];
    final deletedAt = json['deletedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        userId is! String ||
        teamId is! String ||
        scopeType is! String ||
        (customerId != null && customerId is! String) ||
        (region != null && region is! String) ||
        (segment != null && segment is! String) ||
        status is! String ||
        version is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (endedAt != null && endedAt is! Timestamp) ||
        (endedBy != null && endedBy is! String) ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid portfolio assignment payload.',
        code: 'invalid_portfolio_assignment_payload',
      );
    }

    return PortfolioAssignmentDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      teamId: teamId,
      scopeType: scopeType,
      customerId: customerId as String?,
      region: region as String?,
      segment: segment as String?,
      status: status,
      version: version,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      endedAt: (endedAt as Timestamp?)?.toDate(),
      endedBy: endedBy as String?,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String userId;
  final String teamId;
  final String scopeType;
  final String? customerId;
  final String? region;
  final String? segment;
  final String status;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? endedAt;
  final String? endedBy;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'userId': userId,
      'teamId': teamId,
      'scopeType': scopeType,
      'customerId': customerId,
      'region': region,
      'segment': segment,
      'status': status,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
      'endedBy': endedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
