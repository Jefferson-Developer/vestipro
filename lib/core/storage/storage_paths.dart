/// Centralizes every Firebase Storage path the app writes to, so no feature
/// datasource ever hand-builds a path string.
///
/// Every path returned by this class starts with `organizations/{organizationId}/`
/// (ADR-0002/tenant isolation convention, mirrored from
/// `FirestoreCollectionDataSource` in `lib/core/database/`): a client-side
/// convention only, never the real authorization boundary — the real boundary
/// is `storage.rules` (real RBAC/multi-tenant isolation since TASK-031). A
/// correctly-shaped path is not itself permission to read/write it: every
/// read/write is re-validated server-side against the caller's real
/// Membership/capability, exactly as `firestore.rules` (TASK-030) already
/// does.
///
/// Path conventions (see `tasks.md`, seção 20):
/// - Product media: `organizations/{organizationId}/products/{productId}/{fileName}`
/// - Order attachments: `organizations/{organizationId}/orders/{orderId}/attachments/{fileName}`
/// - User avatar: `organizations/{organizationId}/users/{userId}/avatar`
/// - Campaign media: `organizations/{organizationId}/campaigns/{campaignId}/{fileName}`
final class StoragePaths {
  const StoragePaths._();

  static String productFile({
    required String organizationId,
    required String productId,
    required String fileName,
  }) {
    _requireNonEmpty(organizationId, 'organizationId');
    _requireNonEmpty(productId, 'productId');
    _requireNonEmpty(fileName, 'fileName');
    return 'organizations/$organizationId/products/$productId/$fileName';
  }

  /// Cover/editorial images of a `CatalogCampaign` lookbook (TASK-080),
  /// following the exact same "compression, format and reordering rules"
  /// product media already uses (TASK-068) — only the folder differs.
  static String campaignFile({
    required String organizationId,
    required String campaignId,
    required String fileName,
  }) {
    _requireNonEmpty(organizationId, 'organizationId');
    _requireNonEmpty(campaignId, 'campaignId');
    _requireNonEmpty(fileName, 'fileName');
    return 'organizations/$organizationId/campaigns/$campaignId/$fileName';
  }

  static String orderAttachment({
    required String organizationId,
    required String orderId,
    required String fileName,
  }) {
    _requireNonEmpty(organizationId, 'organizationId');
    _requireNonEmpty(orderId, 'orderId');
    _requireNonEmpty(fileName, 'fileName');
    return 'organizations/$organizationId/orders/$orderId/attachments/$fileName';
  }

  /// There is only one avatar per user, so unlike [productFile] and
  /// [orderAttachment] this path has no file name segment: a new upload is
  /// always meant to replace the previous avatar at the same path.
  static String userAvatar({
    required String organizationId,
    required String userId,
  }) {
    _requireNonEmpty(organizationId, 'organizationId');
    _requireNonEmpty(userId, 'userId');
    return 'organizations/$organizationId/users/$userId/avatar';
  }

  /// Throws [ArgumentError] instead of returning a malformed path: an empty
  /// tenant/entity id here is always a caller bug (e.g. building a path
  /// before the current organization is known), never an expected runtime
  /// failure a UI should recover from.
  static void _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, '$name não pode ser vazio.');
    }
  }
}
