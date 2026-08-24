import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/customer_address_contact_rules.dart';
import '../../domain/customer_identity_validator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/value_objects/cep.dart';
import '../../domain/value_objects/cnpj_cpf.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
import '../../domain/value_objects/customer_status.dart';
import '../../domain/value_objects/customer_sync_status.dart';
import '../../domain/value_objects/customer_type.dart';
import '../dtos/customer_dto.dart';

@lazySingleton
final class CustomerMapper {
  const CustomerMapper();

  Customer toEntity(CustomerDto dto) {
    final type = typeToEntity(dto.type);
    final document = CnpjCpf.parse(dto.document);
    final fieldErrors = validateCustomerIdentity(
      type: type,
      document: document,
      legalName: dto.legalName,
      fullName: dto.fullName,
      stateRegistration: dto.stateRegistration,
    );
    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid customer identity.',
        code: 'invalid_customer_identity',
        fieldErrors: fieldErrors,
      );
    }

    return Customer(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      type: type,
      document: document,
      legalName: dto.legalName,
      tradeName: dto.tradeName,
      fullName: dto.fullName,
      stateRegistration: dto.stateRegistration,
      primaryEmail: dto.primaryEmail,
      primaryPhone: dto.primaryPhone,
      status: statusToEntity(dto.status),
      classification: dto.classification,
      potential: dto.potential,
      segment: dto.segment,
      originChannel: dto.originChannel,
      responsibleSellerId: dto.responsibleSellerId,
      registeredAt: dto.registeredAt,
      lastPurchaseAt: dto.lastPurchaseAt,
      addresses: normalizeCustomerAddresses(
        dto.addresses.map(_addressToEntity),
      ),
      contacts: normalizeCustomerContacts(dto.contacts.map(_contactToEntity)),
      tags: dto.tags,
      customFields: dto.customFields,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  CustomerDto toDto(Customer entity) {
    return CustomerDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      type: typeToDto(entity.type),
      document: entity.document.digits,
      legalName: entity.legalName,
      tradeName: entity.tradeName,
      fullName: entity.fullName,
      stateRegistration: entity.stateRegistration,
      primaryEmail: entity.primaryEmail,
      primaryPhone: entity.primaryPhone,
      status: statusToDto(entity.status),
      classification: entity.classification,
      potential: entity.potential,
      segment: entity.segment,
      originChannel: entity.originChannel,
      responsibleSellerId: entity.responsibleSellerId,
      registeredAt: entity.registeredAt,
      lastPurchaseAt: entity.lastPurchaseAt,
      addresses: entity.addresses.map(_addressToDto).toList(growable: false),
      contacts: entity.contacts.map(_contactToDto).toList(growable: false),
      tags: entity.tags,
      customFields: entity.customFields,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  CustomerType typeToEntity(String value) {
    return switch (value) {
      'legalEntity' => CustomerType.legalEntity,
      'individual' => CustomerType.individual,
      _ => throw ValidationException(
        'Invalid customer type.',
        code: 'invalid_customer_type',
        cause: value,
      ),
    };
  }

  String typeToDto(CustomerType type) {
    return switch (type) {
      CustomerType.legalEntity => 'legalEntity',
      CustomerType.individual => 'individual',
    };
  }

  CustomerStatus statusToEntity(String value) {
    return switch (value) {
      'active' => CustomerStatus.active,
      'inactive' => CustomerStatus.inactive,
      'prospect' => CustomerStatus.prospect,
      'blocked' => CustomerStatus.blocked,
      _ => throw ValidationException(
        'Invalid customer status.',
        code: 'invalid_customer_status',
        cause: value,
      ),
    };
  }

  String statusToDto(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => 'active',
      CustomerStatus.inactive => 'inactive',
      CustomerStatus.prospect => 'prospect',
      CustomerStatus.blocked => 'blocked',
    };
  }

  CustomerSyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => CustomerSyncStatus.pending,
      'syncing' => CustomerSyncStatus.syncing,
      'synced' => CustomerSyncStatus.synced,
      'failed' => CustomerSyncStatus.failed,
      'conflict' => CustomerSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid customer sync status.',
        code: 'invalid_customer_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(CustomerSyncStatus status) {
    return switch (status) {
      CustomerSyncStatus.pending => 'pending',
      CustomerSyncStatus.syncing => 'syncing',
      CustomerSyncStatus.synced => 'synced',
      CustomerSyncStatus.failed => 'failed',
      CustomerSyncStatus.conflict => 'conflict',
    };
  }

  CustomerAddress _addressToEntity(CustomerAddressDto dto) {
    final type =
        customerAddressTypeFromCode(dto.typeCode, label: dto.typeLabel) ??
        CustomerAddressType.custom(dto.typeCode, label: dto.typeLabel);
    return CustomerAddress(
      id: dto.id,
      type: type,
      street: dto.street,
      number: dto.number,
      complement: dto.complement,
      district: dto.district,
      city: dto.city,
      state: dto.state,
      zipCode: Cep.parse(dto.zipCode),
      country: dto.country,
      isPrimary: dto.isPrimary,
    );
  }

  CustomerAddressDto _addressToDto(CustomerAddress address) {
    return CustomerAddressDto(
      id: address.id,
      typeCode: address.type.code,
      typeLabel: address.type.label,
      street: address.street,
      number: address.number,
      complement: address.complement,
      district: address.district,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode.digits,
      country: address.country,
      isPrimary: address.isPrimary,
    );
  }

  CustomerContact _contactToEntity(CustomerContactDto dto) {
    final type =
        customerContactTypeFromCode(dto.typeCode, label: dto.typeLabel) ??
        CustomerContactType.custom(dto.typeCode, label: dto.typeLabel);
    return CustomerContact(
      id: dto.id,
      type: type,
      name: dto.name,
      role: dto.role,
      phone: dto.phone,
      email: dto.email,
      isPrimary: dto.isPrimary,
    );
  }

  CustomerContactDto _contactToDto(CustomerContact contact) {
    return CustomerContactDto(
      id: contact.id,
      typeCode: contact.type.code,
      typeLabel: contact.type.label,
      name: contact.name,
      role: contact.role,
      phone: contact.phone,
      email: contact.email,
      isPrimary: contact.isPrimary,
    );
  }
}
