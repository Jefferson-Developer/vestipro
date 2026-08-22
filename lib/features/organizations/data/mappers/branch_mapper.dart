import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/branch.dart';
import '../../domain/value_objects/branch_address.dart';
import '../../domain/value_objects/branch_status.dart';
import '../../domain/value_objects/branch_type.dart';
import '../dtos/branch_address_dto.dart';
import '../dtos/branch_dto.dart';

@lazySingleton
final class BranchMapper {
  const BranchMapper();

  Branch toEntity(BranchDto dto) {
    return Branch(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      name: dto.name,
      type: typeToEntity(dto.type),
      address: dto.address == null ? null : addressToEntity(dto.address!),
      status: statusToEntity(dto.status),
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  BranchDto toDto(Branch entity) {
    return BranchDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      name: entity.name,
      type: typeToDto(entity.type),
      address: entity.address == null ? null : addressToDto(entity.address!),
      status: statusToDto(entity.status),
      version: entity.version,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }

  BranchAddress addressToEntity(BranchAddressDto dto) {
    return BranchAddress(
      street: dto.street,
      number: dto.number,
      complement: dto.complement,
      neighborhood: dto.neighborhood,
      city: dto.city,
      state: dto.state,
      postalCode: dto.postalCode,
      country: dto.country,
    );
  }

  BranchAddressDto addressToDto(BranchAddress address) {
    return BranchAddressDto(
      street: address.street,
      number: address.number,
      complement: address.complement,
      neighborhood: address.neighborhood,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
    );
  }

  BranchType typeToEntity(String value) {
    return switch (value) {
      'store' => BranchType.store,
      'showroom' => BranchType.showroom,
      'unit' => BranchType.unit,
      _ => throw ValidationException(
        'Invalid branch type.',
        code: 'invalid_branch_type',
        cause: value,
      ),
    };
  }

  String typeToDto(BranchType type) {
    return switch (type) {
      BranchType.store => 'store',
      BranchType.showroom => 'showroom',
      BranchType.unit => 'unit',
    };
  }

  BranchStatus statusToEntity(String value) {
    return switch (value) {
      'active' => BranchStatus.active,
      'suspended' => BranchStatus.suspended,
      _ => throw ValidationException(
        'Invalid branch status.',
        code: 'invalid_branch_status',
        cause: value,
      ),
    };
  }

  String statusToDto(BranchStatus status) {
    return switch (status) {
      BranchStatus.active => 'active',
      BranchStatus.suspended => 'suspended',
    };
  }
}
