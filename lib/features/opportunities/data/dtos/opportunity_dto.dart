import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for an Opportunity scoped by organization.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] is duplicated in the payload so Security Rules
/// and queries can validate tenant scope without trusting a client value.
final class OpportunityDto {
  const OpportunityDto({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.title,
    this.description,
    this.customerId,
    this.leadId,
    required this.estimatedValue,
    required this.probability,
    required this.revenueForecast,
    required this.responsibleUserId,
    required this.stageId,
    required this.status,
    required this.expectedCloseDate,
    this.wonReasonId,
    this.wonReason,
    this.wonReasonNote,
    this.lostReasonId,
    this.lostReason,
    this.lostReasonNote,
    this.closedAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
    required this.syncStatus,
  });

  factory OpportunityDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final title = json['title'];
    final description = json['description'];
    final customerId = json['customerId'];
    final leadId = json['leadId'];
    final estimatedValue = json['estimatedValue'];
    final probability = json['probability'];
    final revenueForecast = json['revenueForecast'];
    final responsibleUserId = json['responsibleUserId'];
    final stageId = json['stageId'];
    final status = json['status'];
    final expectedCloseDate = json['expectedCloseDate'];
    final wonReasonId = json['wonReasonId'];
    final wonReason = json['wonReason'];
    final wonReasonNote = json['wonReasonNote'];
    final lostReasonId = json['lostReasonId'];
    final lostReason = json['lostReason'];
    final lostReasonNote = json['lostReasonNote'];
    final closedAt = json['closedAt'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        (companyId != null && companyId is! String) ||
        title is! String ||
        (description != null && description is! String) ||
        (customerId != null && customerId is! String) ||
        (leadId != null && leadId is! String) ||
        (estimatedValue is! num) ||
        probability is! int ||
        (revenueForecast is! num) ||
        responsibleUserId is! String ||
        stageId is! String ||
        status is! String ||
        expectedCloseDate is! Timestamp ||
        (wonReasonId != null && wonReasonId is! String) ||
        (wonReason != null && wonReason is! String) ||
        (wonReasonNote != null && wonReasonNote is! String) ||
        (lostReasonId != null && lostReasonId is! String) ||
        (lostReason != null && lostReason is! String) ||
        (lostReasonNote != null && lostReasonNote is! String) ||
        (closedAt != null && closedAt is! Timestamp) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid opportunity payload.',
        code: 'invalid_opportunity_payload',
      );
    }

    return OpportunityDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId as String?,
      title: title,
      description: description as String?,
      customerId: customerId as String?,
      leadId: leadId as String?,
      estimatedValue: estimatedValue.toDouble(),
      probability: probability,
      revenueForecast: revenueForecast.toDouble(),
      responsibleUserId: responsibleUserId,
      stageId: stageId,
      status: status,
      expectedCloseDate: expectedCloseDate.toDate(),
      wonReasonId: wonReasonId as String?,
      wonReason: wonReason as String?,
      wonReasonNote: wonReasonNote as String?,
      lostReasonId: lostReasonId as String?,
      lostReason: lostReason as String?,
      lostReasonNote: lostReasonNote as String?,
      closedAt: (closedAt as Timestamp?)?.toDate(),
      createdAt: createdAt.toDate(),
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
  final String title;
  final String? description;
  final String? customerId;
  final String? leadId;
  final double estimatedValue;
  final int probability;
  final double revenueForecast;
  final String responsibleUserId;
  final String stageId;
  final String status;
  final DateTime expectedCloseDate;
  final String? wonReasonId;
  final String? wonReason;
  final String? wonReasonNote;
  final String? lostReasonId;
  final String? lostReason;
  final String? lostReasonNote;
  final DateTime? closedAt;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'title': title,
      'description': description,
      'customerId': customerId,
      'leadId': leadId,
      'estimatedValue': estimatedValue,
      'probability': probability,
      'revenueForecast': revenueForecast,
      'responsibleUserId': responsibleUserId,
      'stageId': stageId,
      'status': status,
      'expectedCloseDate': Timestamp.fromDate(expectedCloseDate),
      'wonReasonId': wonReasonId,
      'wonReason': wonReason,
      'wonReasonNote': wonReasonNote,
      'lostReasonId': lostReasonId,
      'lostReason': lostReason,
      'lostReasonNote': lostReasonNote,
      'closedAt': closedAt == null ? null : Timestamp.fromDate(closedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}
