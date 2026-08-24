import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a Customer scoped by organization.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] and [companyId] remain duplicated in the payload
/// so Security Rules and queries can validate tenant scope without trusting a
/// client form value.
final class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.type,
    required this.document,
    this.legalName,
    this.tradeName,
    this.fullName,
    this.stateRegistration,
    this.primaryEmail,
    this.primaryPhone,
    required this.status,
    this.classification,
    this.potential,
    this.segment,
    this.originChannel,
    this.responsibleSellerId,
    required this.registeredAt,
    this.lastPurchaseAt,
    this.addresses = const <CustomerAddressDto>[],
    this.contacts = const <CustomerContactDto>[],
    this.tags = const <String>[],
    this.customFields = const <String, Object?>{},
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  factory CustomerDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final type = json['type'];
    final document = json['document'];
    final legalName = json['legalName'];
    final tradeName = json['tradeName'];
    final fullName = json['fullName'];
    final stateRegistration = json['stateRegistration'];
    final primaryEmail = json['primaryEmail'];
    final primaryPhone = json['primaryPhone'];
    final status = json['status'];
    final classification = json['classification'];
    final potential = json['potential'];
    final segment = json['segment'];
    final originChannel = json['originChannel'];
    final responsibleSellerId = json['responsibleSellerId'];
    final registeredAt = json['registeredAt'];
    final lastPurchaseAt = json['lastPurchaseAt'];
    final rawAddresses = json['addresses'];
    final rawContacts = json['contacts'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        companyId is! String ||
        type is! String ||
        document is! String ||
        (legalName != null && legalName is! String) ||
        (tradeName != null && tradeName is! String) ||
        (fullName != null && fullName is! String) ||
        (stateRegistration != null && stateRegistration is! String) ||
        (primaryEmail != null && primaryEmail is! String) ||
        (primaryPhone != null && primaryPhone is! String) ||
        status is! String ||
        (classification != null && classification is! String) ||
        (potential != null && potential is! String) ||
        (segment != null && segment is! String) ||
        (originChannel != null && originChannel is! String) ||
        (responsibleSellerId != null && responsibleSellerId is! String) ||
        registeredAt is! Timestamp ||
        (lastPurchaseAt != null && lastPurchaseAt is! Timestamp) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid customer payload.',
        code: 'invalid_customer_payload',
      );
    }

    return CustomerDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      type: type,
      document: document,
      legalName: legalName as String?,
      tradeName: tradeName as String?,
      fullName: fullName as String?,
      stateRegistration: stateRegistration as String?,
      primaryEmail: primaryEmail as String?,
      primaryPhone: primaryPhone as String?,
      status: status,
      classification: classification as String?,
      potential: potential as String?,
      segment: segment as String?,
      originChannel: originChannel as String?,
      responsibleSellerId: responsibleSellerId as String?,
      registeredAt: registeredAt.toDate(),
      lastPurchaseAt: (lastPurchaseAt as Timestamp?)?.toDate(),
      addresses: _addressDtosFromJson(rawAddresses),
      contacts: _contactDtosFromJson(rawContacts),
      tags: _tagsFromJson(json['tags']),
      customFields: _customFieldsFromJson(json['customFields']),
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String type;
  final String document;
  final String? legalName;
  final String? tradeName;
  final String? fullName;
  final String? stateRegistration;
  final String? primaryEmail;
  final String? primaryPhone;
  final String status;
  final String? classification;
  final String? potential;
  final String? segment;
  final String? originChannel;
  final String? responsibleSellerId;
  final DateTime registeredAt;
  final DateTime? lastPurchaseAt;
  final List<CustomerAddressDto> addresses;
  final List<CustomerContactDto> contacts;
  final List<String> tags;
  final Map<String, Object?> customFields;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'type': type,
      'document': document,
      'legalName': legalName,
      'tradeName': tradeName,
      'fullName': fullName,
      'stateRegistration': stateRegistration,
      'primaryEmail': primaryEmail,
      'primaryPhone': primaryPhone,
      'status': status,
      'classification': classification,
      'potential': potential,
      'segment': segment,
      'originChannel': originChannel,
      'responsibleSellerId': responsibleSellerId,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'lastPurchaseAt': lastPurchaseAt == null
          ? null
          : Timestamp.fromDate(lastPurchaseAt!),
      'addresses': addresses
          .map((address) => address.toJson())
          .toList(growable: false),
      'contacts': contacts
          .map((contact) => contact.toJson())
          .toList(growable: false),
      'tags': tags,
      'customFields': customFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}

