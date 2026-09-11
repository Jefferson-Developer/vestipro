/// A code registered as an extra way to find [productId]/[variantId]
/// (TASK-216 "códigos alternativos por variante") — used when the printed
/// garment barcode was damaged/reprinted, or a legacy EAN still circulates
/// for an already-recoded product, so the seller's scan still resolves
/// instead of surfacing "código desconhecido" every time.
///
/// Registering one never bypasses catalog RBAC: only
/// `RegisterUnknownProductCodeUseCase`, gated by `Capability.catalogManage`,
/// ever creates one (see that use case's doc).
final class AlternateProductCode {
  const AlternateProductCode({
    required this.organizationId,
    required this.code,
    required this.productId,
    this.variantId,
    required this.registeredAt,
    required this.registeredBy,
  });

  final String organizationId;

  /// Already normalized the same way `ScannedCodeClassifier` compares codes
  /// (digits-only for an EAN-shaped code, trimmed upper case otherwise) —
  /// callers never need to re-normalize this before comparing.
  final String code;

  final String productId;

  /// `null` registers the code at product level only (every active variant
  /// of [productId] is a valid resolution target) — mirrors
  /// [ProductCodeMatch.variant] being nullable for the same reason.
  final String? variantId;

  final DateTime registeredAt;
  final String registeredBy;
}
