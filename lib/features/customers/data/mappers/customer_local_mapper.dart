import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../domain/customer_address_contact_rules.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/value_objects/cep.dart';
import '../../domain/value_objects/cnpj_cpf.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
import 'customer_mapper.dart';

/// Maps `Customer` (and its embedded addresses/contacts) to/from the Drift
/// rows backing the offline load (TASK-054).
///
/// Enum<->string conversions delegate to [CustomerMapper] so the local store
/// does not re-implement the same `type`/`status`/`syncStatus` codes already
/// used for the remote-facing DTO.
@lazySingleton
final class CustomerLocalMapper {
  const CustomerLocalMapper(this._customerMapper);

  final CustomerMapper _customerMapper;

  CustomersTableCompanion toCustomerRow(Customer customer) {
    return CustomersTableCompanion.insert(
      id: customer.id,
      organizationId: customer.organizationId,
      companyId: customer.companyId,
      type: _customerMapper.typeToDto(customer.type),
      document: customer.document.digits,
      legalName: Value(customer.legalName),
      tradeName: Value(customer.tradeName),
      fullName: Value(customer.fullName),
      stateRegistration: Value(customer.stateRegistration),
      primaryEmail: Value(customer.primaryEmail),
      primaryPhone: Value(customer.primaryPhone),
      status: _customerMapper.statusToDto(customer.status),
      classification: Value(customer.classification),
      potential: Value(customer.potential),
      segment: Value(customer.segment),
      originChannel: Value(customer.originChannel),
      responsibleSellerId: Value(customer.responsibleSellerId),
      registeredAt: customer.registeredAt.toUtc(),
      lastPurchaseAt: Value(customer.lastPurchaseAt?.toUtc()),
      commercialScore: Value(customer.commercialScore),
      healthScore: Value(customer.healthScore),
      healthScoreBand: Value(
        customer.healthScoreBand == null
            ? null
            : _customerMapper.healthScoreBandToDto(customer.healthScoreBand!),
      ),
      scoreUpdatedAt: Value(customer.scoreUpdatedAt?.toUtc()),
      scoreFormulaVersion: Value(customer.scoreFormulaVersion),
      scoreDataCoverage: Value(
        customer.scoreDataCoverage == null
            ? null
            : _customerMapper.scoreDataCoverageToDto(
                customer.scoreDataCoverage!,
              ),
      ),
      tagsJson: Value(customer.tags.isEmpty ? null : jsonEncode(customer.tags)),
      customFieldsJson: Value(
        customer.customFields.isEmpty
            ? null
            : jsonEncode(customer.customFields),
      ),
      createdAt: customer.createdAt.toUtc(),
      createdBy: customer.createdBy,
      updatedAt: customer.updatedAt.toUtc(),
      updatedBy: customer.updatedBy,
      deletedAt: Value(customer.deletedAt?.toUtc()),
      version: customer.version,
      syncStatus: _customerMapper.syncStatusToDto(customer.syncStatus),
    );
  }

  List<CustomerAddressesTableCompanion> toAddressRows(Customer customer) {
    final addresses = customer.addresses;
    return <CustomerAddressesTableCompanion>[
      for (var index = 0; index < addresses.length; index += 1)
        _toAddressRow(customer, addresses[index], position: index),
    ];
  }

  List<CustomerContactsTableCompanion> toContactRows(Customer customer) {
    final contacts = customer.contacts;
    return <CustomerContactsTableCompanion>[
      for (var index = 0; index < contacts.length; index += 1)
        _toContactRow(customer, contacts[index], position: index),
    ];
  }

  CustomerAddressesTableCompanion _toAddressRow(
    Customer customer,
    CustomerAddress address, {
    required int position,
  }) {
    return CustomerAddressesTableCompanion.insert(
      id: address.id,
      customerId: customer.id,
      organizationId: customer.organizationId,
      companyId: customer.companyId,
      typeCode: address.type.code,
      typeLabel: address.type.label,
      street: address.street,
      number: Value(address.number),
      complement: Value(address.complement),
      district: Value(address.district),
      city: address.city,
      state: address.state,
      zipCode: address.zipCode.digits,
      country: address.country,
      isPrimary: Value(address.isPrimary),
      position: Value(position),
    );
  }

