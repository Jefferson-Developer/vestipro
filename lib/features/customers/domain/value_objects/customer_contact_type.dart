import '../../../../core/errors/errors.dart';
import 'customer_address_type.dart';

/// Contact type selected in a Customer contact book.
final class CustomerContactType {
  const CustomerContactType._({
    required this.code,
    required this.label,
    this.isCustom = false,
  });

  factory CustomerContactType.custom(String value, {String? label}) {
    final raw = value.trim();
    final rawLabel = label?.trim();
    if (raw.isEmpty && (rawLabel == null || rawLabel.isEmpty)) {
      throw const ValidationException(
        'Invalid customer contact type.',
        code: 'invalid_customer_contact_type',
        fieldErrors: <String, String>{
          'contactType': 'Contact type is required.',
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
    final standard = customerContactTypeFromCode(normalizedCode);
    if (standard != null) return standard;

    return CustomerContactType._(
      code: normalizedCode,
      label: typeLabel.isEmpty ? normalizedCode : typeLabel,
      isCustom: true,
    );
  }

  static const commercial = CustomerContactType._(
    code: 'commercial',
    label: 'Comercial',
  );
  static const buyer = CustomerContactType._(code: 'buyer', label: 'Compras');
  static const financial = CustomerContactType._(
    code: 'financial',
    label: 'Financeiro',
  );
  static const owner = CustomerContactType._(
    code: 'owner',
    label: 'Proprietario',
  );

  static const defaults = <CustomerContactType>[
    commercial,
    buyer,
    financial,
    owner,
  ];

  final String code;
  final String label;
  final bool isCustom;

  @override
  bool operator ==(Object other) {
    return other is CustomerContactType &&
        other.code == code &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(code, label);

  @override
  String toString() => label;
}

CustomerContactType? customerContactTypeFromCode(String code, {String? label}) {
  final normalized = normalizeCustomerTypeCode(code);
  return switch (normalized) {
    'commercial' => CustomerContactType.commercial,
    'comercial' => CustomerContactType.commercial,
    'buyer' => CustomerContactType.buyer,
    'compras' => CustomerContactType.buyer,
    'financial' => CustomerContactType.financial,
    'financeiro' => CustomerContactType.financial,
    'owner' => CustomerContactType.owner,
    'proprietario' => CustomerContactType.owner,
    'proprietário' => CustomerContactType.owner,
    _ when label != null && label.trim().isNotEmpty =>
      CustomerContactType.custom(normalized, label: label),
    _ => null,
  };
}
