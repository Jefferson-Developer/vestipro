import 'package:injectable/injectable.dart';

import '../../domain/entities/aggregation_snapshot.dart';
import '../dtos/aggregation_snapshot_dto.dart';

/// Registered in the DI container starting with TASK-134
/// (`ExecutiveDashboardBloc`, the first presentation-layer consumer of
/// `AggregationRepository`).
@injectable
final class AggregationSnapshotMapper {
  const AggregationSnapshotMapper();

  AggregationSnapshot toEntity(AggregationSnapshotDto dto) {
    return AggregationSnapshot(
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      dimension: dto.dimension,
      scopeId: dto.scopeId,
      periodKey: dto.periodKey,
      revenueGross: dto.revenueGross,
      revenueNet: dto.revenueNet,
      discountAmount: dto.discountAmount,
      orderCount: dto.orderCount,
      itemQuantity: dto.itemQuantity,
      labels: Map<String, String>.unmodifiable(dto.labels),
      generatedAt: dto.generatedAt,
      version: dto.version,
    );
  }
}
