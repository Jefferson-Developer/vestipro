import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../insights/insights.dart';
import '../../../organizations/organizations.dart';
import '../../../targets/targets.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/targets_dashboard_filters.dart';
import '../entities/targets_dashboard_snapshot.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';

/// Builds the targets hierarchy from the same server-side seller snapshots
/// consumed by BI/insights. No raw order is ever read here.
@injectable
class LoadTargetsDashboardUseCase {
  const LoadTargetsDashboardUseCase(
    this._aggregations,
    this._targets,
    this._teams,
    this._visibility,
    this._insights,
    this._ranking,
  );

  final AggregationRepository _aggregations;
  final TargetRepository _targets;
  final TeamRepository _teams;
  final TargetVisibilityService _visibility;
  final InsightRepository _insights;
  final RankingCalculationService _ranking;

  Future<AppResult<TargetsDashboardSnapshot>> call({
    required String organizationId,
    required String userId,
    required TargetsDashboardFilters filters,
    DateTime? now,
  }) async {
    final asOf = (now ?? DateTime.now()).toUtc();
    final visibilityResult = await _visibility.resolve(
      organizationId: organizationId,
      companyId: filters.companyId,
      userId: userId,
    );
    if (visibilityResult case AppFailure<TargetVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<TargetsDashboardSnapshot>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<TargetVisibilityFilter>).value;
    if (!visibility.canViewAny) {
      return const AppFailure<TargetsDashboardSnapshot>(
        PermissionFailure(
          'User cannot view targets dashboard.',
          code: 'targets_dashboard_forbidden',
        ),
      );
    }

    final teamsResult = await _teams.listByOrganization(organizationId);
    if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
      return AppFailure<TargetsDashboardSnapshot>(failure);
    }
    var teams = (teamsResult as AppSuccess<List<Team>>).value
        .where(
          (team) =>
              team.deletedAt == null &&
              (team.companyId == null || team.companyId == filters.companyId),
        )
        .toList();
    if (visibility.mode == TargetVisibilityMode.teams) {
      teams = teams
          .where((team) => visibility.teamIds.contains(team.id))
          .toList();
    } else if (visibility.mode == TargetVisibilityMode.ownOnly) {
      teams = teams.where((team) => team.memberIds.contains(userId)).toList();
    }
    if (filters.teamId != null) {
      if (!visibility.canView(
        dimensionType: TargetDimensionType.team,
        dimensionId: filters.teamId!,
      )) {
        return const AppFailure<TargetsDashboardSnapshot>(
          PermissionFailure(
            'Team is outside the visible target scope.',
            code: 'targets_dashboard_team_forbidden',
          ),
        );
      }
      teams = teams.where((team) => team.id == filters.teamId).toList();
    }

    final aggregatesResult = await _aggregations.listByPeriod(
      organizationId: organizationId,
      dimension: AggregationDimension.sellerMonthly,
      companyId: filters.companyId,
      periodKey: filters.monthKey,
      limit: 500,
    );
    if (aggregatesResult case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      return AppFailure<TargetsDashboardSnapshot>(failure);
    }
    var aggregates =
        (aggregatesResult as AppSuccess<List<AggregationSnapshot>>).value;
    final visibleSellerIds = switch (visibility.mode) {
      TargetVisibilityMode.allOrganization =>
        aggregates.map((item) => item.scopeId).toSet(),
      TargetVisibilityMode.teams => visibility.teamMemberIds,
      TargetVisibilityMode.ownOnly => <String>{userId},
      TargetVisibilityMode.none => const <String>{},
    };
    aggregates = aggregates
        .where((item) => visibleSellerIds.contains(item.scopeId))
        .toList();
    if (filters.sellerId != null) {
      if (!visibility.canView(
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: filters.sellerId!,
      )) {
        return const AppFailure<TargetsDashboardSnapshot>(
          PermissionFailure(
            'Seller is outside the visible target scope.',
            code: 'targets_dashboard_seller_forbidden',
          ),
        );
      }
      aggregates = aggregates
          .where((item) => item.scopeId == filters.sellerId)
          .toList();
    }

