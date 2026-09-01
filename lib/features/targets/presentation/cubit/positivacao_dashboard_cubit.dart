import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/customers.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/positivacao_snapshot.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/repositories/positivacao_repository.dart';
import '../../domain/services/positivacao_period_resolver.dart';
import '../../domain/services/target_visibility_service.dart';
import '../../domain/value_objects/positivacao_dimension_type.dart';
import '../../domain/value_objects/positivacao_settings.dart';
import 'positivacao_dashboard_state.dart';

/// Drives the positivação de carteira dashboard (TASK-117, EPIC-15/
/// VESTI-087): resolves which dimension(s) the caller may view (reusing
/// `TargetVisibilityService`, never re-implemented — TASK-116 already models
/// the exact same OWNER/ADMIN/SALES_MANAGER/SALES_REP dimension-visibility
/// decision this dashboard needs), resolves the organization's
/// `PositivacaoSettings` and subscribes to the selected dimension/current
/// period's near-real-time snapshot (`PositivacaoRepository
/// .watchForDimension`).
@injectable
final class PositivacaoDashboardCubit extends Cubit<PositivacaoDashboardState> {
  PositivacaoDashboardCubit(
    this._visibilityService,
    this._getOrganizationUseCase,
    this._positivacaoRepository,
    this._getCustomerByIdUseCase,
    this._analyticsService,
  ) : super(const PositivacaoDashboardState());

  final TargetVisibilityService _visibilityService;
  final GetOrganizationUseCase _getOrganizationUseCase;
  final PositivacaoRepository _positivacaoRepository;
  final GetCustomerByIdUseCase _getCustomerByIdUseCase;
  final AnalyticsService _analyticsService;

  StreamSubscription<PositivacaoSnapshot>? _snapshotSubscription;

  /// Resolves visibility and settings, then loads the caller's own
  /// `salesRep` carteira by default — the "minha carteira" landing view
  /// every role that can reach this page at all is guaranteed to see.
  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    emit(
      state.copyWith(
        status: PositivacaoDashboardStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      ),
    );

    final filterResult = await _visibilityService.resolve(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );
    if (filterResult case AppFailure<TargetVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: PositivacaoDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final filter = (filterResult as AppSuccess<TargetVisibilityFilter>).value;
    emit(state.copyWith(visibilityFilter: filter));

    if (!filter.canViewAny) {
      emit(state.copyWith(status: PositivacaoDashboardStatus.forbidden));
      return;
    }

    final organizationResult = await _getOrganizationUseCase(organizationId);
    if (organizationResult case AppFailure<Organization>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: PositivacaoDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final organization = (organizationResult as AppSuccess<Organization>).value;
    final settings = PositivacaoSettings.fromOrganizationSettings(
      organization.settings,
    );
    emit(state.copyWith(settings: settings));

    await selectDimension(
      dimensionType: PositivacaoDimensionType.salesRep,
      dimensionId: userId,
    );
  }

  /// Switches the dashboard to [dimensionType]/[dimensionId], re-checking
  /// [TargetVisibilityFilter.canView] first — never assuming the UI already
  /// hid an option the caller cannot reach.
  Future<void> selectDimension({
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
  }) async {
    final filter = state.visibilityFilter;
    final settings = state.settings;
    final trimmedDimensionId = dimensionId.trim();
    if (filter == null || settings == null || trimmedDimensionId.isEmpty) {
      return;
    }

    if (!filter.canView(
      dimensionType: dimensionType.asTargetDimensionType,
      dimensionId: trimmedDimensionId,
    )) {
      // Fire-and-forget: cancelling a subscription stops it from delivering
      // any further event synchronously — nothing here needs to wait for
      // the underlying stream's own teardown to finish, and doing so would
      // needlessly delay the forbidden state by a full stream-cancellation
      // round trip.
      unawaited(_snapshotSubscription?.cancel());
      _snapshotSubscription = null;
      emit(
        state.copyWith(
          status: PositivacaoDashboardStatus.forbidden,
          dimensionType: dimensionType,
          dimensionId: trimmedDimensionId,
          clearSnapshot: true,
        ),
      );
      return;
    }

    unawaited(_snapshotSubscription?.cancel());

    final period = PositivacaoPeriod.current(
      granularity: settings.periodGranularity,
      now: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: PositivacaoDashboardStatus.loading,
        dimensionType: dimensionType,
        dimensionId: trimmedDimensionId,
        period: period,
        clearSnapshot: true,
        pendingCustomerLabels: const <String, String>{},
      ),
    );

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.positivacaoDashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'company_id': state.companyId,
          'dimension_type': dimensionType.name,
        },
      ),
    );

    _snapshotSubscription = _positivacaoRepository
        .watchForDimension(
          organizationId: state.organizationId,
          companyId: state.companyId,
          dimensionType: dimensionType,
          dimensionId: trimmedDimensionId,
          periodStart: period.start,
          periodEnd: period.end,
        )
        .listen(
          _onSnapshot,
          onError: (Object error) {
            emit(
              state.copyWith(
                status: PositivacaoDashboardStatus.error,
                failureMessage: error.toString(),
              ),
            );
          },
        );
  }

  void _onSnapshot(PositivacaoSnapshot snapshot) {
    if (!snapshot.isCalculated) {
      emit(
        state.copyWith(
          status: PositivacaoDashboardStatus.notCalculated,
          snapshot: snapshot,
        ),
      );
      return;
    }

    if (snapshot.totalPortfolio == 0) {
      emit(
        state.copyWith(
          status: PositivacaoDashboardStatus.emptyPortfolio,
          snapshot: snapshot,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PositivacaoDashboardStatus.ready,
        snapshot: snapshot,
      ),
    );
    unawaited(_resolvePendingCustomerLabels(snapshot));
  }

  /// Best-effort, non-blocking resolution of
  /// `Customer.displayName` for [snapshot]'s pending customers, so the "ação
  /// comercial" list shows names instead of raw ids once available — never
  /// blocks [PositivacaoDashboardStatus.ready] on this, and silently keeps
  /// the raw id for any lookup that fails.
  Future<void> _resolvePendingCustomerLabels(
    PositivacaoSnapshot snapshot,
  ) async {
    if (snapshot.nonPositivatedCustomerIds.isEmpty) return;

    final labels = <String, String>{};
    for (final customerId in snapshot.nonPositivatedCustomerIds) {
      final result = await _getCustomerByIdUseCase(
        organizationId: snapshot.organizationId,
        id: customerId,
      );
      if (result case AppSuccess<Customer>(value: final customer)) {
        labels[customerId] = customer.displayName;
      }
    }

    if (isClosed || labels.isEmpty) return;
    // Never applies a stale resolution to a since-switched dimension/period.
    if (!identical(state.snapshot, snapshot)) return;

    emit(
      state.copyWith(
        pendingCustomerLabels: <String, String>{
          ...state.pendingCustomerLabels,
          ...labels,
        },
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_snapshotSubscription?.cancel());
    return super.close();
  }
}
