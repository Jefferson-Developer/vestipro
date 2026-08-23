import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/commercial_team.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/portfolio_assignment.dart';
import '../../domain/usecases/assign_portfolio_use_case.dart';
import '../../domain/usecases/list_commercial_teams_use_case.dart';
import '../../domain/usecases/list_organization_users_use_case.dart';
import '../../domain/usecases/list_portfolio_assignments_use_case.dart';
import 'assign_portfolio_event.dart';
import 'assign_portfolio_state.dart';

@injectable
final class AssignPortfolioBloc
    extends Bloc<AssignPortfolioEvent, AssignPortfolioState> {
  AssignPortfolioBloc({
    required this.listOrganizationUsers,
    required this.listCommercialTeams,
    required this.listPortfolioAssignments,
    required this.assignPortfolio,
    required this.analyticsService,
  }) : super(const AssignPortfolioState()) {
    on<AssignPortfolioStarted>(_onStarted, transformer: restartable());
    on<AssignPortfolioRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<AssignPortfolioSellerSelected>(
      _onSellerSelected,
      transformer: sequential(),
    );
    on<AssignPortfolioTeamSelected>(_onTeamSelected, transformer: sequential());
    on<AssignPortfolioScopeTypeChanged>(
      _onScopeTypeChanged,
      transformer: sequential(),
    );
    on<AssignPortfolioCustomerIdChanged>(
      _onCustomerIdChanged,
      transformer: sequential(),
    );
    on<AssignPortfolioRegionChanged>(
      _onRegionChanged,
      transformer: sequential(),
    );
    on<AssignPortfolioSegmentChanged>(
      _onSegmentChanged,
      transformer: sequential(),
    );
    on<AssignPortfolioSubmitted>(_onSubmitted, transformer: sequential());
  }

  final ListOrganizationUsersUseCase listOrganizationUsers;
  final ListCommercialTeamsUseCase listCommercialTeams;
  final ListPortfolioAssignmentsUseCase listPortfolioAssignments;
  final AssignPortfolioUseCase assignPortfolio;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    AssignPortfolioStarted event,
    Emitter<AssignPortfolioState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: AssignPortfolioLoadStatus.loading,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        clearFailure: true,
        clearFieldErrors: true,
        clearSavedAssignment: true,
      ),
    );
    await _load(event.organizationId, event.companyId, emit);
  }

  Future<void> _onRefreshRequested(
    AssignPortfolioRefreshRequested event,
    Emitter<AssignPortfolioState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.companyId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: AssignPortfolioLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.organizationId, state.companyId, emit);
  }

  Future<void> _load(
    String organizationId,
    String companyId,
    Emitter<AssignPortfolioState> emit,
  ) async {
    final usersResult = await listOrganizationUsers(organizationId);
    if (emit.isDone) return;
    if (usersResult case AppFailure<List<OrganizationUser>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          loadStatus: AssignPortfolioLoadStatus.failure,
          failure: failure,
        ),
      );
      return;
    }

    final teamsResult = await listCommercialTeams(organizationId);
    if (emit.isDone) return;
    if (teamsResult case AppFailure<List<CommercialTeam>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          loadStatus: AssignPortfolioLoadStatus.failure,
          failure: failure,
        ),
      );
      return;
    }

    final assignmentsResult = await listPortfolioAssignments(
      organizationId: organizationId,
      companyId: companyId,
    );
    if (emit.isDone) return;
    if (assignmentsResult case AppFailure<List<PortfolioAssignment>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          loadStatus: AssignPortfolioLoadStatus.failure,
          failure: failure,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loadStatus: AssignPortfolioLoadStatus.ready,
        users: (usersResult as AppSuccess<List<OrganizationUser>>).value,
        teams: (teamsResult as AppSuccess<List<CommercialTeam>>).value,
        assignments:
            (assignmentsResult as AppSuccess<List<PortfolioAssignment>>).value,
        clearFailure: true,
      ),
    );
  }

  void _onSellerSelected(
    AssignPortfolioSellerSelected event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        selectedUserId: event.userId,
        clearSelectedUserId: event.userId == null,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onTeamSelected(
    AssignPortfolioTeamSelected event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        selectedTeamId: event.teamId,
        clearSelectedTeamId: event.teamId == null,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onScopeTypeChanged(
    AssignPortfolioScopeTypeChanged event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        scopeType: event.scopeType,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onCustomerIdChanged(
    AssignPortfolioCustomerIdChanged event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        customerId: event.customerId,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onRegionChanged(
    AssignPortfolioRegionChanged event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        region: event.region,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onSegmentChanged(
    AssignPortfolioSegmentChanged event,
    Emitter<AssignPortfolioState> emit,
  ) {
    emit(
      state.copyWith(
        segment: event.segment,
        submissionStatus: AssignPortfolioSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    AssignPortfolioSubmitted event,
    Emitter<AssignPortfolioState> emit,
  ) async {
    final scope = state.scopeType == PortfolioAssignmentScopeType.customer
        ? PortfolioAssignmentScope.customer(state.customerId)
        : PortfolioAssignmentScope.criteria(
            region: state.region,
            segment: state.segment,
          );

    emit(
      state.copyWith(
        submissionStatus: AssignPortfolioSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedAssignment: true,
      ),
    );
    final result = await assignPortfolio(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.selectedUserId ?? '',
      teamId: state.selectedTeamId ?? '',
      scope: scope,
      assignedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<PortfolioAssignment>(value: final assignment):
        await analyticsService.logEvent(
          AnalyticsEvents.portfolioAssignmentSaved,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'company_id': state.companyId,
            'assignment_id': assignment.id,
            'scope_type': assignment.scope.type.code,
          },
        );
        final refreshed = await listPortfolioAssignments(
          organizationId: state.organizationId,
          companyId: state.companyId,
        );
        emit(
          state.copyWith(
            submissionStatus: AssignPortfolioSubmissionStatus.success,
            assignments: refreshed.fold(
              onSuccess: (assignments) => assignments,
              onFailure: (_) => state.assignments,
            ),
            savedAssignment: assignment,
            clearFailure: true,
          ),
        );
        emit(
          state.copyWith(
            submissionStatus: AssignPortfolioSubmissionStatus.idle,
            clearSavedAssignment: true,
          ),
        );
      case AppFailure<PortfolioAssignment>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: AssignPortfolioSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
