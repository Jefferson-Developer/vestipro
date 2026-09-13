import 'package:injectable/injectable.dart';

import '../../domain/entities/push_device.dart';
import '../dtos/push_device_dto.dart';

/// Converts between [PushDevice] (domain) and [PushDeviceDto] (Firestore
/// document shape) — same thin, stateless mapper convention as every other
/// feature's `*Mapper` in this codebase.
@lazySingleton
final class PushDeviceMapper {
  const PushDeviceMapper();

  PushDevice toEntity(PushDeviceDto dto) {
    return PushDevice(
      id: dto.id,
      organizationId: dto.organizationId,
      userId: dto.userId,
      token: dto.token,
      platform: dto.platform,
      appVersion: dto.appVersion,
      createdAt: dto.createdAt,
      lastUsedAt: dto.lastUsedAt,
      deletedAt: dto.deletedAt,
    );
  }

  PushDeviceDto toDto(PushDevice entity) {
    return PushDeviceDto(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      token: entity.token,
      platform: entity.platform,
      appVersion: entity.appVersion,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
