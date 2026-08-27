import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/warehouse.dart';
import 'warehouse_mapper.dart';

@lazySingleton
final class WarehouseLocalMapper {
  const WarehouseLocalMapper(this._mapper);

  final WarehouseMapper _mapper;

  WarehousesTableCompanion toRow(Warehouse warehouse) {
    return WarehousesTableCompanion.insert(
      id: warehouse.id,
      organizationId: warehouse.organizationId,
      companyId: warehouse.companyId,
      branchId: Value(warehouse.branchId),
      code: warehouse.code,
      name: warehouse.name,
      type: _mapper.typeToDto(warehouse.type),
      isActive: warehouse.isActive,
      priority: Value(warehouse.priority),
      createdAt: warehouse.createdAt,
      createdBy: warehouse.createdBy,
      updatedAt: warehouse.updatedAt,
      updatedBy: warehouse.updatedBy,
      deletedAt: Value(warehouse.deletedAt),
      version: warehouse.version,
      syncStatus: warehouse.syncStatus,
    );
  }

  Warehouse fromRow(WarehousesTableData row) {
    return Warehouse(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      branchId: row.branchId,
      code: row.code,
      name: row.name,
      type: _mapper.typeToEntity(row.type),
      isActive: row.isActive,
      priority: row.priority,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
      version: row.version,
      syncStatus: row.syncStatus,
    );
  }
}
