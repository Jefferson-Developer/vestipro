import '../dtos/push_device_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/pushDevices/{id}` documents (TASK-150).
/// [FirestorePushDeviceDataSource] is the only implementation today.
abstract interface class PushDeviceDataSource {
  Future<void> upsert(PushDeviceDto dto);

  Future<void> softDelete({
    required String organizationId,
    required String id,
    required DateTime deletedAt,
  });
}
