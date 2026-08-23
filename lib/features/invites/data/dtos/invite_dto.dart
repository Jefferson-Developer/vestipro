import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/invites/{id}` (TASK-039). [id] is never
/// one of the map's keys in [toJson] — Firestore already keys the document
/// by it — so it must always be supplied out-of-band (the document
/// snapshot's own id) when building one from [fromJson].
///
/// Deliberately does not model `tokenHash`: nothing in `data/`/`domain/`
/// ever needs to read it back — `Invite` (the domain entity) has no such
/// field at all, and the plaintext token is only ever available once, as
/// [IssuedInvite.token], right when `createInvite`/`resendInvite` succeeds.
final class InviteDto {
  const InviteDto({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.roleName,
    required this.status,
    required this.invitedByUserId,
    required this.invitedByName,
    this.message,
    required this.expiresAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Builds an [InviteDto] from a Firestore document's raw data (dates as
  /// [Timestamp], the shape a `cloud_firestore` read produces) — used by
  /// [FirestoreInviteDataSource.listPending]. Never used for a callable
  /// Cloud Function response (plain JSON, dates as ISO-8601 strings): see
  /// `FirestoreInviteDataSource`'s own private parsing method for that
  /// shape instead.
  factory InviteDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final email = json['email'];
    final roleName = json['roleName'];
    final status = json['status'];
    final invitedByUserId = json['invitedByUserId'];
    final invitedByName = json['invitedByName'];
    final message = json['message'];
    final expiresAt = json['expiresAt'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];

    if (organizationId is! String ||
        email is! String ||
        roleName is! String ||
        status is! String ||
        invitedByUserId is! String ||
        invitedByName is! String ||
        (message != null && message is! String) ||
        expiresAt is! Timestamp ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String) {
      throw const ValidationException(
        'Invalid invite payload.',
        code: 'invalid_invite_payload',
      );
    }

    return InviteDto(
      id: id,
      organizationId: organizationId,
      email: email,
      roleName: roleName,
      status: status,
      invitedByUserId: invitedByUserId,
      invitedByName: invitedByName,
      message: message as String?,
      expiresAt: expiresAt.toDate(),
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
    );
  }

  final String id;
  final String organizationId;
  final String email;
  final String roleName;
  final String status;
  final String invitedByUserId;
  final String invitedByName;
  final String? message;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'email': email,
      'roleName': roleName,
      'status': status,
      'invitedByUserId': invitedByUserId,
      'invitedByName': invitedByName,
      'message': message,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}
