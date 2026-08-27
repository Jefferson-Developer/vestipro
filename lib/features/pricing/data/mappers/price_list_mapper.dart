import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/price_list.dart';
import '../../domain/value_objects/price_list_scope_type.dart';
import '../../domain/value_objects/price_list_status.dart';
import '../../domain/value_objects/price_list_sync_status.dart';
import '../dtos/price_list_dto.dart';

/// Maps [PriceList] to/from [PriceListDto] (EPIC-11, TASK-083), the only
/// place enum<->string codes for `status`/`scope`/`syncStatus` are decided,
/// so no other layer reimplements them.
@lazySingleton
final class PriceListMapper {
  const PriceListMapper();

  PriceListDto toDto(PriceList priceList) {
    return PriceListDto(
      id: priceList.id,
      organizationId: priceList.organizationId,
      companyId: priceList.companyId,
      name: priceList.name,
      currency: priceList.currency,
      validFrom: priceList.validFrom,
      validTo: priceList.validTo,
      status: statusToDto(priceList.status),
      scope: scopeToDto(priceList.scope),
      scopeValue: priceList.scopeValue,
      priority: priceList.priority,
      createdAt: priceList.createdAt,
      createdBy: priceList.createdBy,
      updatedAt: priceList.updatedAt,
      updatedBy: priceList.updatedBy,
      deletedAt: priceList.deletedAt,
      version: priceList.version,
      syncStatus: syncStatusToDto(priceList.syncStatus),
    );
  }

  PriceList toEntity(PriceListDto dto) {
    return PriceList(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      name: dto.name,
      currency: dto.currency,
      validFrom: dto.validFrom,
      validTo: dto.validTo,
      status: statusToEntity(dto.status),
      scope: scopeToEntity(dto.scope),
      scopeValue: dto.scopeValue,
      priority: dto.priority,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  String statusToDto(PriceListStatus status) {
    return switch (status) {
      PriceListStatus.draft => 'draft',
      PriceListStatus.active => 'active',
      PriceListStatus.expired => 'expired',
      PriceListStatus.archived => 'archived',
    };
  }

  PriceListStatus statusToEntity(String raw) {
    return switch (raw) {
      'draft' => PriceListStatus.draft,
      'active' => PriceListStatus.active,
      'expired' => PriceListStatus.expired,
      'archived' => PriceListStatus.archived,
      _ => throw ValidationException(
        'Invalid price list status "$raw".',
        code: 'invalid_price_list_status',
      ),
    };
  }

  String scopeToDto(PriceListScopeType scope) {
    return switch (scope) {
      PriceListScopeType.company => 'company',
      PriceListScopeType.channel => 'channel',
      PriceListScopeType.segment => 'segment',
    };
  }

  PriceListScopeType scopeToEntity(String raw) {
    return switch (raw) {
      'company' => PriceListScopeType.company,
      'channel' => PriceListScopeType.channel,
      'segment' => PriceListScopeType.segment,
      _ => throw ValidationException(
        'Invalid price list scope "$raw".',
        code: 'invalid_price_list_scope',
      ),
    };
  }

  String syncStatusToDto(PriceListSyncStatus syncStatus) {
    return switch (syncStatus) {
      PriceListSyncStatus.pending => 'pending',
      PriceListSyncStatus.syncing => 'syncing',
      PriceListSyncStatus.synced => 'synced',
      PriceListSyncStatus.failed => 'failed',
      PriceListSyncStatus.conflict => 'conflict',
    };
  }

  PriceListSyncStatus syncStatusToEntity(String raw) {
    return switch (raw) {
      'pending' => PriceListSyncStatus.pending,
      'syncing' => PriceListSyncStatus.syncing,
      'synced' => PriceListSyncStatus.synced,
      'failed' => PriceListSyncStatus.failed,
      'conflict' => PriceListSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid price list syncStatus "$raw".',
        code: 'invalid_price_list_sync_status',
      ),
    };
  }
}
