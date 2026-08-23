import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/team_dto.dart';
import 'team_data_source.dart';

/// Firestore-backed [TeamDataSource] for the
/// `organizations/{organizationId}/teams` subcollection (TASK-028).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`.
@LazySingleton(as: TeamDataSource)
final class FirestoreTeamDataSource implements TeamDataSource {
  FirestoreTeamDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<TeamDto>(
        firestore: firestore,
        collectionName: 'teams',
        converter: FirestoreConverter<TeamDto>(
          fromJson: (data, id) => TeamDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<TeamDto> _collection;

  @override
  Future<TeamDto> create(TeamDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<TeamDto>> listByOrganization(String organizationId) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) =>
          query.where('deletedAt', isNull: true).orderBy('name'),
    );
    return page.items;
  }

  @override
  Future<TeamDto?> getById({
    required String organizationId,
    required String id,
  }) {
    return _collection.getById(organizationId: organizationId, id: id);
  }

  @override
  Future<TeamDto> update({
    required String organizationId,
    required String id,
    required String name,
    required String managerUserId,
    required List<String> memberIds,
    String? companyId,
    String? branchId,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'name': name,
        'companyId': companyId,
        'branchId': branchId,
        'managerUserId': managerUserId,
        'memberIds': memberIds,
        'version': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: id,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Team not found after update.',
        code: 'team_not_found_after_update',
      );
    }
    return updated;
  }

  @override
  Future<TeamDto> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'memberIds': FieldValue.arrayUnion(<String>[userId]),
        'version': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: id,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Team not found after adding member.',
        code: 'team_not_found_after_add_member',
      );
    }
    return updated;
  }

  @override
  Future<TeamDto> removeMember({
    required String organizationId,
    required String id,
    required String userId,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'memberIds': FieldValue.arrayRemove(<String>[userId]),
        'version': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: id,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Team not found after removing member.',
        code: 'team_not_found_after_remove_member',
      );
    }
    return updated;
  }

  @override
  Future<bool> hasCommercialLinks({
    required String organizationId,
    required String id,
  }) async {
    try {
      return await _hasLinkInCollection(
            organizationId: organizationId,
            collectionName: 'customers',
            id: id,
          ) ||
          await _hasLinkInCollection(
            organizationId: organizationId,
            collectionName: 'orders',
            id: id,
          );
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<TeamDto> softDelete({
    required String organizationId,
    required String id,
    required DateTime deletedAt,
    required String deletedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'deletedAt': Timestamp.fromDate(deletedAt),
        'version': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(deletedAt),
        'updatedBy': deletedBy,
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: id,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Team not found after delete.',
        code: 'team_not_found_after_delete',
      );
    }
    return updated;
  }

  Future<bool> _hasLinkInCollection({
    required String organizationId,
    required String collectionName,
    required String id,
  }) async {
    final collection = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection(collectionName);

    final direct = await collection
        .where('teamId', isEqualTo: id)
        .limit(1)
        .get();
    if (direct.docs.isNotEmpty) {
      return true;
    }

    final multiple = await collection
        .where('teamIds', arrayContains: id)
        .limit(1)
        .get();
    return multiple.docs.isNotEmpty;
  }
}
