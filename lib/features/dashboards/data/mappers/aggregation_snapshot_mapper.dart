import '../../domain/entities/aggregation_snapshot.dart';
import '../dtos/aggregation_snapshot_dto.dart';

/// Not yet registered in the DI container (`@injectable`/`@LazySingleton`)
/// — no presentation-layer consumer exists yet for `lib/features/dashboards`
/// (that starts at TASK-134, the first dashboard task). Registering it plus
/// running `build_runner` to regenerate `injection.config.dart` is
/// deferred to whichever task first wires a BLoC to
/// `AggregationRepository`, so this task does not touch generated DI code
/// with zero real consumers to justify it.
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
