import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_recognition_result.dart';
import '../repositories/product_recognition_repository.dart';

/// Requests TASK-191's "reconhecimento de produto por imagem" (EPIC-28) for
/// one captured photo. Input validation only — the real authorization
/// boundary (active Membership in [organizationId]) is always re-checked
/// server-side by `recognizeProductImage` regardless of what the UI
/// enforces.
@injectable
final class RecognizeProductImageUseCase {
  const RecognizeProductImageUseCase(this._repository, this._analyticsService);

  final ProductRecognitionRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<ProductRecognitionResult>> call({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (imageBytes.isEmpty) {
      fieldErrors['imageBytes'] = 'A captured photo is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ProductRecognitionResult>(
        ValidationFailure(
          'Invalid product recognition request.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_recognition_request',
        ),
      );
    }

    final result = await _repository.recognize(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      imageBytes: imageBytes,
    );
    switch (result) {
      case AppSuccess<ProductRecognitionResult>(value: final recognitionResult):
        await _analyticsService.logEvent(
          AnalyticsEvents.productRecognitionCompleted,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'candidate_count': recognitionResult.candidates.length,
            'below_threshold': recognitionResult.belowThreshold,
          },
        );
      case AppFailure<ProductRecognitionResult>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.productRecognitionFailed,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'failure_code': failure.code,
          },
        );
    }
    return result;
  }
}
