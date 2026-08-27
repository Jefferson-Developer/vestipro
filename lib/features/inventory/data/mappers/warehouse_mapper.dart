import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/value_objects/warehouse_type.dart';
import '../dtos/warehouse_dto.dart';

@lazySingleton
final class WarehouseMapper {
  const WarehouseMapper();

  Warehouse toEntity(WarehouseDto dto) {
    return Warehouse(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      branchId: dto.branchId,
      code: dto.code,
      name: dto.name,
      type: typeToEntity(dto.type),
      isActive: dto.isActive,
      priority: dto.priority,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: dto.syncStatus,
    );
  }

  WarehouseDto toDto(Warehouse entity) {
    return WarehouseDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      branchId: entity.branchId,
      code: entity.code,
      name: entity.name,
      type: typeToDto(entity.type),
      isActive: entity.isActive,
      priority: entity.priority,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
      version: entity.version,
      syncStatus: entity.syncStatus,
    );
  }

  WarehouseType typeToEntity(String value) {
    return switch (value) {
      'headquarters' => WarehouseType.headquarters,
      'distributionCenter' => WarehouseType.distributionCenter,
      'store' => WarehouseType.store,
      'consigned' => WarehouseType.consigned,
      _ => throw ValidationException(
        'Invalid warehouse type.',
        code: 'invalid_warehouse_type',
        cause: value,
      ),
    };
  }

  String typeToDto(WarehouseType value) {
    return switch (value) {
      WarehouseType.headquarters => 'headquarters',
      WarehouseType.distributionCenter => 'distributionCenter',
      WarehouseType.store => 'store',
      WarehouseType.consigned => 'consigned',
    };
  }
}
