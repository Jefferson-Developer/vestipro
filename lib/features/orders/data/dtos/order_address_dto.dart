import '../../../../core/errors/errors.dart';

/// Firestore-embedded shape of an `OrderAddress` (TASK-095) — nested inside
/// [OrderDto], never its own top-level document.
final class OrderAddressDto {
  const OrderAddressDto({
    required this.street,
    this.number,
    this.complement,
    this.district,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory OrderAddressDto.fromJson(Map<String, dynamic> json) {
    return OrderAddressDto(
      street: _requiredString(json, 'street'),
      number: _optionalString(json, 'number'),
      complement: _optionalString(json, 'complement'),
      district: _optionalString(json, 'district'),
      city: _requiredString(json, 'city'),
      state: _requiredString(json, 'state'),
      zipCode: _requiredString(json, 'zipCode'),
      country: _requiredString(json, 'country'),
    );
  }

  final String street;
  final String? number;
  final String? complement;
  final String? district;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (district != null) 'district': district,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw const ValidationException(
    'Invalid order address payload.',
    code: 'invalid_order_payload',
  );
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw const ValidationException(
    'Invalid order address payload.',
    code: 'invalid_order_payload',
  );
}
