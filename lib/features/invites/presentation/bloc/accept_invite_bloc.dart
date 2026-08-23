import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/accepted_invite.dart';
import '../../domain/entities/invite_preview.dart';
import '../../domain/usecases/accept_invite_use_case.dart';
import '../../domain/usecases/validate_invite_use_case.dart';
import 'accept_invite_event.dart';
import 'accept_invite_state.dart';

/// Drives `AcceptInvitePage` (TASK-040): validating the token from the
/// `/invite/:token` deep link, resolving whether the current session (if
/// any) matches the invite's e-mail, and the final confirm against
/// [AcceptInviteUseCase].
///
/// `AcceptInvitePage` never talks to [ValidateInviteUseCase]/
/// [AcceptInviteUseCase]/[AuthRepository] directly — every transition goes
/// through this bloc, same rationale as `OnboardingBloc`/`SignUpBloc`.
@injectable
final class AcceptInviteBloc
    extends Bloc<AcceptInviteEvent, AcceptInviteState> {
  AcceptInviteBloc({
    required this.validateInvite,
    required this.acceptInvite,
    required this.authRepository,
    required this.analyticsService,
  }) : super(const AcceptInviteState()) {
    on<AcceptInviteStarted>(_onStarted, transformer: droppable());
    on<AcceptInviteConfirmed>(_onConfirmed, transformer: droppable());
    on<AcceptInviteSignOutRequested>(
      _onSignOutRequested,
      transformer: droppable(),
    );
  }

  final ValidateInviteUseCase validateInvite;
  final AcceptInviteUseCase acceptInvite;
  final AuthRepository authRepository;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    AcceptInviteStarted event,
    Emitter<AcceptInviteState> emit,
  ) async {
    emit(
      state.copyWith(
        token: event.token,
        validationStatus: AcceptInviteValidationStatus.loading,
        failure: null,
      ),
    );

    final result = await validateInvite(token: event.token);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<InvitePreview>(value: final preview):
        final sessionUser = authRepository.currentUser;
        final hasActiveSession = sessionUser != null;
        final invitedEmail = preview.email;
        final mismatch =
            hasActiveSession &&
            invitedEmail != null &&
            sessionUser.email?.toLowerCase() != invitedEmail.toLowerCase();

        emit(
          state.copyWith(
            validationStatus: AcceptInviteValidationStatus.ready,
            outcome: preview.outcome,
            organizationId: preview.organizationId,
            organizationName: preview.organizationName,
            invitedEmail: invitedEmail,
            roleName: preview.roleName,
            hasActiveSession: hasActiveSession,
            sessionEmailMismatch: mismatch,
          ),
        );
      case AppFailure<InvitePreview>(failure: final failure):
        emit(
          state.copyWith(
            validationStatus: AcceptInviteValidationStatus.error,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onConfirmed(
    AcceptInviteConfirmed event,
    Emitter<AcceptInviteState> emit,
  ) async {
    emit(
      state.copyWith(
        acceptanceStatus: AcceptInviteAcceptanceStatus.submitting,
        failure: null,
      ),
    );

    final result = await acceptInvite(token: state.token);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<AcceptedInvite>(value: final accepted):
        // Only the assigned role is logged — never the e-mail/uid (LGPD
        // restriction on `AnalyticsService.logEvent`, `AGENTS.md`).
        await analyticsService.logEvent(
          AnalyticsEvents.inviteAccepted,
          parameters: <String, Object?>{'role': accepted.roleName.code},
        );
        if (emit.isDone) {
          return;
        }
        emit(
          state.copyWith(
            acceptanceStatus: AcceptInviteAcceptanceStatus.success,
            acceptedOrganizationId: accepted.organizationId,
            organizationName: accepted.organizationName,
          ),
        );
      case AppFailure<AcceptedInvite>(failure: final failure):
        emit(
          state.copyWith(
            acceptanceStatus: AcceptInviteAcceptanceStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onSignOutRequested(
    AcceptInviteSignOutRequested event,
    Emitter<AcceptInviteState> emit,
  ) async {
    await authRepository.signOut();
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(hasActiveSession: false, sessionEmailMismatch: false));
  }
}
