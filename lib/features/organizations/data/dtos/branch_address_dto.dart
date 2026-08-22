import '../../../../core/errors/errors.dart';

/// Firestore map shape for the `address` field of a Branch document
/// (TASK-027).
final class BranchAddressDto {
  const BranchAddressDto({
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory BranchAddressDto.fromJson(Map<String, dynamic> json) {
    final street = json['street'];
    final number = json['number'];
    final complement = json['complement'];
    final neighborhood = json['neighborhood'];
    final city = json['city'];
    final state = json['state'];
    final postalCode = json['postalCode'];
    final country = json['country'];

    if (street is! String ||
        number is! String ||
        (complement != null && complement is! String) ||
        neighborhood is! String ||
        city is! String ||
        state is! String ||
        postalCode is! String ||
        country is! String) {
      throw const ValidationException(
        'Invalid branch address payload.',
        code: 'invalid_branch_address_payload',
      );
    }

    return BranchAddressDto(
      street: street,
      number: number,
      complement: complement as String?,
      neighborhood: neighborhood,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
    );
  }

  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}
