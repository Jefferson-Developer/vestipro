import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/customer_address_contact_rules.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/value_objects/cep.dart';
import '../../domain/value_objects/cnpj_cpf.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
import '../../domain/value_objects/customer_sensitive_field.dart';
import '../../domain/value_objects/customer_status.dart';
import '../../domain/value_objects/customer_sync_status.dart';
import '../mappers/customer_mapper.dart';

/// Local customer store used until the remote/outbox sync implementation
/// exists. It keeps create/update mutations durable with `syncStatus.pending`
/// and performs local duplicate checks inside the active Organization.
@LazySingleton(as: CustomerRepository)
final class SharedPreferencesCustomerRepository implements CustomerRepository {
  const SharedPreferencesCustomerRepository(this._mapper);

  final CustomerMapper _mapper;

  String _keyFor(String organizationId) => 'customers_$organizationId';

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) async {
    try {
      final customers = await _load(organizationId);
      final excludingId = excludingCustomerId?.trim();
      return AppSuccess<bool>(
        customers.any(
          (customer) =>
              customer.deletedAt == null &&
              customer.document == document &&
              (excludingId == null ||
                  excludingId.isEmpty ||
                  customer.id != excludingId),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking customer document locally.',
          code: 'customer_local_exists_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) async {
    try {
      final customers = await _load(customer.organizationId);
      if (customers.any(
        (existing) =>
            existing.deletedAt == null &&
            existing.document == customer.document &&
            existing.id != customer.id,
      )) {
        return const AppFailure<Customer>(
          ConflictFailure(
            'Customer document already exists in this organization.',
            code: 'customer_document_already_exists',
          ),
        );
      }

      final next = <Customer>[
        ...customers.where((existing) => existing.id != customer.id),
        customer,
      ];
      await _save(customer.organizationId, next);
      return AppSuccess<Customer>(customer);
    } catch (exception) {
      return AppFailure<Customer>(
        UnexpectedFailure(
          'Unexpected error saving customer locally.',
          code: 'customer_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) async {
    try {
      final customers = await _load(customer.organizationId);
      final index = customers.indexWhere(
        (existing) => existing.id == customer.id,
      );
      if (index == -1) {
        return const AppFailure<Customer>(
          NotFoundFailure('Customer not found.', code: 'customer_not_found'),
        );
      }

      final next = List<Customer>.of(customers)..[index] = customer;
      await _save(customer.organizationId, next);
      return AppSuccess<Customer>(customer);
    } catch (exception) {
      return AppFailure<Customer>(
        UnexpectedFailure(
          'Unexpected error updating customer locally.',
          code: 'customer_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    try {
      final customers = await _load(organizationId);
      final index = customers.indexWhere((customer) => customer.id == id);
      if (index == -1) {
        return const AppFailure<Customer>(
          NotFoundFailure('Customer not found.', code: 'customer_not_found'),
        );
      }

      final now = DateTime.now().toUtc();
      final deactivated = customers[index].copyWith(
        status: CustomerStatus.inactive,
        deletedAt: now,
        updatedAt: now,
        updatedBy: updatedBy,
        version: customers[index].version + 1,
        syncStatus: CustomerSyncStatus.pending,
      );
      final next = List<Customer>.of(customers)..[index] = deactivated;
      await _save(organizationId, next);
      return AppSuccess<Customer>(deactivated);
    } catch (exception) {
      return AppFailure<Customer>(
        UnexpectedFailure(
          'Unexpected error deactivating customer locally.',
          code: 'customer_local_deactivate_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final customers = await _load(organizationId);
      for (final customer in customers) {
        if (customer.id == id) {
          return AppSuccess<Customer>(customer);
        }
      }
      return const AppFailure<Customer>(
        NotFoundFailure('Customer not found.', code: 'customer_not_found'),
      );
    } catch (exception) {
      return AppFailure<Customer>(
        UnexpectedFailure(
          'Unexpected error loading customer locally.',
          code: 'customer_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<Customer>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <Customer>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local customer list.',
        code: 'invalid_customer_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local customer payload.',
              code: 'invalid_customer_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<Customer> customers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(customers.map(_toJson).toList(growable: false)),
    );
  }

  Customer _fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _requiredString(json, 'companyId'),
      type: _mapper.typeToEntity(_requiredString(json, 'type')),
      document: CnpjCpf.parse(_requiredString(json, 'document')),
      legalName: _optionalString(json, 'legalName'),
      tradeName: _optionalString(json, 'tradeName'),
      fullName: _optionalString(json, 'fullName'),
      stateRegistration: _optionalString(json, 'stateRegistration'),
      primaryEmail: _optionalString(json, 'primaryEmail'),
      primaryPhone: _optionalString(json, 'primaryPhone'),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      classification: _optionalString(json, 'classification'),
      potential: _optionalString(json, 'potential'),
      segment: _optionalString(json, 'segment'),
      originChannel: _optionalString(json, 'originChannel'),
      responsibleSellerId: _optionalString(json, 'responsibleSellerId'),
      registeredAt: _requiredDate(json, 'registeredAt'),
      lastPurchaseAt: _optionalDate(json, 'lastPurchaseAt'),
      addresses: _addressesFromJson(json['addresses']),
      contacts: _contactsFromJson(json['contacts']),
      tags: _stringList(json['tags']),
      customFields: _objectMap(json['customFields']),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(Customer customer) {
    return <String, dynamic>{
      'id': customer.id,
      'organizationId': customer.organizationId,
      'companyId': customer.companyId,
      'type': _mapper.typeToDto(customer.type),
      'document': customer.document.digits,
      if (customer.legalName != null) 'legalName': customer.legalName,
      if (customer.tradeName != null) 'tradeName': customer.tradeName,
      if (customer.fullName != null) 'fullName': customer.fullName,
      if (customer.stateRegistration != null)
        'stateRegistration': customer.stateRegistration,
      if (customer.primaryEmail != null) 'primaryEmail': customer.primaryEmail,
      if (customer.primaryPhone != null) 'primaryPhone': customer.primaryPhone,
      'status': _mapper.statusToDto(customer.status),
      if (customer.classification != null)
        'classification': customer.classification,
      if (customer.potential != null) 'potential': customer.potential,
      if (customer.segment != null) 'segment': customer.segment,
      if (customer.originChannel != null)
        'originChannel': customer.originChannel,
      if (customer.responsibleSellerId != null)
        'responsibleSellerId': customer.responsibleSellerId,
      'registeredAt': customer.registeredAt.toUtc().toIso8601String(),
      if (customer.lastPurchaseAt != null)
        'lastPurchaseAt': customer.lastPurchaseAt!.toUtc().toIso8601String(),
      if (customer.addresses.isNotEmpty)
        'addresses': customer.addresses
            .map(_addressToJson)
            .toList(growable: false),
      if (customer.contacts.isNotEmpty)
        'contacts': customer.contacts
            .map(_contactToJson)
            .toList(growable: false),
      if (customer.tags.isNotEmpty) 'tags': customer.tags,
      if (customer.customFields.isNotEmpty)
        'customFields': customer.customFields,
      'createdAt': customer.createdAt.toUtc().toIso8601String(),
      'createdBy': customer.createdBy,
      'updatedAt': customer.updatedAt.toUtc().toIso8601String(),
      'updatedBy': customer.updatedBy,
      if (customer.deletedAt != null)
        'deletedAt': customer.deletedAt!.toUtc().toIso8601String(),
      'version': customer.version,
      'syncStatus': _mapper.syncStatusToDto(customer.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local customer string field.',
      code: 'invalid_customer_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local customer string field.',
      code: 'invalid_customer_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : DateTime.parse(value).toUtc();
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local customer integer field.',
      code: 'invalid_customer_local_payload',
      cause: field,
    );
  }

  List<String> _stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is! List<dynamic> || value.any((item) => item is! String)) {
      throw const ValidationException(
        'Invalid local customer string list.',
        code: 'invalid_customer_local_payload',
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  Map<String, Object?> _objectMap(Object? value) {
    if (value == null) return const <String, Object?>{};
    if (value is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local customer object map.',
        code: 'invalid_customer_local_payload',
      );
    }
    return Map<String, Object?>.unmodifiable(value);
  }

  List<CustomerAddress> _addressesFromJson(Object? value) {
    if (value == null) return const <CustomerAddress>[];
    if (value is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local customer addresses.',
        code: 'invalid_customer_local_payload',
      );
    }
    return normalizeCustomerAddresses(
      value.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid local customer address payload.',
            code: 'invalid_customer_local_payload',
          );
        }
        final typeCode = _requiredString(item, 'typeCode');
        final typeLabel = _requiredString(item, 'typeLabel');
        final type =
            customerAddressTypeFromCode(typeCode, label: typeLabel) ??
            CustomerAddressType.custom(typeCode, label: typeLabel);
        return CustomerAddress(
          id: _requiredString(item, 'id'),
          type: type,
          street: _requiredString(item, 'street'),
          number: _optionalString(item, 'number'),
          complement: _optionalString(item, 'complement'),
          district: _optionalString(item, 'district'),
          city: _requiredString(item, 'city'),
          state: _requiredString(item, 'state'),
          zipCode: Cep.parse(_requiredString(item, 'zipCode')),
          country: _requiredString(item, 'country'),
          isPrimary: _requiredBool(item, 'isPrimary'),
        );
      }),
    );
  }

  List<CustomerContact> _contactsFromJson(Object? value) {
    if (value == null) return const <CustomerContact>[];
    if (value is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local customer contacts.',
        code: 'invalid_customer_local_payload',
      );
    }
    return normalizeCustomerContacts(
      value.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid local customer contact payload.',
            code: 'invalid_customer_local_payload',
          );
        }
        final typeCode = _requiredString(item, 'typeCode');
        final typeLabel = _requiredString(item, 'typeLabel');
        final type =
            customerContactTypeFromCode(typeCode, label: typeLabel) ??
            CustomerContactType.custom(typeCode, label: typeLabel);
        return CustomerContact(
          id: _requiredString(item, 'id'),
          type: type,
          name: _requiredString(item, 'name'),
          role: _optionalString(item, 'role'),
          phone: _optionalString(item, 'phone'),
          email: _optionalString(item, 'email'),
          isPrimary: _requiredBool(item, 'isPrimary'),
        );
      }),
    );
  }

  Map<String, dynamic> _addressToJson(CustomerAddress address) {
    return <String, dynamic>{
      'id': address.id,
      'typeCode': address.type.code,
      'typeLabel': address.type.label,
      'street': address.street,
      if (address.number != null) 'number': address.number,
      if (address.complement != null) 'complement': address.complement,
      if (address.district != null) 'district': address.district,
      'city': address.city,
      'state': address.state,
      'zipCode': address.zipCode.digits,
      'country': address.country,
      'isPrimary': address.isPrimary,
    };
  }

  Map<String, dynamic> _contactToJson(CustomerContact contact) {
    return <String, dynamic>{
      'id': contact.id,
      'typeCode': contact.type.code,
      'typeLabel': contact.type.label,
      'name': contact.name,
      if (contact.role != null) 'role': contact.role,
      if (contact.phone != null) 'phone': contact.phone,
      if (contact.email != null) 'email': contact.email,
      'isPrimary': contact.isPrimary,
    };
  }

  bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is bool) return value;
    throw ValidationException(
      'Invalid local customer boolean field.',
      code: 'invalid_customer_local_payload',
      cause: field,
    );
  }
}
