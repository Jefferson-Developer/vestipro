import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/database.dart';
import '../../../core/errors/errors.dart';
import '../../../core/functions/functions.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/personal_data_export.dart';
import '../domain/repositories/personal_data_export_repository.dart';

final class FirestorePersonalDataExportRepository
    implements PersonalDataExportRepository {
  const FirestorePersonalDataExportRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final CloudFunctionsService _functions;

  @override
  Stream<AppResult<List<PersonalDataExport>>> watchExports({
    required String organizationId,
    required String userId,
  }) async* {
    try {
      await for (final snapshot
          in _firestore
              .collection('users')
              .doc(userId)
              .collection('personalDataExports')
              .where('organizationId', isEqualTo: organizationId)
              .orderBy('requestedAt', descending: true)
              .limit(10)
              .snapshots()) {
        try {
          yield AppSuccess<List<PersonalDataExport>>(
            snapshot.docs.map(_mapExport).toList(growable: false),
          );
        } catch (error) {
          yield AppFailure<List<PersonalDataExport>>(
            UnexpectedFailure(
              'Não foi possível interpretar suas exportações.',
              code: 'personal_data_export_invalid',
              cause: error,
            ),
          );
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      yield AppFailure<List<PersonalDataExport>>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(error, stackTrace),
        ),
      );
    }
  }

  @override
  Future<AppResult<String>> requestExport({
    required String organizationId,
  }) async {
    try {
      final response = await _functions.call<Map<String, dynamic>>(
        'requestPersonalDataExport',
        data: <String, dynamic>{'organizationId': organizationId},
        requireAuth: true,
      );
      final exportId = response['exportId'];
      if (exportId is! String || exportId.isEmpty) {
        throw const ValidationException(
          'Resposta inválida ao solicitar exportação.',
          code: 'personal_data_export_response_invalid',
        );
      }
      return AppSuccess<String>(exportId);
    } on AppException catch (error) {
      return AppFailure<String>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<String>(
        UnexpectedFailure(
          'Não foi possível solicitar a exportação.',
          code: 'personal_data_export_request_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<PersonalDataExportDownload>> createDownloadLink({
    required String exportId,
  }) async {
    try {
      final response = await _functions.call<Map<String, dynamic>>(
        'getPersonalDataExportDownloadUrl',
        data: <String, dynamic>{'exportId': exportId},
        requireAuth: true,
      );
      final url = Uri.tryParse(response['downloadUrl'] as String? ?? '');
      final fileName = response['fileName'];
      final expiresAt = DateTime.tryParse(
        response['expiresAt'] as String? ?? '',
      );
      if (url == null ||
          !url.hasScheme ||
          fileName is! String ||
          expiresAt == null) {
        throw const ValidationException(
          'Link de exportação inválido.',
          code: 'personal_data_export_link_invalid',
        );
      }
      return AppSuccess<PersonalDataExportDownload>(
        PersonalDataExportDownload(
          url: url,
          fileName: fileName,
          expiresAt: expiresAt,
        ),
      );
    } on AppException catch (error) {
      return AppFailure<PersonalDataExportDownload>(
        mapAppExceptionToFailure(error),
      );
    } catch (error) {
      return AppFailure<PersonalDataExportDownload>(
        UnexpectedFailure(
          'Não foi possível gerar o link de download.',
          code: 'personal_data_export_download_unexpected',
          cause: error,
        ),
      );
    }
  }

  PersonalDataExport _mapExport(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final status = PersonalDataExportStatus.values
        .where((value) => value.name == data['status'])
        .firstOrNull;
    final organizationId = data['organizationId'];
    final userId = data['userId'];
    final requestedAt = data['requestedAt'];
    if (status == null ||
        organizationId is! String ||
        userId is! String ||
        requestedAt is! Timestamp) {
      throw const ValidationException(
        'Solicitação de exportação inválida.',
        code: 'personal_data_export_document_invalid',
      );
    }
    return PersonalDataExport(
      id: snapshot.id,
      organizationId: organizationId,
      userId: userId,
      status: status,
      requestedAt: requestedAt.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      fileName: data['fileName'] as String?,
    );
  }
}
