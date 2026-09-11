import '../../../../core/errors/errors.dart';
import '../../../products/domain/value_objects/ean.dart';
import '../entities/scanned_code.dart';
import '../value_objects/internal_qr_payload.dart';
import '../value_objects/scanned_code_format.dart';

/// Classifies a raw scanned/typed value into a [ScannedCode] (TASK-216) —
/// the one place that decides "is this an EAN, a VestiPro internal QR, or a
/// free-form SKU/reference candidate", so `ProductCodeLookupRepositoryImpl`
/// and every widget/test that needs the same classification never
/// reimplement it.
abstract final class ScannedCodeClassifier {
  static ScannedCode classify(String raw) {
    final trimmed = raw.trim();
    final now = DateTime.now().toUtc();

    if (trimmed.isEmpty) {
      return ScannedCode(
        rawValue: trimmed,
        format: ScannedCodeFormat.unknown,
        scannedAt: now,
      );
    }

    if (InternalQrPayload.looksLikeInternalQr(trimmed)) {
      return ScannedCode(
        rawValue: trimmed,
        format: ScannedCodeFormat.internalQr,
        scannedAt: now,
      );
    }

    try {
      final ean = Ean.parse(trimmed);
      return ScannedCode(
        rawValue: trimmed,
        format: ean.format == EanFormat.ean13
            ? ScannedCodeFormat.ean13
            : ScannedCodeFormat.ean8,
        scannedAt: now,
      );
    } on ValidationException {
      // Not a valid EAN — fall through to treat it as a SKU/reference
      // candidate instead of rejecting it outright.
    }

    return ScannedCode(
      rawValue: trimmed,
      format: ScannedCodeFormat.sku,
      scannedAt: now,
    );
  }

  /// The value every exact-match comparison (variant/product/alternate code
  /// lookup) uses — digits-only for an EAN-shaped code (mirrors
  /// `Ean.digits`), trimmed upper case otherwise (mirrors `Sku.value`'s own
  /// normalization) — so a scanned `"7891234567895"` and a stored
  /// `Ean.digits` compare equal, and a manually typed `"cam-bas-001"`
  /// compares equal to the stored `Sku.value` `"CAM-BAS-001"`.
  static String comparableValue(ScannedCode code) {
    return switch (code.format) {
      ScannedCodeFormat.ean13 ||
      ScannedCodeFormat.ean8 => code.rawValue.replaceAll(RegExp(r'\D'), ''),
      ScannedCodeFormat.sku ||
      ScannedCodeFormat.internalQr ||
      ScannedCodeFormat.unknown => code.rawValue.trim().toUpperCase(),
    };
  }
}
