import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a Lead scoped by organization.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] is duplicated in the payload so Security Rules
/// and queries can validate tenant scope without trusting a client value.
final class LeadDto {
  const LeadDto({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.name,
    this.document,
    required this.sourceCode,
    required this.sourceLabel,
    required this.responsibleUserId,
    required this.status,
    required this.score,
    this.disqualificationReason,
    this.convertedCustomerId,
    this.convertedOpportunityId,
    required this.createdAt,
    this.contactedAt,
    this.qualifiedAt,
    this.convertedAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
    required this.syncStatus,
  });

  factory LeadDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final name = json['name'];
    final document = json['document'];
    final sourceCode = json['sourceCode'];
    final sourceLabel = json['sourceLabel'];
    final responsibleUserId = json['responsibleUserId'];
    final status = json['status'];
    final score = json['score'];
    final disqualificationReason = json['disqualificationReason'];
    final convertedCustomerId = json['convertedCustomerId'];
    final convertedOpportunityId = json['convertedOpportunityId'];
    final createdAt = json['createdAt'];
    final contactedAt = json['contactedAt'];
    final qualifiedAt = json['qualifiedAt'];
    final convertedAt = json['convertedAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        (companyId != null && companyId is! String) ||
        name is! String ||
        (document != null && document is! String) ||
        sourceCode is! String ||
        sourceLabel is! String ||
        responsibleUserId is! String ||
        status is! String ||
        score is! int ||
        (disqualificationReason != null && disqualificationReason is! String) ||
        (convertedCustomerId != null && convertedCustomerId is! String) ||
        (convertedOpportunityId != null && convertedOpportunityId is! String) ||
        createdAt is! Timestamp ||
        (contactedAt != null && contactedAt is! Timestamp) ||
        (qualifiedAt != null && qualifiedAt is! Timestamp) ||
        (convertedAt != null && convertedAt is! Timestamp) ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid lead payload.',
        code: 'invalid_lead_payload',
      );
    }

    return LeadDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId as String?,
      name: name,
      document: document as String?,
      sourceCode: sourceCode,
      sourceLabel: sourceLabel,
      responsibleUserId: responsibleUserId,
      status: status,
      score: score,
      disqualificationReason: disqualificationReason as String?,
      convertedCustomerId: convertedCustomerId as String?,
      convertedOpportunityId: convertedOpportunityId as String?,
      createdAt: createdAt.toDate(),
      contactedAt: (contactedAt as Timestamp?)?.toDate(),
      qualifiedAt: (qualifiedAt as Timestamp?)?.toDate(),
      convertedAt: (convertedAt as Timestamp?)?.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String? companyId;
  final String name;
  final String? document;
  final String sourceCode;
  final String sourceLabel;
  final String responsibleUserId;
  final String status;
  final int score;
  final String? disqualificationReason;
  final String? convertedCustomerId;
  final String? convertedOpportunityId;
  final DateTime createdAt;
  final DateTime? contactedAt;
  final DateTime? qualifiedAt;
  final DateTime? convertedAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'name': name,
      'document': document,
      'sourceCode': sourceCode,
      'sourceLabel': sourceLabel,
      'responsibleUserId': responsibleUserId,
      'status': status,
      'score': score,
      'disqualificationReason': disqualificationReason,
      'convertedCustomerId': convertedCustomerId,
      'convertedOpportunityId': convertedOpportunityId,
      'createdAt': Timestamp.fromDate(createdAt),
      'contactedAt': contactedAt == null
          ? null
          : Timestamp.fromDate(contactedAt!),
      'qualifiedAt': qualifiedAt == null
          ? null
          : Timestamp.fromDate(qualifiedAt!),
      'convertedAt': convertedAt == null
          ? null
          : Timestamp.fromDate(convertedAt!),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}
