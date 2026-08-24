import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class OpportunityOutcomeReasonDto {
  const OpportunityOutcomeReasonDto({
    required this.id,
    required this.organizationId,
    required this.type,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  factory OpportunityOutcomeReasonDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final type = json['type'];
    final description = json['description'];
    final isActive = json['isActive'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];

    if (organizationId is! String ||
        type is! String ||
        description is! String ||
        isActive is! bool ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid opportunity outcome reason payload.',
        code: 'invalid_opportunity_outcome_reason_payload',
      );
    }

    return OpportunityOutcomeReasonDto(
      id: id,
      organizationId: organizationId,
      type: type,
      description: description,
      isActive: isActive,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String type;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'type': type,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }
}
