/// Shape of a raw code the scanner (camera or manual fallback) captured,
/// before it is resolved against the catalog (TASK-216).
///
/// [unknown] never reaches [ScannedCodeClassifier]'s callers as a resolvable
/// code — an empty/blank raw value classifies as [unknown] so
/// `ProductCodeLookupRepository` can short-circuit to "not found" without a
/// wasted lookup.
enum ScannedCodeFormat {
  /// GS1 EAN-13 barcode, the common garment-tag barcode length.
  ean13,

  /// GS1 EAN-8 barcode (shorter format, less common on apparel tags).
  ean8,

  /// A code that failed EAN checksum validation but is otherwise non-blank —
  /// treated as a candidate SKU/reference, VestiPro's own alphanumeric
  /// identifiers (see `Sku`/`Product.reference`).
  sku,

  /// A VestiPro-minted QR payload (`InternalQrPayload`), never a third-party
  /// barcode standard.
  internalQr,

  /// Blank/empty raw value — never a valid code.
  unknown,
}
