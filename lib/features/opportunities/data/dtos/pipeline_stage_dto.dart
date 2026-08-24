import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a [PipelineStage] scoped by organization
/// (TASK-058). [id] is supplied from the document id and is never
/// serialized inside [toJson]; [organizationId] is duplicated in the
/// payload so Security Rules/queries never need to trust a client value.
final class PipelineStageDto {
  const PipelineStageDto({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.order,
    required this.colorHex,
    required this.terminalType,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  factory PipelineStageDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final name = json['name'];
    final order = json['order'];
    final colorHex = json['colorHex'];
    final terminalType = json['terminalType'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];

    if (organizationId is! String ||
        name is! String ||
        order is! int ||
        colorHex is! String ||
        terminalType is! String ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid pipeline stage payload.',
        code: 'invalid_pipeline_stage_payload',
      );
    }

    return PipelineStageDto(
      id: id,
      organizationId: organizationId,
      name: name,
      order: order,
      colorHex: colorHex,
      terminalType: terminalType,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final int order;
  final String colorHex;
  final String terminalType;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'name': name,
      'order': order,
      'colorHex': colorHex,
      'terminalType': terminalType,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }
}
