import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/value_objects/crm_task_priority.dart';
import '../../domain/value_objects/crm_task_status.dart';
import '../../domain/value_objects/crm_task_sync_status.dart';

@lazySingleton
final class CrmTaskMapper {
  const CrmTaskMapper();

  CrmTaskPriority priorityToEntity(String value) {
    return switch (value) {
      'low' => CrmTaskPriority.low,
      'medium' => CrmTaskPriority.medium,
      'high' => CrmTaskPriority.high,
      _ => throw ValidationException(
        'Invalid CRM task priority.',
        code: 'invalid_crm_task_priority',
        cause: value,
      ),
    };
  }

  String priorityToDto(CrmTaskPriority priority) {
    return switch (priority) {
      CrmTaskPriority.low => 'low',
      CrmTaskPriority.medium => 'medium',
      CrmTaskPriority.high => 'high',
    };
  }

  CrmTaskStatus statusToEntity(String value) {
    return switch (value) {
      'pending' => CrmTaskStatus.pending,
      'completed' => CrmTaskStatus.completed,
      _ => throw ValidationException(
        'Invalid CRM task status.',
        code: 'invalid_crm_task_status',
        cause: value,
      ),
    };
  }

  String statusToDto(CrmTaskStatus status) {
    return switch (status) {
      CrmTaskStatus.pending => 'pending',
      CrmTaskStatus.completed => 'completed',
    };
  }

  CrmTaskSyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => CrmTaskSyncStatus.pending,
      'syncing' => CrmTaskSyncStatus.syncing,
      'synced' => CrmTaskSyncStatus.synced,
      'failed' => CrmTaskSyncStatus.failed,
      'conflict' => CrmTaskSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid CRM task sync status.',
        code: 'invalid_crm_task_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(CrmTaskSyncStatus status) {
    return switch (status) {
      CrmTaskSyncStatus.pending => 'pending',
      CrmTaskSyncStatus.syncing => 'syncing',
      CrmTaskSyncStatus.synced => 'synced',
      CrmTaskSyncStatus.failed => 'failed',
      CrmTaskSyncStatus.conflict => 'conflict',
    };
  }
}
