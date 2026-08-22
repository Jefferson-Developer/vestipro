import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/company_dto.dart';
import 'company_data_source.dart';

/// Firestore-backed [CompanyDataSource] for the
/// `organizations/{organizationId}/companies` subcollection (TASK-027).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, so every read/write is scoped by
/// `organizationId` by construction and no raw Firestore map ever reaches
/// `domain/`.
@LazySingleton(as: CompanyDataSource)
final class FirestoreCompanyDataSource implements CompanyDataSource {
  FirestoreCompanyDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<CompanyDto>(
        firestore: firestore,
        collectionName: 'companies',
        converter: FirestoreConverter<CompanyDto>(
          fromJson: (data, id) => CompanyDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<CompanyDto> _collection;

  @override
  Future<CompanyDto> create(CompanyDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<CompanyDto>> listByOrganization(String organizationId) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) =>
          query.where('deletedAt', isNull: true).orderBy('name'),
    );
    return page.items;
  }

  @override
  Future<CompanyDto?> getById({
    required String organizationId,
    required String id,
  }) {
    return _collection.getById(organizationId: organizationId, id: id);
  }

  @override
  Future<CompanyDto> update({
    required String organizationId,
    required String id,
    required String name,
    String? legalName,
    String? taxId,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'name': name,
        'legalName': legalName,
        'taxId': taxId,
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
        'Company not found after update.',
        code: 'company_not_found_after_update',
      );
    }
    return updated;
  }
}
