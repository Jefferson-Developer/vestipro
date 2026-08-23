import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/repositories/membership_repository.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/issued_invite.dart';
import '../../domain/role_hierarchy.dart';
import '../../domain/usecases/create_invite_use_case.dart';
import '../../domain/validators/invite_form_validators.dart';
import 'invite_form_event.dart';
import 'invite_form_state.dart';

/// Drives `InviteUserPage` (TASK-039): resolving which roles the signed-in
/// user may assign, per-field edits/validation and the final submit against
/// [CreateInviteUseCase].
///
/// `InviteUserPage` never talks to [CreateInviteUseCase]/
/// [MembershipRepository]/[AuthRepository] directly — every state
/// transition goes through this bloc, same rationale as `OnboardingBloc`
/// (TASK-038).
@injectable
final class InviteFormBloc extends Bloc<InviteFormEvent, InviteFormState> {
  InviteFormBloc({
    required this.createInvite,
    required this.membershipRepository,
    required this.authRepository,
    required this.analyticsService,
  }) : super(const InviteFormState()) {
    on<InviteFormStarted>(_onStarted, transformer: droppable());
    on<InviteFormEmailChanged>(_onEmailChanged, transformer: sequential());
    on<InviteFormRoleSelected>(_onRoleSelected, transformer: sequential());
    on<InviteFormMessageChanged>(_onMessageChanged, transformer: sequential());
    on<InviteFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreateInviteUseCase createInvite;
  final MembershipRepository membershipRepository;
  final AuthRepository authRepository;
  final AnalyticsService analyticsService;

  String? get _userId => authRepository.currentUser?.uid;

  Future<void> _onStarted(
    InviteFormStarted event,
    Emitter<InviteFormState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      emit(
        state.copyWith(
          loadStatus: InviteFormLoadStatus.ready,
          organizationId: event.organizationId,
        ),
      );
      return;
    }

    final result = await membershipRepository.getByUser(
      organizationId: event.organizationId,
      userId: userId,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess(value: final membership):
        final callerRole = systemRoleNameFromCode(membership.roleName);
        emit(
          state.copyWith(
            loadStatus: InviteFormLoadStatus.ready,
            organizationId: event.organizationId,
            assignableRoles: callerRole == null
                ? const []
                : assignableRolesFor(callerRole),
          ),
        );
      case AppFailure():
        // Fails closed, same rationale as `PermissionService`: an
        // unresolved Membership never grants any assignable role.
        emit(
          state.copyWith(
            loadStatus: InviteFormLoadStatus.ready,
            organizationId: event.organizationId,
          ),
        );
    }
  }

  Future<void> _onEmailChanged(
    InviteFormEmailChanged event,
    Emitter<InviteFormState> emit,
  ) async {
    emit(state.copyWith(email: event.email, emailError: null));
  }

  Future<void> _onRoleSelected(
    InviteFormRoleSelected event,
    Emitter<InviteFormState> emit,
  ) async {
    emit(state.copyWith(role: event.role, roleError: null));
  }

  Future<void> _onMessageChanged(
    InviteFormMessageChanged event,
    Emitter<InviteFormState> emit,
  ) async {
    emit(state.copyWith(message: event.message));
  }

  Future<void> _onSubmitted(
    InviteFormSubmitted event,
    Emitter<InviteFormState> emit,
  ) async {
    final emailError = validateInviteEmail(state.email);
    final role = state.role;
    final roleError = role == null ? 'Selecione uma função.' : null;

    if (emailError != null || roleError != null) {
      emit(state.copyWith(emailError: emailError, roleError: roleError));
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: InviteFormSubmissionStatus.submitting,
        failure: null,
      ),
    );

    final result = await createInvite(
      organizationId: state.organizationId,
      email: state.email,
      roleName: role!,
      message: state.message,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<IssuedInvite>(value: final issuedInvite):
        // Only the assigned role is logged — never the invited e-mail
        // (personal data), same LGPD restriction `AnalyticsService.logEvent`
        // documents.
        await analyticsService.logEvent(
          AnalyticsEvents.inviteSent,
          parameters: <String, Object?>{'role': role.code},
        );
        if (emit.isDone) {
          return;
        }
        emit(
          state.copyWith(
            submissionStatus: InviteFormSubmissionStatus.success,
            issuedInvite: issuedInvite,
          ),
        );
      case AppFailure<IssuedInvite>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: InviteFormSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
