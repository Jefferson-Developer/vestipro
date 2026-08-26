import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/catalog_share_preview_dto.dart';
import 'catalog_share_lookup_data_source.dart';

/// [CatalogShareLookupDataSource] backed by [CloudFunctionsService]
/// (TASK-081) — never talks to `cloud_firestore` directly, same rationale as
/// `CloudFunctionsInviteAcceptanceDataSource`.
@LazySingleton(as: CatalogShareLookupDataSource)
final class CloudFunctionsCatalogShareLookupDataSource
    implements CatalogShareLookupDataSource {
  const CloudFunctionsCatalogShareLookupDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<CatalogSharePreviewDto> preview({required String token}) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'getCatalogShareLink',
      data: <String, dynamic>{'token': token},
      // Deliberately `false`: a catalog share link must work for a visitor
      // who never signs in at all (TASK-081: "sem exigir login do
      // cliente").
      requireAuth: false,
    );
    return CatalogSharePreviewDto.fromJson(response);
  }

  @override
  Future<void> registerOpen({required String token}) async {
    // Best-effort by construction: `registerCatalogShareOpen` itself never
    // throws (see its own doc) and this call is never awaited by its
    // caller (`RegisterCatalogShareOpenUseCase`/`CatalogSharePublicBloc`)
    // before rendering the preview it already has. Any remaining
    // network-level failure here (e.g. offline) is deliberately swallowed —
    // nothing about "did the open counter update" may ever surface as an
    // error to a customer who is only here to look at a catalog.
    try {
      await _cloudFunctionsService.call<Map<String, dynamic>>(
        'registerCatalogShareOpen',
        data: <String, dynamic>{'token': token},
        requireAuth: false,
      );
    } catch (_) {
      // Intentionally ignored — see doc above.
    }
  }
}
