import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/value_objects/crm_activity_sync_status.dart';
import '../../domain/value_objects/crm_activity_type.dart';

@lazySingleton
final class CrmActivityMapper {
  const CrmActivityMapper();

  CrmActivityType typeToEntity(String value) {
    return switch (value) {
      'phone_call' => CrmActivityType.phoneCall,
      'visit' => CrmActivityType.visit,
      'meeting' => CrmActivityType.meeting,
      'message' => CrmActivityType.message,
      'note' => CrmActivityType.note,
      _ => throw ValidationException(
        'Invalid CRM activity type.',
        code: 'invalid_crm_activity_type',
        cause: value,
      ),
    };
  }

  String typeToDto(CrmActivityType type) => type.analyticsCode;

  CrmActivitySyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => CrmActivitySyncStatus.pending,
      'syncing' => CrmActivitySyncStatus.syncing,
      'synced' => CrmActivitySyncStatus.synced,
      'failed' => CrmActivitySyncStatus.failed,
      'conflict' => CrmActivitySyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid CRM activity sync status.',
        code: 'invalid_crm_activity_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(CrmActivitySyncStatus status) {
    return switch (status) {
      CrmActivitySyncStatus.pending => 'pending',
      CrmActivitySyncStatus.syncing => 'syncing',
      CrmActivitySyncStatus.synced => 'synced',
      CrmActivitySyncStatus.failed => 'failed',
      CrmActivitySyncStatus.conflict => 'conflict',
    };
  }
}
