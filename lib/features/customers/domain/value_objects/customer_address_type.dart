import '../../../../core/errors/errors.dart';

/// Address type selected in a Customer address book.
///
/// Organizations may add custom types. The stable [code] is what gets
/// persisted, while [label] is what the UI shows to the sales rep.
final class CustomerAddressType {
  const CustomerAddressType._({
    required this.code,
    required this.label,
    this.isCustom = false,
  });

  factory CustomerAddressType.custom(String value, {String? label}) {
    final raw = value.trim();
    final rawLabel = label?.trim();
    if (raw.isEmpty && (rawLabel == null || rawLabel.isEmpty)) {
      throw const ValidationException(
        'Invalid customer address type.',
        code: 'invalid_customer_address_type',
        fieldErrors: <String, String>{
          'addressType': 'Address type is required.',
        },
      );
    }

    final parts = raw.contains('|') ? raw.split('|') : raw.split(':');
    final typeLabel = (rawLabel != null && rawLabel.isNotEmpty)
        ? rawLabel
        : parts.length > 1
        ? parts.sublist(1).join(':').trim()
        : raw;
    final codeSource = parts.first.trim().isEmpty ? typeLabel : parts.first;
    final normalizedCode = normalizeCustomerTypeCode(codeSource);
    final standard = customerAddressTypeFromCode(normalizedCode);
    if (standard != null) return standard;

    return CustomerAddressType._(
      code: normalizedCode,
      label: typeLabel.isEmpty ? normalizedCode : typeLabel,
      isCustom: true,
    );
  }

  static const shipping = CustomerAddressType._(
    code: 'shipping',
    label: 'Entrega',
  );
  static const billing = CustomerAddressType._(
    code: 'billing',
    label: 'Cobranca',
  );
  static const other = CustomerAddressType._(code: 'other', label: 'Outro');

  static const defaults = <CustomerAddressType>[shipping, billing, other];

  final String code;
  final String label;
  final bool isCustom;

  @override
  bool operator ==(Object other) {
    return other is CustomerAddressType &&
        other.code == code &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(code, label);

  @override
  String toString() => label;
}

CustomerAddressType? customerAddressTypeFromCode(String code, {String? label}) {
  final normalized = normalizeCustomerTypeCode(code);
  return switch (normalized) {
    'shipping' => CustomerAddressType.shipping,
    'delivery' => CustomerAddressType.shipping,
    'entrega' => CustomerAddressType.shipping,
    'billing' => CustomerAddressType.billing,
    'cobranca' => CustomerAddressType.billing,
    'cobrança' => CustomerAddressType.billing,
    'other' => CustomerAddressType.other,
    'outro' => CustomerAddressType.other,
    _ when label != null && label.trim().isNotEmpty =>
      CustomerAddressType.custom(normalized, label: label),
    _ => null,
  };
}

String normalizeCustomerTypeCode(String value) {
  final withoutDiacritics = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàãâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòõôö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
  final normalized = withoutDiacritics.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return normalized
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
