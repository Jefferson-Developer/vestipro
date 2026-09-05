import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../crm/domain/entities/crm_task.dart';
import '../../../crm/domain/repositories/crm_task_repository.dart';
import '../../../customers/domain/entities/customer_portfolio_filters.dart';
import '../../../customers/domain/entities/customer_portfolio_page_result.dart';
import '../../../customers/domain/usecases/list_customer_portfolio_use_case.dart';
import '../../../insights/domain/entities/insight.dart';
import '../../../insights/domain/entities/insight_page.dart';
import '../../../insights/domain/repositories/insight_repository.dart';
import '../../../insights/domain/value_objects/insight_status.dart';
import '../../../targets/domain/entities/positivacao_snapshot.dart';
import '../../../targets/domain/entities/target.dart';
import '../../../targets/domain/entities/target_achievement_snapshot.dart';
import '../../../targets/domain/entities/target_progress_view_model.dart';
import '../../../targets/domain/repositories/positivacao_repository.dart';
import '../../../targets/domain/repositories/target_achievement_repository.dart';
import '../../../targets/domain/repositories/target_repository.dart';
import '../../../targets/domain/target_period_overlap.dart';
import '../../../targets/domain/value_objects/positivacao_dimension_type.dart';
import '../../../targets/domain/value_objects/target_dimension_type.dart';
import '../../../targets/domain/value_objects/target_metric_type.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/executive_dashboard_metric.dart';
import '../entities/representative_customer_highlight.dart';
import '../entities/representative_dashboard_filters.dart';
import '../entities/representative_dashboard_snapshot.dart';
import '../repositories/aggregation_repository.dart';
import '../services/representative_dashboard_visibility_service.dart';
import '../value_objects/aggregation_dimension.dart';

@injectable
class LoadRepresentativeDashboardUseCase {
  const LoadRepresentativeDashboardUseCase(
    this._visibilityService,
    this._aggregationRepository,
    this._positivacaoRepository,
    this._targetRepository,
    this._targetAchievementRepository,
    this._crmTaskRepository,
    this._insightRepository,
    this._listCustomerPortfolio,
  );

  final RepresentativeDashboardVisibilityService _visibilityService;
  final AggregationRepository _aggregationRepository;
  final PositivacaoRepository _positivacaoRepository;
  final TargetRepository _targetRepository;
  final TargetAchievementRepository _targetAchievementRepository;
  final CrmTaskRepository _crmTaskRepository;
  final InsightRepository _insightRepository;
  final ListCustomerPortfolioUseCase _listCustomerPortfolio;

  Future<AppResult<RepresentativeDashboardSnapshot>> call({
    required String organizationId,
    required String requesterUserId,
    required RepresentativeDashboardFilters filters,
    DateTime? now,
  }) async {
    final currentTime = (now ?? DateTime.now()).toUtc();
    if (organizationId.trim().isEmpty ||
        requesterUserId.trim().isEmpty ||
        filters.companyId.trim().isEmpty ||
        filters.sellerId.trim().isEmpty ||
        filters.month < 1 ||
        filters.month > 12) {
      return const AppFailure<RepresentativeDashboardSnapshot>(
        ValidationFailure(
          'Invalid representative dashboard payload.',
          code: 'invalid_representative_dashboard_payload',
        ),
      );
    }

    final visibility = await _visibilityService.canView(
      organizationId: organizationId,
      requesterUserId: requesterUserId,
      sellerId: filters.sellerId,
    );
    if (visibility case AppFailure<bool>(failure: final failure)) {
      return AppFailure<RepresentativeDashboardSnapshot>(failure);
    }
    if (!(visibility as AppSuccess<bool>).value) {
      return const AppFailure<RepresentativeDashboardSnapshot>(
        PermissionFailure(
          'User cannot view this representative dashboard.',
          code: 'representative_dashboard_forbidden',
        ),
      );
    }

    final todayResult = await _aggregationRepository.getSnapshot(
      organizationId: organizationId,
      dimension: AggregationDimension.sellerDaily,
      companyId: filters.companyId,
      scopeId: filters.sellerId,
      periodKey: _dayKey(currentTime),
    );
    final monthResult = await _aggregationRepository.getSnapshot(
      organizationId: organizationId,
      dimension: AggregationDimension.representativeMonthly,
      companyId: filters.companyId,
      scopeId: filters.sellerId,
      periodKey: filters.monthKey,
    );

    final positivacaoResult = await _positivacaoRepository.getForDimension(
      organizationId: organizationId,
      companyId: filters.companyId,
      dimensionType: PositivacaoDimensionType.salesRep,
      dimensionId: filters.sellerId,
      periodStart: filters.periodStart,
      periodEnd: filters.periodEnd,
    );
    final targetMetric = await _loadTargetMetric(
      organizationId: organizationId,
      filters: filters,
      now: currentTime,
    );
    final followUps = await _loadFollowUps(
      organizationId: organizationId,
      sellerId: filters.sellerId,
    );
    final insights = await _loadInsights(
      organizationId: organizationId,
      sellerId: filters.sellerId,
    );
    final customers = await _loadCustomers(
      organizationId: organizationId,
      filters: filters,
      insights: insights,
      now: currentTime,
    );

    final today = _snapshotOf(todayResult);
    final month = _snapshotOf(monthResult);
    final generatedDates = <DateTime>[
      if (today != null) today.generatedAt,
      if (month != null) month.generatedAt,
    ]..sort();
    return AppSuccess<RepresentativeDashboardSnapshot>(
      RepresentativeDashboardSnapshot(
        salesToday: _revenueMetric(todayResult),
        salesMonth: _revenueMetric(monthResult),
        targetAchievement: targetMetric,
        portfolioPositivation: switch (positivacaoResult) {
          AppSuccess<PositivacaoSnapshot>(value: final value)
              when value.isCalculated =>
            ExecutiveDashboardMetric.available(value: value.percentage),
          AppSuccess<PositivacaoSnapshot>() =>
            const ExecutiveDashboardMetric.notCalculated(),
          AppFailure<PositivacaoSnapshot>(failure: final failure) =>
            ExecutiveDashboardMetric.failed(failure.message),
        },
        teamRank: _rankMetric(month),
        followUps: followUps,
        customers: customers,
        lastUpdatedAt: generatedDates.isEmpty ? null : generatedDates.first,
        isFromLocalCache:
            (today?.isFromLocalCache ?? false) ||
            (month?.isFromLocalCache ?? false),
      ),
    );
  }

