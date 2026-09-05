import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../opportunities/opportunities.dart';
import '../entities/funnel_dashboard_filters.dart';
import '../entities/funnel_dashboard_snapshot.dart';
import '../entities/funnel_dashboard_visibility.dart';
import '../services/funnel_dashboard_visibility_service.dart';
import 'build_funnel_dashboard_snapshot_use_case.dart';

@injectable
class LoadFunnelDashboardUseCase {
  const LoadFunnelDashboardUseCase(
    this._visibilityService,
    this._listStages,
    this._listOpportunities,
    this._buildSnapshot,
  );

  final FunnelDashboardVisibilityService _visibilityService;
  final ListPipelineStagesUseCase _listStages;
  final ListPipelineOpportunitiesUseCase _listOpportunities;
  final BuildFunnelDashboardSnapshotUseCase _buildSnapshot;

  Future<AppResult<FunnelDashboardSnapshot>> call({
    required String organizationId,
    required String userId,
    required FunnelDashboardFilters filters,
  }) async {
    final period = _monthRange(filters.monthKey);
    if (period == null) {
      return const AppFailure<FunnelDashboardSnapshot>(
        ValidationFailure(
          'Período inválido para o dashboard de funil.',
          fieldErrors: <String, String>{'monthKey': 'Use o formato YYYY-MM.'},
          code: 'invalid_funnel_dashboard_period',
        ),
      );
    }
    final visibilityResult = await _visibilityService.resolve(
      organizationId: organizationId,
      userId: userId,
    );
    if (visibilityResult case AppFailure<FunnelDashboardVisibility>(
      failure: final failure,
    )) {
      return AppFailure<FunnelDashboardSnapshot>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<FunnelDashboardVisibility>).value;
    if (visibility.mode == FunnelDashboardVisibilityMode.none ||
        (filters.sellerId != null &&
            !visibility.allowsSeller(filters.sellerId!))) {
      return const AppFailure<FunnelDashboardSnapshot>(
        PermissionFailure(
          'Você não pode consultar este escopo do funil.',
          code: 'funnel_dashboard_scope_forbidden',
        ),
      );
    }
    final sellerIds = filters.sellerId != null
        ? <String>{filters.sellerId!}
        : visibility.mode == FunnelDashboardVisibilityMode.organization
        ? const <String>{}
        : visibility.allowedSellerIds;
    final results = await Future.wait<Object>(<Future<Object>>[
      _listStages(organizationId: organizationId),
      _listOpportunities(
        organizationId: organizationId,
        companyId: filters.companyId,
        responsibleUserIds: sellerIds,
      ),
    ]);
    final stagesResult = results[0] as AppResult<List<PipelineStage>>;
    final opportunitiesResult = results[1] as AppResult<List<Opportunity>>;
    if (stagesResult case AppFailure<List<PipelineStage>>(
      failure: final failure,
    )) {
      return AppFailure<FunnelDashboardSnapshot>(failure);
    }
    if (opportunitiesResult case AppFailure<List<Opportunity>>(
      failure: final failure,
    )) {
      return AppFailure<FunnelDashboardSnapshot>(failure);
    }
    final visible = (opportunitiesResult as AppSuccess<List<Opportunity>>).value
        .where((item) {
          if (item.status != OpportunityStatus.lost) return true;
          final closedAt = item.closedAt;
          return closedAt != null &&
              !closedAt.isBefore(period.$1) &&
              !closedAt.isAfter(period.$2);
        })
        .toList(growable: false);
    return AppSuccess<FunnelDashboardSnapshot>(
      _buildSnapshot(
        stages: (stagesResult as AppSuccess<List<PipelineStage>>).value,
        opportunities: visible,
        now: DateTime.now(),
        lossStageId: filters.lossStageId,
      ),
    );
  }

  (DateTime, DateTime)? _monthRange(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return (
      DateTime.utc(year, month),
      DateTime.utc(year, month + 1).subtract(const Duration(microseconds: 1)),
    );
  }
}
