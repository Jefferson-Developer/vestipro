import 'package:injectable/injectable.dart';

import '../../domain/entities/stock_alert.dart';
import '../../domain/value_objects/stock_alert_level.dart';
import '../../domain/value_objects/stock_alert_transition_type.dart';
import '../dtos/stock_alert_dto.dart';

@lazySingleton
final class StockAlertMapper {
  const StockAlertMapper();

  StockAlert toEntity(StockAlertDto dto) {
    return StockAlert(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      productId: dto.productId,
      variantId: dto.variantId,
      warehouseId: dto.warehouseId,
      level: _parseLevel(dto.level),
      previousLevel: _parseNullableLevel(dto.previousLevel),
      currentLevel: _parseNullableLevel(dto.currentLevel),
      transitionType: _parseTransitionType(dto.transitionType),
      sellableQuantity: dto.sellableQuantity,
      thresholdQuantity: dto.thresholdQuantity,
      triggeredAt: dto.triggeredAt,
      ruleId: dto.ruleId,
      notificationEventId: dto.notificationEventId,
    );
  }

  StockAlertDto toDto(StockAlert entity) {
    return StockAlertDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      productId: entity.productId,
      variantId: entity.variantId,
      warehouseId: entity.warehouseId,
      level: entity.level.code,
      previousLevel: entity.previousLevel?.code,
      currentLevel: entity.currentLevel?.code,
      transitionType: entity.transitionType.code,
      sellableQuantity: entity.sellableQuantity,
      thresholdQuantity: entity.thresholdQuantity,
      triggeredAt: entity.triggeredAt,
      ruleId: entity.ruleId,
      notificationEventId: entity.notificationEventId,
    );
  }

  StockAlertLevel _parseLevel(String raw) {
    return switch (raw) {
      'low' => StockAlertLevel.low,
      'critical' => StockAlertLevel.critical,
      _ => throw ArgumentError.value(raw, 'raw', 'Unknown stock alert level.'),
    };
  }

  StockAlertLevel? _parseNullableLevel(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return _parseLevel(raw);
  }

  StockAlertTransitionType _parseTransitionType(String raw) {
    return switch (raw) {
      'entered' => StockAlertTransitionType.entered,
      'escalated' => StockAlertTransitionType.escalated,
      'deescalated' => StockAlertTransitionType.deescalated,
      'recovered' => StockAlertTransitionType.recovered,
      _ => throw ArgumentError.value(
        raw,
        'raw',
        'Unknown stock alert transition type.',
      ),
    };
  }
}
