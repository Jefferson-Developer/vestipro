import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/role_dto.dart';
import 'role_data_source.dart';

/// Firestore-backed [RoleDataSource] for the
/// `organizations/{organizationId}/roles` subcollection (TASK-028).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`.
@LazySingleton(as: RoleDataSource)
final class FirestoreRoleDataSource implements RoleDataSource {
  FirestoreRoleDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<RoleDto>(
        firestore: firestore,
        collectionName: 'roles',
        converter: FirestoreConverter<RoleDto>(
          fromJson: (data, id) => RoleDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<RoleDto> _collection;

  @override
  Future<RoleDto> create(RoleDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<RoleDto>> listByOrganization(String organizationId) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) =>
          query.where('deletedAt', isNull: true).orderBy('name'),
    );
    return page.items;
  }

  @override
  Future<RoleDto?> getById({
    required String organizationId,
    required String id,
  }) {
    return _collection.getById(organizationId: organizationId, id: id);
  }
}
