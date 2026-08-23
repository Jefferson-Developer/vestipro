import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/members/{userId}` (TASK-028). [id] is
/// always equal to [userId] and is never one of the map's keys in [toJson]
/// — Firestore already keys the document by it — so it must always be
/// supplied out-of-band (the document snapshot's own id) when building one
/// from [fromJson]. [organizationId]/[userId] *are* stored as fields
/// (redundant with the document's path) so Firestore Security Rules
/// (TASK-030) can validate them without reading the path.
final class MembershipDto {
  const MembershipDto({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.roleId,
    required this.roleName,
    this.teamIds = const <String>[],
    required this.status,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    this.name,
    this.email,
  });

  factory MembershipDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final roleId = json['roleId'];
    final roleName = json['roleName'];
    final teamIds = json['teamIds'];
    final status = json['status'];
    final version = json['version'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final name = json['name'];
    final email = json['email'];

    if (organizationId is! String ||
        userId is! String ||
        roleId is! String ||
        roleName is! String ||
        (teamIds != null && teamIds is! List) ||
        status is! String ||
        version is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        (name != null && name is! String) ||
        (email != null && email is! String)) {
      throw const ValidationException(
        'Invalid membership payload.',
        code: 'invalid_membership_payload',
      );
    }

    return MembershipDto(
      id: id,
      organizationId: organizationId,
      userId: userId,
      roleId: roleId,
      roleName: roleName,
      teamIds: teamIds == null
          ? const <String>[]
          : List<String>.from(teamIds as List),
      status: status,
      version: version,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      name: name as String?,
      email: email as String?,
    );
  }

  final String id;
  final String organizationId;
  final String userId;
  final String roleId;
  final String roleName;
  final List<String> teamIds;
  final String status;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;

  /// Denormalized display fields (TASK-042) — see [Membership.name]/
  /// [Membership.email]'s own docs for why these are optional and never
  /// written by any client-side update.
  final String? name;
  final String? email;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'roleId': roleId,
      'roleName': roleName,
      'teamIds': teamIds,
      'status': status,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'name': name,
      'email': email,
    };
  }
}
