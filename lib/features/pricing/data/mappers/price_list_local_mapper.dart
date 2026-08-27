import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/price_list.dart';
import 'price_list_mapper.dart';

/// Maps [PriceList] to/from the Drift rows backing its offline cache
/// (`PriceListsTable`, TASK-083). Enum<->string conversions delegate to
/// [PriceListMapper] so this local store does not reimplement the same
/// `status`/`scope`/`syncStatus` codes already used for the remote-facing
/// DTO — same precedent `CustomerLocalMapper` already follows.
@lazySingleton
final class PriceListLocalMapper {
  const PriceListLocalMapper(this._mapper);

  final PriceListMapper _mapper;

  PriceListsTableCompanion toRow(PriceList priceList) {
    return PriceListsTableCompanion.insert(
      id: priceList.id,
      organizationId: priceList.organizationId,
      companyId: priceList.companyId,
      name: priceList.name,
      currency: priceList.currency,
      validFrom: priceList.validFrom.toUtc(),
      validTo: Value(priceList.validTo?.toUtc()),
      status: _mapper.statusToDto(priceList.status),
      scope: _mapper.scopeToDto(priceList.scope),
      scopeValue: Value(priceList.scopeValue),
      priority: Value(priceList.priority),
      createdAt: priceList.createdAt.toUtc(),
      createdBy: priceList.createdBy,
      updatedAt: priceList.updatedAt.toUtc(),
      updatedBy: priceList.updatedBy,
      deletedAt: Value(priceList.deletedAt?.toUtc()),
      version: priceList.version,
      syncStatus: _mapper.syncStatusToDto(priceList.syncStatus),
    );
  }

  PriceList fromRow(PriceListsTableData row) {
    return PriceList(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      name: row.name,
      currency: row.currency,
      validFrom: row.validFrom.toUtc(),
      validTo: row.validTo?.toUtc(),
      status: _mapper.statusToEntity(row.status),
      scope: _mapper.scopeToEntity(row.scope),
      scopeValue: row.scopeValue,
      priority: row.priority,
      createdAt: row.createdAt.toUtc(),
      createdBy: row.createdBy,
      updatedAt: row.updatedAt.toUtc(),
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt?.toUtc(),
      version: row.version,
      syncStatus: _mapper.syncStatusToEntity(row.syncStatus),
    );
  }
}
