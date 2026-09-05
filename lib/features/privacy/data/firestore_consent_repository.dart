import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/database.dart';
import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/consent_record.dart';
import '../domain/repositories/consent_repository.dart';

final class FirestoreConsentRepository implements ConsentRepository {
  const FirestoreConsentRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<AppResult<void>> appendConsentRecord(ConsentRecord record) async {
    try {
      await _records(record.userId).add(<String, Object?>{
        'organizationId': record.organizationId,
        'userId': record.userId,
        'purpose': record.purpose.code,
        'granted': record.granted,
        // Immutable server time makes the compliance trail auditable.
        'recordedAt': FieldValue.serverTimestamp(),
      });
      return const AppSuccess<void>(null);
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<void>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Não foi possível atualizar o consentimento.',
          code: 'consent_write_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ConsentRecord>>> listUserConsents({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final snapshot = await _query(userId, organizationId).get();
      return AppSuccess<List<ConsentRecord>>(_map(snapshot.docs));
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<List<ConsentRecord>>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } catch (exception) {
      return AppFailure<List<ConsentRecord>>(
        UnexpectedFailure(
          'Não foi possível carregar os consentimentos.',
          code: 'consent_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<ConsentRecord>>> watchUserConsents({
    required String organizationId,
    required String userId,
  }) => _watch(userId: userId, organizationId: organizationId);

  Stream<AppResult<List<ConsentRecord>>> _watch({
    required String userId,
    required String organizationId,
  }) async* {
    try {
      await for (final snapshot in _query(userId, organizationId).snapshots()) {
        try {
          yield AppSuccess<List<ConsentRecord>>(_map(snapshot.docs));
        } catch (exception) {
          yield AppFailure<List<ConsentRecord>>(
            UnexpectedFailure(
              'Não foi possível acompanhar os consentimentos.',
              code: 'consent_watch_unexpected',
              cause: exception,
            ),
          );
        }
      }
    } on FirebaseException catch (exception, stackTrace) {
      yield AppFailure<List<ConsentRecord>>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _records(String userId) =>
      _firestore.collection('users').doc(userId).collection('consentRecords');

  Query<Map<String, dynamic>> _query(String userId, String organizationId) =>
      _records(userId).where('organizationId', isEqualTo: organizationId);

  List<ConsentRecord> _map(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) => documents
      .map((snapshot) {
        final data = snapshot.data();
        final purpose = ConsentPurpose.values
            .where((value) => value.code == data['purpose'])
            .firstOrNull;
        final organizationId = data['organizationId'];
        final userId = data['userId'];
        final granted = data['granted'];
        final recordedAt = data['recordedAt'];
        if (purpose == null ||
            organizationId is! String ||
            userId is! String ||
            granted is! bool ||
            recordedAt is! Timestamp) {
          throw const ValidationException(
            'Registro de consentimento inválido.',
            code: 'invalid_consent_record',
          );
        }
        return ConsentRecord(
          id: snapshot.id,
          organizationId: organizationId,
          userId: userId,
          purpose: purpose,
          granted: granted,
          recordedAt: recordedAt.toDate(),
        );
      })
      .toList(growable: false);
}
