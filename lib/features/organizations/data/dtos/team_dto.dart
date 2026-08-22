import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for `organizations/{organizationId}/teams/{id}`
/// (TASK-028). [id] is never one of the map's keys in [toJson] — Firestore
/// already keys the document by it — so it must always be supplied
/// out-of-band (the document snapshot's own id) when building one from
/// [fromJson]. [organizationId] *is* stored as a field (redundant with the
/// document's path) so Firestore Security Rules (TASK-030) can validate it
/// without reading the path.
final class TeamDto {
  const TeamDto({
    required this.id,
    required this.organizationId,
    required this.name,
    this.memberIds = const <String>[],
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });

  factory TeamDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final name = json['name'];
    final memberIds = json['memberIds'];
    final version = json['version'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];

    if (organizationId is! String ||
        name is! String ||
        (memberIds != null && memberIds is! List) ||
        version is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid team payload.',
        code: 'invalid_team_payload',
      );
    }

    return TeamDto(
      id: id,
      organizationId: organizationId,
      name: name,
      memberIds: memberIds == null
          ? const <String>[]
          : List<String>.from(memberIds as List),
      version: version,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final List<String> memberIds;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'name': name,
      'memberIds': memberIds,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
