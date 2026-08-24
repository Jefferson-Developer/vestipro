import '../../../core/errors/errors.dart';
import 'entities/customer_address.dart';
import 'entities/customer_contact.dart';
import 'value_objects/cep.dart';
import 'value_objects/customer_address_type.dart';
import 'value_objects/customer_contact_type.dart';

CustomerAddress buildCustomerAddress({
  required String id,
  required CustomerAddressType type,
  required String street,
  String? number,
  String? complement,
  String? district,
  required String city,
  required String state,
  required String zipCode,
  String country = 'BR',
  bool isPrimary = false,
}) {
  final fieldErrors = <String, String>{};
  final trimmedId = id.trim();
  final trimmedStreet = street.trim();
  final trimmedCity = city.trim();
  final trimmedState = state.trim().toUpperCase();
  final trimmedCountry = country.trim().isEmpty
      ? 'BR'
      : country.trim().toUpperCase();

  if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
  if (trimmedStreet.isEmpty) fieldErrors['street'] = 'Street is required.';
  if (trimmedCity.isEmpty) fieldErrors['city'] = 'City is required.';
  if (trimmedState.isEmpty) {
    fieldErrors['state'] = 'State is required.';
  } else if (!RegExp(r'^[A-Z]{2}$').hasMatch(trimmedState)) {
    fieldErrors['state'] = 'State must use a valid UF.';
  }
  if (trimmedCountry.isEmpty) fieldErrors['country'] = 'Country is required.';

  Cep? parsedZipCode;
  try {
    parsedZipCode = Cep.parse(zipCode);
  } on ValidationException catch (exception) {
    fieldErrors['zipCode'] =
        exception.fieldErrors['zipCode'] ?? 'CEP is invalid.';
  }

  if (fieldErrors.isNotEmpty || parsedZipCode == null) {
    throw ValidationException(
      'Invalid customer address.',
      code: 'invalid_customer_address',
      fieldErrors: fieldErrors,
    );
  }

  return CustomerAddress(
    id: trimmedId,
    type: type,
    street: trimmedStreet,
    number: _blankToNull(number),
    complement: _blankToNull(complement),
    district: _blankToNull(district),
    city: trimmedCity,
    state: trimmedState,
    zipCode: parsedZipCode,
    country: trimmedCountry,
    isPrimary: isPrimary,
  );
}

CustomerContact buildCustomerContact({
  required String id,
  required CustomerContactType type,
  required String name,
  String? role,
  String? phone,
  String? email,
  bool isPrimary = false,
}) {
  final fieldErrors = <String, String>{};
  final trimmedId = id.trim();
  final trimmedName = name.trim();
  final normalizedPhone = _blankToNull(phone);
  final normalizedEmail = _blankToNull(email);

  if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
  if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
  if (normalizedPhone == null && normalizedEmail == null) {
    fieldErrors['phone'] = 'Phone or email is required.';
    fieldErrors['email'] = 'Phone or email is required.';
  }
  if (normalizedEmail != null &&
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
    fieldErrors['email'] = 'Email is invalid.';
  }

  if (fieldErrors.isNotEmpty) {
    throw ValidationException(
      'Invalid customer contact.',
      code: 'invalid_customer_contact',
      fieldErrors: fieldErrors,
    );
  }

  return CustomerContact(
    id: trimmedId,
    type: type,
    name: trimmedName,
    role: _blankToNull(role),
    phone: normalizedPhone,
    email: normalizedEmail,
    isPrimary: isPrimary,
  );
}

List<CustomerAddress> normalizeCustomerAddresses(
  Iterable<CustomerAddress> addresses,
) {
  final items = addresses.toList(growable: false);
  if (items.isEmpty) return const <CustomerAddress>[];
  final primaryIndex = items.indexWhere((address) => address.isPrimary);
  final resolvedPrimaryIndex = primaryIndex == -1 ? 0 : primaryIndex;
  return <CustomerAddress>[
    for (var index = 0; index < items.length; index += 1)
      items[index].copyWith(isPrimary: index == resolvedPrimaryIndex),
  ];
}

List<CustomerContact> normalizeCustomerContacts(
  Iterable<CustomerContact> contacts,
) {
  final items = contacts.toList(growable: false);
  if (items.isEmpty) return const <CustomerContact>[];
  final primaryIndex = items.indexWhere((contact) => contact.isPrimary);
  final resolvedPrimaryIndex = primaryIndex == -1 ? 0 : primaryIndex;
  return <CustomerContact>[
    for (var index = 0; index < items.length; index += 1)
      items[index].copyWith(isPrimary: index == resolvedPrimaryIndex),
  ];
}

CustomerAddress? primaryCustomerAddress(Iterable<CustomerAddress> addresses) {
  for (final address in addresses) {
    if (address.isPrimary) return address;
  }
  return addresses.isEmpty ? null : addresses.first;
}

CustomerContact? primaryCustomerContact(Iterable<CustomerContact> contacts) {
  for (final contact in contacts) {
    if (contact.isPrimary) return contact;
  }
  return contacts.isEmpty ? null : contacts.first;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