    final riskSellerIds = await _riskSellerIds(
      organizationId,
      userId,
      visibility,
    );
    final sellerRowsById = <String, TargetsDashboardRow>{};
    final participants = <RankingParticipant>[];
    for (final aggregate in aggregates) {
      final targetResult = await _activeTarget(
        organizationId: organizationId,
        companyId: filters.companyId,
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: aggregate.scopeId,
        filters: filters,
      );
      if (targetResult case AppFailure<Target?>(failure: final failure)) {
        return AppFailure<TargetsDashboardSnapshot>(failure);
      }
      final target = (targetResult as AppSuccess<Target?>).value;
      final metric = target == null
          ? null
          : _metric(target, aggregate.revenueNet, asOf);
      final label = aggregate.labels['sellerName'] ?? aggregate.scopeId;
      sellerRowsById[aggregate.scopeId] = TargetsDashboardRow(
        id: aggregate.scopeId,
        label: label,
        level: TargetsDashboardLevel.seller,
        metric: metric,
        isBelowTargetInsightActive: riskSellerIds.contains(aggregate.scopeId),
      );
      if (target != null) {
        participants.add(
          RankingParticipant(
            dimensionId: aggregate.scopeId,
            displayName: label,
            targetValue: target.targetValue,
            realizedValue: aggregate.revenueNet,
          ),
        );
      }
    }

    final teamRows = <TargetsDashboardRow>[];
    final assignedSellerIds = <String>{};
    for (final team in teams) {
      final children = <TargetsDashboardRow>[
        for (final sellerId in team.memberIds) ?sellerRowsById[sellerId],
      ]..sort((a, b) => a.label.compareTo(b.label));
      assignedSellerIds.addAll(children.map((row) => row.id));
      final realized = children.fold<double>(
        0,
        (sum, row) => sum + (row.metric?.realizedValue ?? 0),
      );
      Target? target;
      if (visibility.mode != TargetVisibilityMode.ownOnly) {
        final targetResult = await _activeTarget(
          organizationId: organizationId,
          companyId: filters.companyId,
          dimensionType: TargetDimensionType.team,
          dimensionId: team.id,
          filters: filters,
        );
        if (targetResult case AppFailure<Target?>(failure: final failure)) {
          return AppFailure<TargetsDashboardSnapshot>(failure);
        }
        target = (targetResult as AppSuccess<Target?>).value;
      }
      teamRows.add(
        TargetsDashboardRow(
          id: team.id,
          label: team.name,
          level: TargetsDashboardLevel.team,
          metric: target == null ? null : _metric(target, realized, asOf),
          children: children,
          isBelowTargetInsightActive: children.any(
            (row) => row.isBelowTargetInsightActive,
          ),
        ),
      );
    }
    // Admins can still see sellers that have no team assignment.
    if (visibility.mode == TargetVisibilityMode.allOrganization) {
      final unassigned = sellerRowsById.values
          .where((row) => !assignedSellerIds.contains(row.id))
          .toList();
      if (unassigned.isNotEmpty) {
        teamRows.add(
          TargetsDashboardRow(
            id: 'unassigned',
            label: 'Sem equipe',
            level: TargetsDashboardLevel.team,
            metric: null,
            children: unassigned,
            isBelowTargetInsightActive: unassigned.any(
              (row) => row.isBelowTargetInsightActive,
            ),
          ),
        );
      }
    }

