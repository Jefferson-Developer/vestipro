import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/auditLogs/{id}` (TASK-033). [id] is
/// never one of the map's keys in [toJson] — Firestore already keys the
/// document by it — so it must always be supplied out-of-band (the
/// document snapshot's own id) when building one from [fromJson].
/// [organizationId] *is* stored as a field (redundant with the document's
/// path) so Firestore Security Rules can validate it without reading the
/// path, exactly like every other tenant-scoped DTO in this codebase.
///
/// [previousValue]/[newValue] are stored as-is (already sanitized by
/// `RecordAuditLogUseCase` before this DTO exists) — this DTO never decides
/// what is or is not sensitive, it only (de)serializes.
final class AuditLogEntryDto {
  const AuditLogEntryDto({
    required this.id,
    required this.organizationId,
    required this.actorUserId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.previousValue,
    this.newValue,
    required this.timestamp,
  });

  factory AuditLogEntryDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final actorUserId = json['actorUserId'];
    final actorName = json['actorName'];
    final action = json['action'];
    final entityType = json['entityType'];
    final entityId = json['entityId'];
    final previousValue = json['previousValue'];
    final newValue = json['newValue'];
    final timestamp = json['timestamp'];

    if (organizationId is! String ||
        actorUserId is! String ||
        actorName is! String ||
        action is! String ||
        entityType is! String ||
        entityId is! String ||
        (previousValue != null && previousValue is! Map) ||
        (newValue != null && newValue is! Map) ||
        timestamp is! Timestamp) {
      throw const ValidationException(
        'Invalid audit log entry payload.',
        code: 'invalid_audit_log_entry_payload',
      );
    }

    return AuditLogEntryDto(
      id: id,
      organizationId: organizationId,
      actorUserId: actorUserId,
      actorName: actorName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      previousValue: previousValue == null
          ? null
          : Map<String, dynamic>.from(previousValue as Map),
      newValue: newValue == null
          ? null
          : Map<String, dynamic>.from(newValue as Map),
      timestamp: timestamp.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String actorUserId;
  final String actorName;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'actorUserId': actorUserId,
      'actorName': actorName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'previousValue': previousValue,
      'newValue': newValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
