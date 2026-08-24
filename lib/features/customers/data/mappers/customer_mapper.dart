import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/customer_identity_validator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/value_objects/cnpj_cpf.dart';
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
}
