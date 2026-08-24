import '../../../../core/errors/errors.dart';
import 'customer_dto.dart';

final class CustomerFormDraftDto {
  const CustomerFormDraftDto({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.document,
    this.legalName,
    this.tradeName,
    this.fullName,
    this.stateRegistration,
    this.primaryEmail,
    this.primaryPhone,
    this.classification,
    this.potential,
    this.responsibleSellerId,
    this.addresses = const <CustomerAddressDto>[],
    this.contacts = const <CustomerContactDto>[],
    required this.savedAt,
  });

  factory CustomerFormDraftDto.fromJson(Map<String, dynamic> json) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final userId = json['userId'];
    final type = json['type'];
    final document = json['document'];
    final legalName = json['legalName'];
    final tradeName = json['tradeName'];
    final fullName = json['fullName'];
    final stateRegistration = json['stateRegistration'];
    final primaryEmail = json['primaryEmail'];
    final primaryPhone = json['primaryPhone'];
    final classification = json['classification'];
    final potential = json['potential'];
    final responsibleSellerId = json['responsibleSellerId'];
    final rawAddresses = json['addresses'];
    final rawContacts = json['contacts'];
    final savedAt = json['savedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        userId is! String ||
        type is! String ||
        document is! String ||
        (legalName != null && legalName is! String) ||
        (tradeName != null && tradeName is! String) ||
        (fullName != null && fullName is! String) ||
        (stateRegistration != null && stateRegistration is! String) ||
        (primaryEmail != null && primaryEmail is! String) ||
        (primaryPhone != null && primaryPhone is! String) ||
        (classification != null && classification is! String) ||
        (potential != null && potential is! String) ||
        (responsibleSellerId != null && responsibleSellerId is! String) ||
        savedAt is! String) {
      throw const ValidationException(
        'Invalid customer draft payload.',
        code: 'invalid_customer_draft_payload',
      );
    }

    return CustomerFormDraftDto(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      type: type,
      document: document,
      legalName: legalName as String?,
      tradeName: tradeName as String?,
      fullName: fullName as String?,
      stateRegistration: stateRegistration as String?,
      primaryEmail: primaryEmail as String?,
      primaryPhone: primaryPhone as String?,
      classification: classification as String?,
      potential: potential as String?,
      responsibleSellerId: responsibleSellerId as String?,
      addresses: _addressDtosFromJson(rawAddresses),
      contacts: _contactDtosFromJson(rawContacts),
      savedAt: DateTime.parse(savedAt),
    );
  }

  final String organizationId;
  final String companyId;
  final String userId;
  final String type;
  final String document;
  final String? legalName;
  final String? tradeName;
  final String? fullName;
  final String? stateRegistration;
  final String? primaryEmail;
  final String? primaryPhone;
  final String? classification;
  final String? potential;
  final String? responsibleSellerId;
  final List<CustomerAddressDto> addresses;
  final List<CustomerContactDto> contacts;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'userId': userId,
      'type': type,
      'document': document,
      if (legalName != null) 'legalName': legalName,
      if (tradeName != null) 'tradeName': tradeName,
      if (fullName != null) 'fullName': fullName,
      if (stateRegistration != null) 'stateRegistration': stateRegistration,
      if (primaryEmail != null) 'primaryEmail': primaryEmail,
      if (primaryPhone != null) 'primaryPhone': primaryPhone,
      if (classification != null) 'classification': classification,
      if (potential != null) 'potential': potential,
      if (responsibleSellerId != null)
        'responsibleSellerId': responsibleSellerId,
      if (addresses.isNotEmpty)
        'addresses': addresses
            .map((address) => address.toJson())
            .toList(growable: false),
      if (contacts.isNotEmpty)
        'contacts': contacts
            .map((contact) => contact.toJson())
            .toList(growable: false),
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }
}

List<CustomerAddressDto> _addressDtosFromJson(Object? value) {
  if (value == null) return const <CustomerAddressDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid customer draft address payload.',
      code: 'invalid_customer_draft_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid customer draft address payload.',
            code: 'invalid_customer_draft_payload',
          );
        }
        return CustomerAddressDto.fromJson(item);
      })
      .toList(growable: false);
}

List<CustomerContactDto> _contactDtosFromJson(Object? value) {
  if (value == null) return const <CustomerContactDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid customer draft contact payload.',
      code: 'invalid_customer_draft_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid customer draft contact payload.',
            code: 'invalid_customer_draft_payload',
          );
        }
        return CustomerContactDto.fromJson(item);
      })
      .toList(growable: false);
}
