import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/value_objects/opportunity_status.dart';
import '../../domain/value_objects/opportunity_sync_status.dart';
import '../dtos/opportunity_dto.dart';

@lazySingleton
final class OpportunityMapper {
  const OpportunityMapper();

  Opportunity toEntity(OpportunityDto dto) {
    return Opportunity(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      title: dto.title,
      description: dto.description,
      customerId: dto.customerId,
      leadId: dto.leadId,
      estimatedValue: dto.estimatedValue,
      probability: dto.probability,
      revenueForecast: dto.revenueForecast,
      responsibleUserId: dto.responsibleUserId,
      stageId: dto.stageId,
      status: statusToEntity(dto.status),
      expectedCloseDate: dto.expectedCloseDate,
      wonReason: dto.wonReason,
      lostReason: dto.lostReason,
      closedAt: dto.closedAt,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  OpportunityDto toDto(Opportunity entity) {
    return OpportunityDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      title: entity.title,
      description: entity.description,
      customerId: entity.customerId,
      leadId: entity.leadId,
      estimatedValue: entity.estimatedValue,
      probability: entity.probability,
      revenueForecast: entity.revenueForecast,
      responsibleUserId: entity.responsibleUserId,
      stageId: entity.stageId,
      status: statusToDto(entity.status),
      expectedCloseDate: entity.expectedCloseDate,
      wonReason: entity.wonReason,
      lostReason: entity.lostReason,
      closedAt: entity.closedAt,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  OpportunityStatus statusToEntity(String value) {
    return switch (value) {
      'open' => OpportunityStatus.open,
      'won' => OpportunityStatus.won,
      'lost' => OpportunityStatus.lost,
      _ => throw ValidationException(
        'Invalid opportunity status.',
        code: 'invalid_opportunity_status',
        cause: value,
      ),
    };
  }

  String statusToDto(OpportunityStatus status) {
    return switch (status) {
      OpportunityStatus.open => 'open',
      OpportunityStatus.won => 'won',
      OpportunityStatus.lost => 'lost',
    };
  }

  OpportunitySyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => OpportunitySyncStatus.pending,
      'syncing' => OpportunitySyncStatus.syncing,
      'synced' => OpportunitySyncStatus.synced,
      'failed' => OpportunitySyncStatus.failed,
      'conflict' => OpportunitySyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid opportunity sync status.',
        code: 'invalid_opportunity_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(OpportunitySyncStatus status) {
    return switch (status) {
      OpportunitySyncStatus.pending => 'pending',
      OpportunitySyncStatus.syncing => 'syncing',
      OpportunitySyncStatus.synced => 'synced',
      OpportunitySyncStatus.failed => 'failed',
      OpportunitySyncStatus.conflict => 'conflict',
    };
  }
}