  CustomerContactsTableCompanion _toContactRow(
    Customer customer,
    CustomerContact contact, {
    required int position,
  }) {
    return CustomerContactsTableCompanion.insert(
      id: contact.id,
      customerId: customer.id,
      organizationId: customer.organizationId,
      companyId: customer.companyId,
      typeCode: contact.type.code,
      typeLabel: contact.type.label,
      name: contact.name,
      role: Value(contact.role),
      phone: Value(contact.phone),
      email: Value(contact.email),
      isPrimary: Value(contact.isPrimary),
      position: Value(position),
    );
  }

  Customer fromRow(CustomerWithRelationsRow row) {
    final customerRow = row.customer;
    return Customer(
      id: customerRow.id,
      organizationId: customerRow.organizationId,
      companyId: customerRow.companyId,
      type: _customerMapper.typeToEntity(customerRow.type),
      document: CnpjCpf.parse(customerRow.document),
      legalName: customerRow.legalName,
      tradeName: customerRow.tradeName,
      fullName: customerRow.fullName,
      stateRegistration: customerRow.stateRegistration,
      primaryEmail: customerRow.primaryEmail,
      primaryPhone: customerRow.primaryPhone,
      status: _customerMapper.statusToEntity(customerRow.status),
      classification: customerRow.classification,
      potential: customerRow.potential,
      segment: customerRow.segment,
      originChannel: customerRow.originChannel,
      responsibleSellerId: customerRow.responsibleSellerId,
      registeredAt: customerRow.registeredAt.toUtc(),
      lastPurchaseAt: customerRow.lastPurchaseAt?.toUtc(),
      commercialScore: customerRow.commercialScore,
      healthScore: customerRow.healthScore,
      healthScoreBand: customerRow.healthScoreBand == null
          ? null
          : _customerMapper.healthScoreBandToEntity(
              customerRow.healthScoreBand!,
            ),
      scoreUpdatedAt: customerRow.scoreUpdatedAt?.toUtc(),
      scoreFormulaVersion: customerRow.scoreFormulaVersion,
      scoreDataCoverage: customerRow.scoreDataCoverage == null
          ? null
          : _customerMapper.scoreDataCoverageToEntity(
              customerRow.scoreDataCoverage!,
            ),
      addresses: normalizeCustomerAddresses(row.addresses.map(_addressFromRow)),
      contacts: normalizeCustomerContacts(row.contacts.map(_contactFromRow)),
      tags: _stringListFromJson(customerRow.tagsJson),
      customFields: _objectMapFromJson(customerRow.customFieldsJson),
      createdAt: customerRow.createdAt.toUtc(),
      createdBy: customerRow.createdBy,
      updatedAt: customerRow.updatedAt.toUtc(),
      updatedBy: customerRow.updatedBy,
      deletedAt: customerRow.deletedAt?.toUtc(),
      version: customerRow.version,
      syncStatus: _customerMapper.syncStatusToEntity(customerRow.syncStatus),
    );
  }

  CustomerAddress _addressFromRow(CustomerAddressesTableData row) {
    final type =
        customerAddressTypeFromCode(row.typeCode, label: row.typeLabel) ??
        CustomerAddressType.custom(row.typeCode, label: row.typeLabel);
    return CustomerAddress(
      id: row.id,
      type: type,
      street: row.street,
      number: row.number,
      complement: row.complement,
      district: row.district,
      city: row.city,
      state: row.state,
      zipCode: Cep.parse(row.zipCode),
      country: row.country,
      isPrimary: row.isPrimary,
    );
  }

  CustomerContact _contactFromRow(CustomerContactsTableData row) {
    final type =
        customerContactTypeFromCode(row.typeCode, label: row.typeLabel) ??
        CustomerContactType.custom(row.typeCode, label: row.typeLabel);
    return CustomerContact(
      id: row.id,
      type: type,
      name: row.name,
      role: row.role,
      phone: row.phone,
      email: row.email,
      isPrimary: row.isPrimary,
    );
  }

  List<String> _stringListFromJson(String? raw) {
    if (raw == null) return const <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic> || decoded.any((item) => item is! String)) {
      throw const ValidationException(
        'Invalid local customer tags payload.',
        code: 'invalid_customer_local_payload',
      );
    }
    return List<String>.unmodifiable(decoded.cast<String>());
  }

  Map<String, Object?> _objectMapFromJson(String? raw) {
    if (raw == null) return const <String, Object?>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local customer custom fields payload.',
        code: 'invalid_customer_local_payload',
      );
    }
    return Map<String, Object?>.unmodifiable(decoded);
  }
}