    Target? companyTarget;
    if (visibility.mode == TargetVisibilityMode.allOrganization) {
      final companyTargetResult = await _activeTarget(
        organizationId: organizationId,
        companyId: filters.companyId,
        dimensionType: TargetDimensionType.company,
        dimensionId: filters.companyId,
        filters: filters,
      );
      if (companyTargetResult case AppFailure<Target?>(
        failure: final failure,
      )) {
        return AppFailure<TargetsDashboardSnapshot>(failure);
      }
      companyTarget = (companyTargetResult as AppSuccess<Target?>).value;
    }
    final totalRealized = aggregates.fold<double>(
      0,
      (sum, item) => sum + item.revenueNet,
    );
    final ranking = _ranking.compute(
      participants: participants,
      currentUserDimensionId: userId,
      accessLevel: visibility.mode == TargetVisibilityMode.ownOnly
          ? RankingAccessLevel.relativePositionOnly
          : RankingAccessLevel.full,
    );
    final generatedDates = aggregates.map((item) => item.generatedAt).toList()
      ..sort();
    return AppSuccess<TargetsDashboardSnapshot>(
      TargetsDashboardSnapshot(
        root: TargetsDashboardRow(
          id: filters.companyId,
          label: 'Organização',
          level: TargetsDashboardLevel.organization,
          metric: companyTarget == null
              ? null
              : _metric(companyTarget, totalRealized, asOf),
          children: teamRows,
          isBelowTargetInsightActive: teamRows.any(
            (row) => row.isBelowTargetInsightActive,
          ),
        ),
        ranking: ranking.entries,
        availableTeamIds: teams.map((team) => team.id).toList(),
        availableSellerIds: aggregates.map((item) => item.scopeId).toList(),
        generatedAt: generatedDates.isEmpty ? null : generatedDates.first,
        isFromLocalCache: aggregates.any((item) => item.isFromLocalCache),
      ),
    );
  }

  Future<AppResult<Target?>> _activeTarget({
    required String organizationId,
    required String companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    required TargetsDashboardFilters filters,
  }) async {
    final result = await _targets.listByDimension(
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      metricType: TargetMetricType.revenue,
    );
    if (result case AppFailure<List<Target>>(failure: final failure)) {
      return AppFailure<Target?>(failure);
    }
    final matches =
        (result as AppSuccess<List<Target>>).value
            .where(
              (target) =>
                  target.status == TargetStatus.active &&
                  target.deletedAt == null &&
                  target.startDate.isBefore(filters.periodEnd) &&
                  target.endDate.isAfter(filters.periodStart),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return AppSuccess<Target?>(matches.firstOrNull);
  }

  TargetsDashboardMetric _metric(Target target, double realized, DateTime now) {
    final totalDays = target.endDate
        .difference(target.startDate)
        .inDays
        .clamp(1, 100000);
    final elapsedDays = now
        .difference(target.startDate)
        .inDays
        .clamp(0, totalDays);
    // This is deliberately the TASK-131 snapshot primitive: projection shown
    // here and projection used by the below-target insight share one formula.
    final insightSnapshot = InsightSalesRepBelowTargetSnapshot(
      organizationId: target.organizationId,
      companyId: target.companyId,
      recipientUserId: '',
      sellerId: target.dimensionId,
      sellerName: '',
      periodLabel: '',
      periodStartDate: target.startDate,
      periodEndDate: target.endDate,
      targetValue: target.targetValue,
      realizedValue: realized,
      elapsedRelevantDays: elapsedDays,
      totalRelevantDays: totalDays,
    );
    final achievement = target.targetValue <= 0
        ? (realized > 0 ? 100.0 : 0.0)
        : realized / target.targetValue * 100;
    return TargetsDashboardMetric(
      targetValue: target.targetValue,
      realizedValue: realized,
      achievementPercentage: achievement,
      projectedValue: insightSnapshot.projectedValue,
      projectedAchievementPercentage:
          insightSnapshot.projectedAchievementPercentage,
    );
  }

  Future<Set<String>> _riskSellerIds(
    String organizationId,
    String userId,
    TargetVisibilityFilter visibility,
  ) async {
    final insightVisibility = InsightVisibilityFilter(
      organizationId: organizationId,
      userId: userId,
      mode: switch (visibility.mode) {
        TargetVisibilityMode.allOrganization =>
          InsightVisibilityMode.allOrganization,
        TargetVisibilityMode.teams => InsightVisibilityMode.teams,
        TargetVisibilityMode.ownOnly => InsightVisibilityMode.ownOnly,
        TargetVisibilityMode.none => InsightVisibilityMode.none,
      },
      teamMemberIds: visibility.teamMemberIds,
    );
    final result = await _insights.listPageByVisibility(
      organizationId: organizationId,
      visibility: insightVisibility,
      limit: 100,
      type: InsightType.sellerBelowTarget,
    );
    return switch (result) {
      AppSuccess<InsightPage>(value: final page) =>
        page.insights.map((item) => item.sellerId).whereType<String>().toSet(),
      AppFailure<InsightPage>() => <String>{},
    };
  }
}
