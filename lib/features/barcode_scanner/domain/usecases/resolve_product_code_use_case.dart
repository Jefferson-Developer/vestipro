import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_code_resolution.dart';
import '../repositories/product_code_lookup_repository.dart';

/// Resolves one scanned/typed [rawCode] (TASK-216) — input validation plus
/// the analytics trail only; the actual lookup algorithm (alternate code,
/// variant, product, internal QR, tenant scoping) lives in
/// `ProductCodeLookupRepositoryImpl`, the same "thin use case, repository
/// owns the query" shape `SearchProductsUseCase` already sets for the
/// product catalog's own search.
///
/// Never logs [rawCode] itself — only the resolution outcome/match count —
/// mirroring `RecognizeProductImageUseCase`'s "never the recognized product
/// ids/names themselves" analytics precedent.
@injectable
final class ResolveProductCodeUseCase {
  const ResolveProductCodeUseCase(this._repository, this._analyticsService);

  final ProductCodeLookupRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<ProductCodeResolution>> call({
    required String organizationId,
    required String rawCode,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCode = rawCode.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCode.isEmpty) {
      fieldErrors['rawCode'] = 'A scanned or typed code is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ProductCodeResolution>(
        ValidationFailure(
          'Invalid product code resolution payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_code_resolution_payload',
        ),
      );
    }

    final result = await _repository.resolveCode(
      organizationId: trimmedOrganizationId,
      rawCode: trimmedCode,
    );
    if (result case AppSuccess<ProductCodeResolution>(
      value: final resolution,
    )) {
      await _analyticsService.logEvent(
        AnalyticsEvents.barcodeScanResolved,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'resolution_status': resolution.status.name,
          'match_count': resolution.matches.length,
        },
      );
    }
    return result;
  }
}
