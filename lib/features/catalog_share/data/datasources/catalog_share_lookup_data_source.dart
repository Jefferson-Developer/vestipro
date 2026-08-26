import '../dtos/catalog_share_preview_dto.dart';

/// Contract for the two public, unauthenticated catalog share Cloud
/// Functions (TASK-081): `getCatalogShareLink` and
/// `registerCatalogShareOpen`. Always Cloud Function calls — no Firestore
/// read/write of `catalogShares` ever happens directly here (see
/// `firestore.rules`: reading it directly is restricted to the share's own
/// creator/an OWNER-ADMIN, never an anonymous caller).
abstract interface class CatalogShareLookupDataSource {
  Future<CatalogSharePreviewDto> preview({required String token});

  /// Best-effort — never throws, see `registerCatalogShareOpen`'s own doc.
  Future<void> registerOpen({required String token});
}
