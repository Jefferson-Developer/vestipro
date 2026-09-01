import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/target.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../../domain/value_objects/target_period_granularity.dart';
import '../../domain/value_objects/target_status.dart';
import '../../domain/value_objects/target_sync_status.dart';
import '../dtos/target_dto.dart';

@lazySingleton
final class TargetMapper {
  const TargetMapper();

  Target toEntity(TargetDto dto) {
    return Target(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      dimensionType: dimensionTypeToEntity(dto.dimensionType),
      dimensionId: dto.dimensionId,
      periodGranularity: periodGranularityToEntity(dto.periodGranularity),
      startDate: dto.startDate,
      endDate: dto.endDate,
      metricType: metricTypeToEntity(dto.metricType),
      targetValue: dto.targetValue,
      currency: dto.currency,
      status: statusToEntity(dto.status),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  TargetDto toDto(Target entity) {
    return TargetDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      dimensionType: dimensionTypeToDto(entity.dimensionType),
      dimensionId: entity.dimensionId,
      periodGranularity: periodGranularityToDto(entity.periodGranularity),
      startDate: entity.startDate,
      endDate: entity.endDate,
      metricType: metricTypeToDto(entity.metricType),
      targetValue: entity.targetValue,
      currency: entity.currency,
      status: statusToDto(entity.status),
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  TargetDimensionType dimensionTypeToEntity(String value) {
    return switch (value) {
      'salesRep' => TargetDimensionType.salesRep,
      'team' => TargetDimensionType.team,
      'company' => TargetDimensionType.company,
      'collection' => TargetDimensionType.collection,
      'category' => TargetDimensionType.category,
      _ => throw ValidationException(
        'Invalid target dimension type.',
        code: 'invalid_target_dimension_type',
        cause: value,
      ),
    };
  }

  String dimensionTypeToDto(TargetDimensionType value) {
    return switch (value) {
      TargetDimensionType.salesRep => 'salesRep',
      TargetDimensionType.team => 'team',
      TargetDimensionType.company => 'company',
      TargetDimensionType.collection => 'collection',
      TargetDimensionType.category => 'category',
    };
  }

  TargetPeriodGranularity periodGranularityToEntity(String value) {
    return switch (value) {
      'monthly' => TargetPeriodGranularity.monthly,
      'quarterly' => TargetPeriodGranularity.quarterly,
      'yearly' => TargetPeriodGranularity.yearly,
      _ => throw ValidationException(
        'Invalid target period granularity.',
        code: 'invalid_target_period_granularity',
        cause: value,
      ),
    };
  }

  String periodGranularityToDto(TargetPeriodGranularity value) {
    return switch (value) {
      TargetPeriodGranularity.monthly => 'monthly',
      TargetPeriodGranularity.quarterly => 'quarterly',
      TargetPeriodGranularity.yearly => 'yearly',
    };
  }

  TargetMetricType metricTypeToEntity(String value) {
    return switch (value) {
      'revenue' => TargetMetricType.revenue,
      'quantity' => TargetMetricType.quantity,
      'positivacao' => TargetMetricType.positivacao,
      _ => throw ValidationException(
        'Invalid target metric type.',
        code: 'invalid_target_metric_type',
        cause: value,
      ),
    };
  }

  String metricTypeToDto(TargetMetricType value) {
    return switch (value) {
      TargetMetricType.revenue => 'revenue',
      TargetMetricType.quantity => 'quantity',
      TargetMetricType.positivacao => 'positivacao',
    };
  }

  TargetStatus statusToEntity(String value) {
    return switch (value) {
      'draft' => TargetStatus.draft,
      'active' => TargetStatus.active,
      'closed' => TargetStatus.closed,
      _ => throw ValidationException(
        'Invalid target status.',
        code: 'invalid_target_status',
        cause: value,
      ),
    };
  }

  String statusToDto(TargetStatus value) {
    return switch (value) {
      TargetStatus.draft => 'draft',
      TargetStatus.active => 'active',
      TargetStatus.closed => 'closed',
    };
  }

  TargetSyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => TargetSyncStatus.pending,
      'syncing' => TargetSyncStatus.syncing,
      'synced' => TargetSyncStatus.synced,
      'failed' => TargetSyncStatus.failed,
      'conflict' => TargetSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid target sync status.',
        code: 'invalid_target_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(TargetSyncStatus value) {
    return switch (value) {
      TargetSyncStatus.pending => 'pending',
      TargetSyncStatus.syncing => 'syncing',
      TargetSyncStatus.synced => 'synced',
      TargetSyncStatus.failed => 'failed',
      TargetSyncStatus.conflict => 'conflict',
    };
  }
}
