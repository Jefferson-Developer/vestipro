/// VestiPro's own QR payload format (TASK-216 "formato seguro de QR
/// interno") — printed, for example, on a showroom rack tag to speed up
/// finding one specific variant without a garment-level EAN.
///
/// Deliberately carries only two non-sensitive identifiers
/// ([organizationId], [variantId]) — no token, secret, price or personal
/// data of any kind, so a photographed/leaked QR never grants anything by
/// itself: `ResolveProductCodeUseCase`/`ProductCodeLookupRepositoryImpl`
/// still resolve it through the exact same tenant-scoped, RBAC-checked
/// variant lookup every other code goes through, and a payload minted for a
/// *different* organization than the caller's active one is treated as "not
/// found", never as "switch tenant" or leaked as "exists elsewhere".
///
/// Encoded as `vestipro:v1:variant:<organizationId>:<variantId>` — plain
/// colon-delimited text (not a URI/JSON) so it stays short enough for a
/// small, high-contrast QR symbol on a garment tag.
final class InternalQrPayload {
  const InternalQrPayload._({
    required this.organizationId,
    required this.variantId,
  });

  static const String scheme = 'vestipro';
  static const String _version = 'v1';
  static const String _kind = 'variant';

  /// Cheap prefix check used by `ScannedCodeClassifier` to route a raw code
  /// to [parse] without paying for a full parse/validation on every other
  /// (far more common) barcode format.
  static bool looksLikeInternalQr(String raw) =>
      raw.trim().startsWith('$scheme:');

  /// Throws [FormatException] for anything that is not exactly this
  /// payload's shape — never partially trusts a malformed/tampered value.
  factory InternalQrPayload.parse(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 5 ||
        parts[0] != scheme ||
        parts[1] != _version ||
        parts[2] != _kind ||
        parts[3].trim().isEmpty ||
        parts[4].trim().isEmpty) {
      throw const FormatException('invalid_internal_qr_payload');
    }
    return InternalQrPayload._(organizationId: parts[3], variantId: parts[4]);
  }

  final String organizationId;
  final String variantId;

  String encode() => '$scheme:$_version:$_kind:$organizationId:$variantId';
}
