import '../../../../core/errors/errors.dart';

/// Product SKU value object.
///
/// Normalizes to upper case and validates the format before any create/update
/// payload reaches a repository. Uniqueness per organization is enforced by
/// the backend (Firestore Security Rules/Cloud Functions); this value object
/// only guarantees a well-formed value, never uniqueness.
final class Sku {
  const Sku._(this.value);

  factory Sku.parse(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.isEmpty) {
      throw ValidationException(
        'SKU is required.',
        code: 'invalid_sku_length',
        fieldErrors: const <String, String>{'sku': 'SKU is required.'},
        cause: value,
      );
    }

    if (normalized.length < 2 || normalized.length > 40) {
      throw ValidationException(
        'Invalid SKU length.',
        code: 'invalid_sku_length',
        fieldErrors: const <String, String>{
          'sku': 'SKU must have between 2 and 40 characters.',
        },
        cause: normalized,
      );
    }

    if (!_formatPattern.hasMatch(normalized)) {
      throw ValidationException(
        'Invalid SKU format.',
        code: 'invalid_sku_format',
        fieldErrors: const <String, String>{
          'sku':
              'SKU must use letters, numbers, "-" or "_" and cannot start '
              'or end with a separator.',
        },
        cause: normalized,
      );
    }

    return Sku._(normalized);
  }

  static final RegExp _formatPattern = RegExp(r'^[A-Z0-9]+(?:[_-][A-Z0-9]+)*$');

  final String value;

  @override
  bool operator ==(Object other) => other is Sku && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
