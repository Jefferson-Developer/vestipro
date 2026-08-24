import '../../../../core/errors/errors.dart';

/// GS1 barcode format detected from an [Ean] digit length.
enum EanFormat { ean13, ean8 }

/// EAN-13/EAN-8 barcode value object with checksum validation.
///
/// A Product may have no [Ean] of its own when the sellable code lives on the
/// color/size variant instead (see TASK-064 business rules), so this value
/// object is only constructed when a code is actually informed.
final class Ean {
  const Ean._(this.digits);

  factory Ean.parse(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 13 && digits.length != 8) {
      throw ValidationException(
        'Invalid EAN length.',
        code: 'invalid_ean_length',
        fieldErrors: const <String, String>{
          'ean': 'EAN must have 8 (EAN-8) or 13 (EAN-13) digits.',
        },
        cause: digits,
      );
    }

    if (!_hasValidCheckDigit(digits)) {
      throw ValidationException(
        'Invalid EAN check digit.',
        code: 'invalid_ean_check_digit',
        fieldErrors: const <String, String>{
          'ean': 'EAN check digit does not match.',
        },
        cause: digits,
      );
    }

    return Ean._(digits);
  }

  final String digits;

  EanFormat get format =>
      digits.length == 13 ? EanFormat.ean13 : EanFormat.ean8;

  /// GS1 check-digit algorithm: walking right to left, starting immediately
  /// left of the check digit, weights alternate 3/1. It is length-agnostic
  /// (works for both EAN-13 and EAN-8) because both are right-aligned GTINs.
  static bool _hasValidCheckDigit(String digits) {
    var sum = 0;
    for (var offset = 1; offset < digits.length; offset += 1) {
      final digit = _digitAt(digits, digits.length - 1 - offset);
      final weight = offset.isOdd ? 3 : 1;
      sum += digit * weight;
    }
    final expectedCheckDigit = (10 - (sum % 10)) % 10;
    return _digitAt(digits, digits.length - 1) == expectedCheckDigit;
  }

  static int _digitAt(String digits, int index) {
    return digits.codeUnitAt(index) - 48;
  }

  @override
  bool operator ==(Object other) => other is Ean && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => digits;
}
