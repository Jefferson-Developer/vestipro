import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'branch_address.freezed.dart';

/// Basic postal address of a [Branch] (`tasks.md`, seção 3.2 — "Loja
/// Blumenau", "Showroom São Paulo"). Deliberately minimal: no geocoding or
/// delivery-routing fields here, only what identifies where the unit is.
@freezed
abstract class BranchAddress with _$BranchAddress {
  const BranchAddress._();

  const factory BranchAddress({
    required String street,
    required String number,
    String? complement,
    required String neighborhood,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) = _BranchAddress;

  /// Builds a validated [BranchAddress], trimming every field and rejecting
  /// blanks in the required ones — [complement] is the only optional field
  /// and an empty string is normalized to `null`.
  factory BranchAddress.validated({
    required String street,
    required String number,
    String? complement,
    required String neighborhood,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) {
    final trimmedStreet = street.trim();
    final trimmedNumber = number.trim();
    final trimmedComplement = complement?.trim();
    final trimmedNeighborhood = neighborhood.trim();
    final trimmedCity = city.trim();
    final trimmedState = state.trim();
    final trimmedPostalCode = postalCode.trim();
    final trimmedCountry = country.trim();

    final fieldErrors = <String, String>{};
    if (trimmedStreet.isEmpty) fieldErrors['street'] = 'Street is required.';
    if (trimmedNumber.isEmpty) fieldErrors['number'] = 'Number is required.';
    if (trimmedNeighborhood.isEmpty) {
      fieldErrors['neighborhood'] = 'Neighborhood is required.';
    }
    if (trimmedCity.isEmpty) fieldErrors['city'] = 'City is required.';
    if (trimmedState.isEmpty) fieldErrors['state'] = 'State is required.';
    if (trimmedPostalCode.isEmpty) {
      fieldErrors['postalCode'] = 'Postal code is required.';
    }
    if (trimmedCountry.isEmpty) {
      fieldErrors['country'] = 'Country is required.';
    }

    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid branch address.',
        code: 'invalid_branch_address',
        fieldErrors: fieldErrors,
      );
    }

    return BranchAddress(
      street: trimmedStreet,
      number: trimmedNumber,
      complement: (trimmedComplement == null || trimmedComplement.isEmpty)
          ? null
          : trimmedComplement,
      neighborhood: trimmedNeighborhood,
      city: trimmedCity,
      state: trimmedState,
      postalCode: trimmedPostalCode,
      country: trimmedCountry,
    );
  }
}
