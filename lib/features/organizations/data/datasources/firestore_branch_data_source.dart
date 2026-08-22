import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/branch_address_dto.dart';
import '../dtos/branch_dto.dart';
import 'branch_data_source.dart';

/// Firestore-backed [BranchDataSource] for the
/// `organizations/{organizationId}/branches` subcollection (TASK-027).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`. `companyId` scoping for [listByCompany] is a query filter, not
/// a separate subcollection, per TASK-027's `organizations/{organizationId}/
/// branches/{id}` layout.
@LazySingleton(as: BranchDataSource)
final class FirestoreBranchDataSource implements BranchDataSource {
  FirestoreBranchDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<BranchDto>(
        firestore: firestore,
        collectionName: 'branches',
        converter: FirestoreConverter<BranchDto>(
          fromJson: (data, id) => BranchDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<BranchDto> _collection;

  @override
  Future<BranchDto> create(BranchDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<BranchDto>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('deletedAt', isNull: true)
          .orderBy('name'),
    );
    return page.items;
  }

  @override
  Future<BranchDto?> getById({
    required String organizationId,
    required String id,
  }) {
    return _collection.getById(organizationId: organizationId, id: id);
  }

  @override
  Future<BranchDto> update({
    required String organizationId,
    required String id,
    required String name,
    required String type,
    BranchAddressDto? address,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'name': name,
        'type': type,
        'address': address?.toJson(),
        'status': status,
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
        'Branch not found after update.',
        code: 'branch_not_found_after_update',
      );
    }
    return updated;
  }
}