final class CustomerAddressDto {
  const CustomerAddressDto({
    required this.id,
    required this.typeCode,
    required this.typeLabel,
    required this.street,
    this.number,
    this.complement,
    this.district,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.isPrimary,
  });

  factory CustomerAddressDto.fromJson(Map<String, dynamic> json) {
    return CustomerAddressDto(
      id: _requiredString(json, 'id'),
      typeCode: _requiredString(json, 'typeCode'),
      typeLabel: _requiredString(json, 'typeLabel'),
      street: _requiredString(json, 'street'),
      number: _optionalString(json, 'number'),
      complement: _optionalString(json, 'complement'),
      district: _optionalString(json, 'district'),
      city: _requiredString(json, 'city'),
      state: _requiredString(json, 'state'),
      zipCode: _requiredString(json, 'zipCode'),
      country: _requiredString(json, 'country'),
      isPrimary: _requiredBool(json, 'isPrimary'),
    );
  }

  final String id;
  final String typeCode;
  final String typeLabel;
  final String street;
  final String? number;
  final String? complement;
  final String? district;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isPrimary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'typeCode': typeCode,
      'typeLabel': typeLabel,
      'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (district != null) 'district': district,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isPrimary': isPrimary,
    };
  }
}

final class CustomerContactDto {
  const CustomerContactDto({
    required this.id,
    required this.typeCode,
    required this.typeLabel,
    required this.name,
    this.role,
    this.phone,
    this.email,
    required this.isPrimary,
  });

  factory CustomerContactDto.fromJson(Map<String, dynamic> json) {
    return CustomerContactDto(
      id: _requiredString(json, 'id'),
      typeCode: _requiredString(json, 'typeCode'),
      typeLabel: _requiredString(json, 'typeLabel'),
      name: _requiredString(json, 'name'),
      role: _optionalString(json, 'role'),
      phone: _optionalString(json, 'phone'),
      email: _optionalString(json, 'email'),
      isPrimary: _requiredBool(json, 'isPrimary'),
    );
  }

  final String id;
  final String typeCode;
  final String typeLabel;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final bool isPrimary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'typeCode': typeCode,
      'typeLabel': typeLabel,
      'name': name,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'isPrimary': isPrimary,
    };
  }
}

List<String> _tagsFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid customer tags.',
      code: 'invalid_customer_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}

Map<String, Object?> _customFieldsFromJson(Object? value) {
  if (value == null) return const <String, Object?>{};
  if (value is! Map<String, dynamic>) {
    throw const ValidationException(
      'Invalid customer custom fields.',
      code: 'invalid_customer_payload',
    );
  }
  return Map<String, Object?>.unmodifiable(value);
}

List<CustomerAddressDto> _addressDtosFromJson(Object? value) {
  if (value == null) return const <CustomerAddressDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid customer addresses.',
      code: 'invalid_customer_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid customer address payload.',
            code: 'invalid_customer_payload',
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
      'Invalid customer contacts.',
      code: 'invalid_customer_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid customer contact payload.',
            code: 'invalid_customer_payload',
          );
        }
        return CustomerContactDto.fromJson(item);
      })
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw const ValidationException(
    'Invalid customer nested payload.',
    code: 'invalid_customer_payload',
  );
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw const ValidationException(
    'Invalid customer nested payload.',
    code: 'invalid_customer_payload',
  );
}

bool _requiredBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw const ValidationException(
    'Invalid customer nested payload.',
    code: 'invalid_customer_payload',
  );
}
