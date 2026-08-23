import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/usecases/list_organization_users_use_case.dart';
import 'team_form_event.dart';
import 'team_form_state.dart';

@injectable
final class TeamFormBloc extends Bloc<TeamFormEvent, TeamFormState> {
  TeamFormBloc({
    required this.listOrganizationUsers,
    required this.createTeam,
    required this.updateTeam,
    required this.analyticsService,
  }) : super(const TeamFormState()) {
    on<TeamFormStarted>(_onStarted, transformer: restartable());
    on<TeamFormNameChanged>(_onNameChanged, transformer: sequential());
    on<TeamFormManagerSelected>(_onManagerSelected, transformer: sequential());
    on<TeamFormMembersSelected>(_onMembersSelected, transformer: sequential());
    on<TeamFormSubmitted>(_onSubmitted, transformer: sequential());
  }

  final ListOrganizationUsersUseCase listOrganizationUsers;
  final CreateTeamUseCase createTeam;
  final UpdateTeamUseCase updateTeam;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    TeamFormStarted event,
    Emitter<TeamFormState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: TeamFormLoadStatus.loading,
        submissionStatus: TeamFormSubmissionStatus.idle,
        organizationId: event.organizationId,
        userId: event.userId,
        initialTeam: event.initialTeam,
        name: event.initialTeam?.name ?? '',
        managerUserId: event.initialTeam?.managerUserId,
        memberIds: event.initialTeam?.memberIds.toSet() ?? const <String>{},
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedTeam: true,
      ),
    );

    final result = await listOrganizationUsers(event.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<OrganizationUser>>(value: final users):
        emit(
          state.copyWith(
            loadStatus: TeamFormLoadStatus.ready,
            users: users,
            clearFailure: true,
          ),
        );
      case AppFailure<List<OrganizationUser>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: TeamFormLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onNameChanged(TeamFormNameChanged event, Emitter<TeamFormState> emit) {
    emit(
      state.copyWith(
        name: event.name,
        submissionStatus: TeamFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onManagerSelected(
    TeamFormManagerSelected event,
    Emitter<TeamFormState> emit,
  ) {
    emit(
      state.copyWith(
        managerUserId: event.managerUserId,
        clearManagerUserId: event.managerUserId == null,
        submissionStatus: TeamFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onMembersSelected(
    TeamFormMembersSelected event,
    Emitter<TeamFormState> emit,
  ) {
    emit(
      state.copyWith(
        memberIds: event.memberIds,
        submissionStatus: TeamFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    TeamFormSubmitted event,
    Emitter<TeamFormState> emit,
  ) async {
    final localErrors = <String, String>{};
    if (state.name.trim().isEmpty) {
      localErrors['name'] = 'Informe o nome da equipe.';
    }
    final managerUserId = state.managerUserId?.trim() ?? '';
    if (managerUserId.isEmpty) {
      localErrors['managerUserId'] = 'Selecione um gestor responsável.';
    }
    if (localErrors.isNotEmpty) {
      emit(
        state.copyWith(
          submissionStatus: TeamFormSubmissionStatus.failure,
          fieldErrors: localErrors,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: TeamFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedTeam: true,
      ),
    );

    final result = state.isEditing
        ? await updateTeam(
            organizationId: state.organizationId,
            id: state.initialTeam!.id,
            name: state.name,
            managerUserId: managerUserId,
            memberIds: state.memberIds.toList(growable: false),
            companyId: state.initialTeam!.companyId,
            branchId: state.initialTeam!.branchId,
            updatedBy: state.userId,
          )
        : await createTeam(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            name: state.name,
            managerUserId: managerUserId,
            memberIds: state.memberIds.toList(growable: false),
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Team>(value: final team):
        await analyticsService.logEvent(
          state.isEditing
              ? AnalyticsEvents.teamUpdated
              : AnalyticsEvents.teamCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'team_id': team.id,
            'member_count': team.memberIds.length,
          },
        );
        emit(
          state.copyWith(
            submissionStatus: TeamFormSubmissionStatus.success,
            savedTeam: team,
            clearFailure: true,
          ),
        );
      case AppFailure<Team>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: TeamFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
