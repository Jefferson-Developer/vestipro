import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/nps_aggregate_snapshot.dart';
import '../../domain/value_objects/nps_aggregate_scope.dart';
import '../dtos/nps_aggregate_snapshot_dto.dart';

@injectable
final class NpsAggregateSnapshotMapper {
  const NpsAggregateSnapshotMapper();

  NpsAggregateSnapshot toEntity(NpsAggregateSnapshotDto dto) {
    return NpsAggregateSnapshot(
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      scope: _scopeOf(dto.scope),
      scopeId: dto.scopeId,
      periodKey: dto.periodKey,
      promoters: dto.promoters,
      passives: dto.passives,
      detractors: dto.detractors,
      totalResponses: dto.totalResponses,
      npsScore: dto.npsScore,
      generatedAt: dto.generatedAt,
      version: dto.version,
    );
  }

  NpsAggregateScope _scopeOf(String code) => switch (code) {
    'seller' => NpsAggregateScope.seller,
    'team' => NpsAggregateScope.team,
    'organization' => NpsAggregateScope.organization,
    _ => throw ValidationException(
      'Unknown NPS aggregate scope "$code".',
      code: 'invalid_nps_aggregate_scope',
    ),
  };
}
