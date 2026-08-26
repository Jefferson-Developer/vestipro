import '../dtos/catalog_share_dto.dart';
import '../dtos/catalog_share_item_dto.dart';

/// A [CatalogShareDto] together with the plaintext share token, returned
/// only by [CatalogShareDataSource.create] — see `IssuedCatalogShare`'s own
/// docs for why the token is never available again afterwards.
typedef IssuedCatalogShareDto = ({CatalogShareDto share, String token});

/// Contract for reading/writing
/// `organizations/{organizationId}/catalogShares` from the **vendor's**
/// side (TASK-081). [create]/[revoke] are always Cloud Function calls
/// (Admin SDK is the only writer of this collection — see
/// `firestore.rules`), never a direct Firestore write; [getById] reads
/// Firestore directly, gated by the same "creator or OWNER/ADMIN" rule the
/// Cloud Functions themselves re-validate for their own writes.
abstract interface class CatalogShareDataSource {
  Future<IssuedCatalogShareDto> create({
    required String organizationId,
    required String scope,
    required List<CatalogShareItemDto> items,
    String? collectionId,
    String? collectionName,
    int? expiresInDays,
  });

  Future<CatalogShareDto> revoke({
    required String organizationId,
    required String shareId,
  });

  Future<CatalogShareDto?> getById({
    required String organizationId,
    required String shareId,
  });
}
