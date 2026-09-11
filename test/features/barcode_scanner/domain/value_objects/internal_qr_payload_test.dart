import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';

void main() {
  group('InternalQrPayload', () {
    test('round-trips organizationId/variantId through encode/parse', () {
      const payload = InternalQrPayload.scheme;
      final encoded = InternalQrPayloadTestFactory.build(
        organizationId: 'org-1',
        variantId: 'variant-1',
      ).encode();

      expect(encoded, '$payload:v1:variant:org-1:variant-1');

      final parsed = InternalQrPayload.parse(encoded);
      expect(parsed.organizationId, 'org-1');
      expect(parsed.variantId, 'variant-1');
    });

    test('looksLikeInternalQr matches only the vestipro scheme prefix', () {
      expect(
        InternalQrPayload.looksLikeInternalQr('vestipro:v1:variant:o:v'),
        isTrue,
      );
      expect(InternalQrPayload.looksLikeInternalQr('7891234567895'), isFalse);
      expect(InternalQrPayload.looksLikeInternalQr('SKU-001'), isFalse);
    });

    test('rejects a malformed payload instead of partially parsing it', () {
      expect(
        () => InternalQrPayload.parse('vestipro:v1:variant:only-org'),
        throwsFormatException,
      );
      expect(
        () => InternalQrPayload.parse('vestipro:v2:variant:org-1:variant-1'),
        throwsFormatException,
      );
      expect(
        () => InternalQrPayload.parse('other:v1:variant:org-1:variant-1'),
        throwsFormatException,
      );
      expect(
        () => InternalQrPayload.parse('vestipro:v1:variant::variant-1'),
        throwsFormatException,
      );
    });

    test('never encodes anything beyond organizationId/variantId', () {
      final encoded = InternalQrPayloadTestFactory.build(
        organizationId: 'org-1',
        variantId: 'variant-1',
      ).encode();

      // No secret/token/price/personal-data-shaped segment — exactly 5
      // colon-delimited parts.
      expect(encoded.split(':'), hasLength(5));
    });
  });
}

/// [InternalQrPayload]'s constructor is private — `parse` is the only public
/// way to build one, so this factory goes through it via [InternalQrPayload]
/// itself instead of relying on reflection.
abstract final class InternalQrPayloadTestFactory {
  static InternalQrPayload build({
    required String organizationId,
    required String variantId,
  }) {
    return InternalQrPayload.parse(
      'vestipro:v1:variant:$organizationId:$variantId',
    );
  }
}
