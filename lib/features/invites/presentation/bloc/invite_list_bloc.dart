import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/issued_invite.dart';
import '../../domain/usecases/list_pending_invites_use_case.dart';
import '../../domain/usecases/resend_invite_use_case.dart';
import '../../domain/usecases/revoke_invite_use_case.dart';
import 'invite_list_event.dart';
import 'invite_list_state.dart';

/// Drives `InviteListPage` (TASK-039): loading the pending/expired invites
/// of one Organization and dispatching resend/revoke actions.
///
/// `InviteListPage` never talks to [ListPendingInvitesUseCase]/
/// [ResendInviteUseCase]/[RevokeInviteUseCase] directly — every state
/// transition goes through this bloc.
@injectable
final class InviteListBloc extends Bloc<InviteListEvent, InviteListState> {
  InviteListBloc({
    required this.listPendingInvites,
    required this.resendInvite,
    required this.revokeInvite,
  }) : super(const InviteListState()) {
    on<InviteListStarted>(_onStarted, transformer: restartable());
    on<InviteListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<InviteListResendRequested>(
      _onResendRequested,
      transformer: sequential(),
    );
    on<InviteListRevokeRequested>(
      _onRevokeRequested,
      transformer: sequential(),
    );
  }

  final ListPendingInvitesUseCase listPendingInvites;
  final ResendInviteUseCase resendInvite;
  final RevokeInviteUseCase revokeInvite;

  Future<void> _onStarted(
    InviteListStarted event,
    Emitter<InviteListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: InviteListLoadStatus.loading,
        organizationId: event.organizationId,
      ),
    );
    await _loadInvites(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    InviteListRefreshRequested event,
    Emitter<InviteListState> emit,
  ) async {
    if (state.organizationId.isEmpty) {
      return;
    }
    emit(state.copyWith(loadStatus: InviteListLoadStatus.loading));
    await _loadInvites(state.organizationId, emit);
  }

  Future<void> _loadInvites(
    String organizationId,
    Emitter<InviteListState> emit,
  ) async {
    final result = await listPendingInvites(organizationId);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<List<Invite>>(value: final invites):
        emit(
          state.copyWith(
            loadStatus: InviteListLoadStatus.ready,
            invites: invites,
            loadFailure: null,
          ),
        );
      case AppFailure<List<Invite>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: InviteListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  Future<void> _onResendRequested(
    InviteListResendRequested event,
    Emitter<InviteListState> emit,
  ) async {
    emit(
      state.copyWith(
        processingInviteId: event.inviteId,
        actionFailure: null,
        lastResendResult: null,
      ),
    );

    final result = await resendInvite(
      organizationId: state.organizationId,
      inviteId: event.inviteId,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<IssuedInvite>(value: final issuedInvite):
        emit(
          state.copyWith(
            processingInviteId: null,
            lastResendResult: issuedInvite,
          ),
        );
        await _loadInvites(state.organizationId, emit);
      case AppFailure<IssuedInvite>(failure: final failure):
        emit(state.copyWith(processingInviteId: null, actionFailure: failure));
    }
  }

  Future<void> _onRevokeRequested(
    InviteListRevokeRequested event,
    Emitter<InviteListState> emit,
  ) async {
    emit(
      state.copyWith(
        processingInviteId: event.inviteId,
        actionFailure: null,
        lastResendResult: null,
      ),
    );

    final result = await revokeInvite(
      organizationId: state.organizationId,
      inviteId: event.inviteId,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<Invite>():
        emit(state.copyWith(processingInviteId: null));
        await _loadInvites(state.organizationId, emit);
      case AppFailure<Invite>(failure: final failure):
        emit(state.copyWith(processingInviteId: null, actionFailure: failure));
    }
  }
}
