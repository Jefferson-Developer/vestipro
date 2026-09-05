import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/pushDevices/{id}` (TASK-150). [id] is
/// never one of the map's keys in [toJson] — Firestore already keys the
/// document by it — so it must always be supplied out-of-band (the document
/// snapshot's own id), same convention as `AuditLogEntryDto`.
/// [organizationId] *is* stored as a field (redundant with the document's
/// path) so Firestore Security Rules can validate it without reading the
/// path, exactly like every other tenant-scoped DTO in this codebase.
final class PushDeviceDto {
  const PushDeviceDto({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.token,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.lastUsedAt,
    this.deletedAt,
  });

  factory PushDeviceDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final token = json['token'];
    final platform = json['platform'];
    final appVersion = json['appVersion'];
    final createdAt = json['createdAt'];
    final lastUsedAt = json['lastUsedAt'];
    final deletedAt = json['deletedAt'];

    if (organizationId is! String ||
        userId is! String ||
        token is! String ||
        platform is! String ||
        appVersion is! String ||
        createdAt is! Timestamp ||
        lastUsedAt is! Timestamp ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid push device payload.',
        code: 'invalid_push_device_payload',
      );
    }

    return PushDeviceDto(
      id: id,
      organizationId: organizationId,
      userId: userId,
      token: token,
      platform: platform,
      appVersion: appVersion,
      createdAt: createdAt.toDate(),
      lastUsedAt: lastUsedAt.toDate(),
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String userId;
  final String token;
  final String platform;
  final String appVersion;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'token': token,
      'platform': platform,
      'appVersion': appVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
