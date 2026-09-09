import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/storage/storage.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_recognition_candidate.dart';
import '../../domain/entities/product_recognition_result.dart';
import '../../domain/repositories/product_recognition_repository.dart';
import '../../domain/value_objects/product_recognition_feedback_outcome.dart';

/// Uploads the captured photo, then calls the `recognizeProductImage`/
/// `submitProductRecognitionFeedback` Cloud Functions (TASK-191, EPIC-28) —
/// the only place this feature ever reaches the network. No Firestore
/// datasource exists for this feature: the embedding index and the
/// recognition-attempt cache are never readable directly by any client
/// (`firestore.rules` denies both outright) — the only way to obtain a
/// result is `recognizeProductImage`'s own response. Mirrors
/// `CloudFunctionsApproachSuggestionRepository` (TASK-187).
@LazySingleton(as: ProductRecognitionRepository)
final class CloudFunctionsProductRecognitionRepository
    implements ProductRecognitionRepository {
  const CloudFunctionsProductRecognitionRepository(
    this._functions,
    this._storage,
    this._firebaseAuth,
    this._compressor, {
    this._uuid = const Uuid(),
  });

  final CloudFunctionsService _functions;
  final StorageDataSource _storage;
  final FirebaseAuth _firebaseAuth;
  final ImageUploadCompressor _compressor;
  final Uuid _uuid;

  @override
  Future<AppResult<ProductRecognitionResult>> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) => _guard(() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const UnauthorizedException(
        'É necessário estar autenticado para identificar um produto por foto.',
      );
    }

    final fileName = '${_uuid.v4()}.jpg';
    final storagePath = StoragePaths.productRecognitionQuery(
      organizationId: organizationId,
      userId: uid,
      fileName: fileName,
    );
    final compressedBytes = await _compressor.compressForUpload(imageBytes);
    await _storage.uploadFile(
      path: storagePath,
      bytes: compressedBytes,
      contentType: 'image/jpeg',
    );

    final json = await _functions.call<Map<String, dynamic>>(
      'recognizeProductImage',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'storagePath': storagePath,
      },
    );
    final rawCandidates =
        json['candidates'] as List<dynamic>? ?? const <dynamic>[];
    return ProductRecognitionResult(
      attemptId: json['attemptId'] as String,
      candidates: rawCandidates
          .map((raw) {
            final candidate = Map<String, dynamic>.from(raw as Map);
            return ProductRecognitionCandidate(
              productId: candidate['productId'] as String,
              productName: candidate['productName'] as String,
              thumbnailUrl: candidate['thumbnailUrl'] as String?,
              score: (candidate['score'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      belowThreshold: json['belowThreshold'] as bool? ?? false,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  });

  @override
  Future<AppResult<void>> submitFeedback({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) => _guard(() async {
    await _functions.call<Map<String, dynamic>>(
      'submitProductRecognitionFeedback',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'attemptId': attemptId,
        'outcome': outcome.toWireValue(),
        if (matchedProductId != null && matchedProductId.isNotEmpty)
          'matchedProductId': matchedProductId,
      },
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada ao identificar o produto por foto.',
          cause: error,
        ),
      );
    }
  }
}
