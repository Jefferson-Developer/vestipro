import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/customer_address_contact_rules.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/customer_form_draft.dart';
import '../../domain/value_objects/cep.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
import '../../domain/value_objects/customer_type.dart';
import '../dtos/customer_dto.dart';
import '../dtos/customer_form_draft_dto.dart';

@lazySingleton
final class CustomerFormDraftMapper {
  const CustomerFormDraftMapper();

  CustomerFormDraft toEntity(CustomerFormDraftDto dto) {
    return CustomerFormDraft(
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      userId: dto.userId,
      type: _typeToEntity(dto.type),
      document: dto.document,
      legalName: dto.legalName,
      tradeName: dto.tradeName,
      fullName: dto.fullName,
      stateRegistration: dto.stateRegistration,
      primaryEmail: dto.primaryEmail,
      primaryPhone: dto.primaryPhone,
      classification: dto.classification,
      potential: dto.potential,
      responsibleSellerId: dto.responsibleSellerId,
      addresses: normalizeCustomerAddresses(
        dto.addresses.map(_addressToEntity),
      ),
      contacts: normalizeCustomerContacts(dto.contacts.map(_contactToEntity)),
      savedAt: dto.savedAt,
    );
  }

  CustomerFormDraftDto toDto(CustomerFormDraft entity) {
    return CustomerFormDraftDto(
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      userId: entity.userId,
      type: _typeToDto(entity.type),
      document: entity.document,
      legalName: entity.legalName,
      tradeName: entity.tradeName,
      fullName: entity.fullName,
      stateRegistration: entity.stateRegistration,
      primaryEmail: entity.primaryEmail,
      primaryPhone: entity.primaryPhone,
      classification: entity.classification,
      potential: entity.potential,
      responsibleSellerId: entity.responsibleSellerId,
      addresses: entity.addresses.map(_addressToDto).toList(growable: false),
      contacts: entity.contacts.map(_contactToDto).toList(growable: false),
      savedAt: entity.savedAt,
    );
  }

  CustomerType _typeToEntity(String value) {
    return switch (value) {
      'legalEntity' => CustomerType.legalEntity,
      'individual' => CustomerType.individual,
      _ => throw ValidationException(
        'Invalid customer draft type.',
        code: 'invalid_customer_draft_type',
        cause: value,
      ),
    };
  }

  String _typeToDto(CustomerType type) {
    return switch (type) {
      CustomerType.legalEntity => 'legalEntity',
      CustomerType.individual => 'individual',
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
