import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/audit_log_entry_dto.dart';
import '../dtos/audit_log_entry_page_dto.dart';
import 'audit_log_data_source.dart';

/// Firestore-backed [AuditLogDataSource] for the
/// `organizations/{organizationId}/auditLogs` subcollection (TASK-033).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`. Only ever calls [FirestoreCollectionDataSource.set] (never
/// `update`/`softDelete`) — Firestore Security Rules independently deny
/// `update`/`delete` on this collection for every role, including `OWNER`.
@LazySingleton(as: AuditLogDataSource)
final class FirestoreAuditLogDataSource implements AuditLogDataSource {
  FirestoreAuditLogDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<AuditLogEntryDto>(
        firestore: firestore,
        collectionName: 'auditLogs',
        converter: FirestoreConverter<AuditLogEntryDto>(
          fromJson: (data, id) => AuditLogEntryDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<AuditLogEntryDto> _collection;

  @override
  Future<AuditLogEntryDto> record(AuditLogEntryDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<AuditLogEntryPageDto> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<String> actionCodes = const <String>{},
    String? actorUserId,
  }) async {
    final trimmedActorUserId = actorUserId?.trim();
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query.orderBy('timestamp', descending: true);
        if (actionCodes.length == 1) {
          scoped = scoped.where('action', isEqualTo: actionCodes.first);
        } else if (actionCodes.length > 1) {
          scoped = scoped.where('action', whereIn: actionCodes.toList());
        }
        if (trimmedActorUserId != null && trimmedActorUserId.isNotEmpty) {
          scoped = scoped.where('actorUserId', isEqualTo: trimmedActorUserId);
        }
        if (before != null) {
          scoped = scoped.where(
            'timestamp',
            isLessThan: Timestamp.fromDate(before),
          );
        }
        if (from != null) {
          scoped = scoped.where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          );
        }
        if (to != null) {
          scoped = scoped.where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(to),
          );
        }
        return scoped;
      },
    );
    return AuditLogEntryPageDto(items: page.items, hasMore: page.hasMore);
  }
}
