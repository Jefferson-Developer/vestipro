import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/user_profile_dto.dart';
import 'user_profile_data_source.dart';

/// Firestore-backed [UserProfileDataSource] for the root `users` collection
/// (TASK-035).
///
/// Deliberately not built on [FirestoreCollectionDataSource]: that helper
/// always scopes reads/writes under
/// `organizations/{organizationId}/{collectionName}`, but a user profile is
/// created *before* any Organization exists for that user — mirroring why
/// [FirestoreOrganizationDataSource] does not use it either.
@LazySingleton(as: UserProfileDataSource)
final class FirestoreUserProfileDataSource implements UserProfileDataSource {
  const FirestoreUserProfileDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Future<void> createInitialProfile(UserProfileDto dto) async {
    try {
      // A plain `set` (not a read-then-write transaction, unlike
      // `FirestoreOrganizationDataSource.create`): a retry of this exact
      // step is only ever reachable *after* the matching Firebase Auth
      // account already exists (see `CreateAccountWithEmailAndPasswordUseCase`),
      // so there is no distinct "already created" branch to special-case —
      // writing the same [dto] again is always safe.
      await _collection.doc(dto.uid).set(dto.toJson());
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }
}
