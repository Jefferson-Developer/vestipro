import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/membership_dto.dart';
import 'membership_data_source.dart';

/// Firestore-backed [MembershipDataSource] for the
/// `organizations/{organizationId}/members` subcollection (TASK-028), keyed
/// by `userId` so there is at most one document per (organizationId,
/// userId) pair.
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`.
@LazySingleton(as: MembershipDataSource)
final class FirestoreMembershipDataSource implements MembershipDataSource {
  FirestoreMembershipDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<MembershipDto>(
        firestore: firestore,
        collectionName: 'members',
        converter: FirestoreConverter<MembershipDto>(
          fromJson: (data, id) => MembershipDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  /// Kept alongside [_collection] only for [listActiveByUser]: a
  /// collection-group query spans every `organizations/*/members`
  /// subcollection at once, which [FirestoreCollectionDataSource] — scoped
  /// to a single `organizationId` by design — cannot express.
  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<MembershipDto> _collection;

  @override
  Future<MembershipDto> create(MembershipDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<MembershipDto>> listByOrganization(String organizationId) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) => query.where('deletedAt', isNull: true),
    );
    return page.items;
  }

  @override
  Future<MembershipDto?> getByUser({
    required String organizationId,
    required String userId,
  }) {
    return _collection.getById(organizationId: organizationId, id: userId);
  }

  @override
  Future<MembershipDto> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: userId,
      data: <String, Object?>{
        'roleId': roleId,
        'roleName': roleName,
        'teamIds': teamIds,
        'status': status,
        'version': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: userId,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Membership not found after update.',
        code: 'membership_not_found_after_update',
      );
    }
    return updated;
  }

  @override
  Future<List<MembershipDto>> listActiveByUser(String userId) async {
    debugPrint('[DEBUG-MEMBERSHIP] listActiveByUser(userId=$userId) start');
    try {
      // A raw `collectionGroup` query (not `_collection`, which is always
      // rooted at one `organizations/{organizationId}`): this is the one
      // read that needs to span every Organization's `members`
      // subcollection at once, filtered to the caller's own `userId` —
      // `firestore.rules` only grants `list` on `members` when that exact
      // filter is present, see this class's own doc and `firestore.rules`.
      final snapshot = await _firestore
          .collectionGroup('members')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint(
        '[DEBUG-MEMBERSHIP] listActiveByUser query OK, '
        'docs=${snapshot.docs.length} '
        'paths=${snapshot.docs.map((d) => d.reference.path).toList()}',
      );

      return snapshot.docs
          .map((doc) => MembershipDto.fromJson(doc.data(), id: doc.id))
          .where((dto) => dto.deletedAt == null && dto.status == 'active')
          .toList(growable: false);
    } on FirebaseException catch (exception, stackTrace) {
      debugPrint(
        '[DEBUG-MEMBERSHIP] listActiveByUser FirebaseException '
        'code=${exception.code} message=${exception.message}',
      );
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }
}
