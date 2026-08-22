import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/organization_dto.dart';
import '../dtos/organization_settings_dto.dart';
import 'organization_data_source.dart';

/// Firestore-backed [OrganizationDataSource] for the root `organizations`
/// collection (TASK-026).
///
/// Deliberately not built on [FirestoreCollectionDataSource]: that helper
/// always scopes reads/writes under
/// `organizations/{organizationId}/{collectionName}`, but an Organization
/// document *is* the tenant root, not one of its subcollections.
@LazySingleton(as: OrganizationDataSource)
final class FirestoreOrganizationDataSource implements OrganizationDataSource {
  const FirestoreOrganizationDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('organizations');

  @override
  Future<OrganizationDto> create(OrganizationDto dto) async {
    try {
      final docRef = _collection.doc(dto.id);

      return await _firestore.runTransaction<OrganizationDto>((
        transaction,
      ) async {
        final snapshot = await transaction.get<Map<String, dynamic>>(docRef);
        final existingData = snapshot.data();

        if (snapshot.exists && existingData != null) {
          // A retry of a create that already landed: return what is
          // already there instead of overwriting it or failing with a
          // conflict, so callers stay idempotent across network retries.
          return OrganizationDto.fromJson(existingData, id: snapshot.id);
        }

        transaction.set<Map<String, dynamic>>(docRef, dto.toJson());
        return dto;
      });
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<OrganizationDto?> getById(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OrganizationDto.fromJson(data, id: snapshot.id);
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<OrganizationDto> updateSettings({
    required String id,
    required OrganizationSettingsDto settings,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    try {
      final docRef = _collection.doc(id);
      await docRef.update(<String, Object?>{
        'settings': settings.toJson(),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      });

      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const NotFoundException(
          'Organization not found after settings update.',
          code: 'organization_not_found_after_update',
        );
      }
      return OrganizationDto.fromJson(data, id: snapshot.id);
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }
}
