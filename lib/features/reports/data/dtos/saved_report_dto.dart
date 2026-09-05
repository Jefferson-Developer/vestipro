import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/saved_report.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/savedReports/{id}` (TASK-145).
///
/// [id] comes from the document id and is never serialized inside [toJson].
/// [organizationId]/[companyId]/[ownerId] stay duplicated in the payload so
/// `firestore.rules` and queries never have to trust a client value out of
/// band from the document itself.
final class SavedReportDto {
  const SavedReportDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.ownerId,
    required this.name,
    required this.definition,
    required this.visibility,
    this.sharedWithTeamIds = const <String>[],
    required this.favorite,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  factory SavedReportDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final ownerId = json['ownerId'];
    final name = json['name'];
    final definition = json['definition'];
    final visibility = json['visibility'];
    final favorite = json['favorite'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        ownerId is! String ||
        name is! String ||
        definition is! Map ||
        visibility is! String ||
        favorite is! bool ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        version is! int) {
      throw const ValidationException(
        'Invalid saved report payload.',
        code: 'invalid_saved_report_payload',
      );
    }

    return SavedReportDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      ownerId: ownerId,
      name: name,
      definition: ReportDefinition.fromJson(
        Map<String, dynamic>.from(definition),
      ),
      visibility: SavedReportVisibilityCode.fromCode(visibility),
      sharedWithTeamIds: _stringListFromJson(json['sharedWithTeamIds']),
      favorite: favorite,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      version: version,
    );
  }

  factory SavedReportDto.fromEntity(SavedReport entity) => SavedReportDto(
    id: entity.id,
    organizationId: entity.organizationId,
    companyId: entity.companyId,
    ownerId: entity.ownerId,
    name: entity.name,
    definition: entity.definition,
    visibility: entity.visibility,
    sharedWithTeamIds: entity.sharedWithTeamIds,
    favorite: entity.favorite,
    createdAt: entity.createdAt,
    createdBy: entity.createdBy,
    updatedAt: entity.updatedAt,
    updatedBy: entity.updatedBy,
    version: entity.version,
  );

  final String id;
  final String organizationId;
  final String companyId;
  final String ownerId;
  final String name;
  final ReportDefinition definition;
  final SavedReportVisibility visibility;
  final List<String> sharedWithTeamIds;
  final bool favorite;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  SavedReport toEntity() => SavedReport(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    ownerId: ownerId,
    name: name,
    definition: definition,
    visibility: visibility,
    sharedWithTeamIds: sharedWithTeamIds,
    favorite: favorite,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
    version: version,
  );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'ownerId': ownerId,
      'name': name,
      'definition': definition.toJson(),
      'visibility': visibility.code,
      'sharedWithTeamIds': sharedWithTeamIds,
      'favorite': favorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid saved report team list.',
      code: 'invalid_saved_report_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}
