import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for the root `users/{uid}` collection
/// (TASK-035). [uid] is never one of the map's keys in [toJson] — Firestore
/// already keys the document by it, same convention as [OrganizationDto]
/// (`organizations/{id}`) — so it must always be supplied out-of-band (the
/// document snapshot's own id) when building one from [fromJson].
final class UserProfileDto {
  const UserProfileDto({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.termsVersion,
    required this.termsAcceptedAt,
  });

  factory UserProfileDto.fromJson(
    Map<String, dynamic> json, {
    required String uid,
  }) {
    final name = json['name'];
    final email = json['email'];
    final createdAt = json['createdAt'];
    final termsVersion = json['termsVersion'];
    final termsAcceptedAt = json['termsAcceptedAt'];

    if (name is! String ||
        email is! String ||
        createdAt is! Timestamp ||
        termsVersion is! String ||
        termsAcceptedAt is! Timestamp) {
      throw const ValidationException(
        'Invalid user profile payload.',
        code: 'invalid_user_profile_payload',
      );
    }

    return UserProfileDto(
      uid: uid,
      name: name,
      email: email,
      createdAt: createdAt.toDate(),
      termsVersion: termsVersion,
      termsAcceptedAt: termsAcceptedAt.toDate(),
    );
  }

  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String termsVersion;
  final DateTime termsAcceptedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'termsVersion': termsVersion,
      'termsAcceptedAt': Timestamp.fromDate(termsAcceptedAt),
    };
  }
}