  ExecutiveDashboardMetric _revenueMetric(
    AppResult<AggregationSnapshot?> result,
  ) {
    return switch (result) {
      AppFailure<AggregationSnapshot?>(failure: final failure) =>
        ExecutiveDashboardMetric.failed(failure.message),
      AppSuccess<AggregationSnapshot?>(value: null) =>
        const ExecutiveDashboardMetric.available(value: 0),
      AppSuccess<AggregationSnapshot?>(value: final value) =>
        ExecutiveDashboardMetric.available(value: value!.revenueNet),
    };
  }

  AggregationSnapshot? _snapshotOf(AppResult<AggregationSnapshot?> result) =>
      switch (result) {
        AppSuccess<AggregationSnapshot?>(value: final value) => value,
        AppFailure<AggregationSnapshot?>() => null,
      };

  ExecutiveDashboardMetric _rankMetric(AggregationSnapshot? snapshot) {
    final rank = int.tryParse(snapshot?.labels['teamRank'] ?? '');
    return rank == null
        ? const ExecutiveDashboardMetric.notCalculated()
        : ExecutiveDashboardMetric.available(value: rank.toDouble());
  }

  Future<ExecutiveDashboardMetric> _loadTargetMetric({
    required String organizationId,
    required RepresentativeDashboardFilters filters,
    required DateTime now,
  }) async {
    final targetsResult = await _targetRepository.listByDimension(
      organizationId: organizationId,
      companyId: filters.companyId,
      dimensionType: TargetDimensionType.salesRep,
      dimensionId: filters.sellerId,
      metricType: TargetMetricType.revenue,
    );
    if (targetsResult case AppFailure<List<Target>>(failure: final failure)) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final targets = (targetsResult as AppSuccess<List<Target>>).value.where(
      (target) =>
          target.deletedAt == null &&
          targetPeriodsOverlap(
            aStart: target.startDate,
            aEnd: target.endDate,
            bStart: filters.periodStart,
            bEnd: filters.periodEnd,
          ),
    );
    if (targets.isEmpty) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final target = targets.first;
    final result = await _targetAchievementRepository.getForTarget(
      organizationId: organizationId,
      targetId: target.id,
    );
    if (result case AppFailure<TargetAchievementSnapshot>(
      failure: final failure,
    )) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final achievement = (result as AppSuccess<TargetAchievementSnapshot>).value;
    if (!achievement.isCalculated) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final progress = TargetProgressViewModel.compute(
      target: target,
      realizedValue: achievement.realizedValue!,
      calculatedAt: achievement.calculatedAt,
      now: now,
    );
    return ExecutiveDashboardMetric.available(
      value: progress.achievementPercentage,
    );
  }

  Future<List<CrmTask>> _loadFollowUps({
    required String organizationId,
    required String sellerId,
  }) async {
    final result = await _crmTaskRepository.listPending(
      organizationId: organizationId,
      responsibleUserIds: <String>{sellerId},
    );
    if (result case AppFailure<List<CrmTask>>()) return const <CrmTask>[];
    final tasks = [...(result as AppSuccess<List<CrmTask>>).value]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return tasks.take(8).toList(growable: false);
  }

  Future<List<Insight>> _loadInsights({
    required String organizationId,
    required String sellerId,
  }) async {
    final result = await _insightRepository.listPageByRecipient(
      organizationId: organizationId,
      recipientUserId: sellerId,
      limit: 25,
      status: InsightStatus.fresh,
    );
    return switch (result) {
      AppSuccess<InsightPage>(value: final page) => page.insights,
      AppFailure<InsightPage>() => const <Insight>[],
    };
  }

  Future<List<RepresentativeCustomerHighlight>> _loadCustomers({
    required String organizationId,
    required RepresentativeDashboardFilters filters,
    required List<Insight> insights,
    required DateTime now,
  }) async {
    final result = await _listCustomerPortfolio(
      organizationId: organizationId,
      companyId: filters.companyId,
      userId: filters.sellerId,
      filters: CustomerPortfolioFilters.empty,
      limit: 8,
      now: now,
    );
    if (result case AppFailure<CustomerPortfolioPageResult>()) {
      return const <RepresentativeCustomerHighlight>[];
    }
    final byCustomer = <String, Insight>{
      for (final insight in insights)
        if (insight.customerId != null) insight.customerId!: insight,
    };
    final customers =
        (result as AppSuccess<CustomerPortfolioPageResult>).value.customers;
    return customers
        .map(
          (customer) => RepresentativeCustomerHighlight(
            customerId: customer.id,
            customerName: customer.displayName,
            insight: byCustomer[customer.id],
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        if (a.insight != null && b.insight == null) return -1;
        if (a.insight == null && b.insight != null) return 1;
        return a.customerName.compareTo(b.customerName);
      });
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
