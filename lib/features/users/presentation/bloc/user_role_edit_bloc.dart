import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';
import '../../../invites/domain/role_hierarchy.dart';
import '../../../organizations/domain/entities/membership.dart';
import '../../../organizations/domain/repositories/membership_repository.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/user_role_update_result.dart';
import '../../domain/usecases/update_user_role_use_case.dart';
import 'user_role_edit_event.dart';
import 'user_role_edit_state.dart';

/// Drives `UserRoleEditPage`/bottom sheet (TASK-043). It resolves the
/// caller's real Membership to narrow the role picker for UX, then submits
/// to `UpdateUserRoleUseCase`; backend authorization and audit remain
/// entirely inside the Cloud Function.
@injectable
final class UserRoleEditBloc
    extends Bloc<UserRoleEditEvent, UserRoleEditState> {
  UserRoleEditBloc({
    required this.updateUserRole,
    required this.membershipRepository,
    required this.authRepository,
    required this.analyticsService,
  }) : super(const UserRoleEditState()) {
    on<UserRoleEditStarted>(_onStarted, transformer: restartable());
    on<UserRoleEditRoleSelected>(_onRoleSelected, transformer: sequential());
    on<UserRoleEditSubmitted>(_onSubmitted, transformer: droppable());
  }

  final UpdateUserRoleUseCase updateUserRole;
  final MembershipRepository membershipRepository;
  final AuthRepository authRepository;
  final AnalyticsService analyticsService;

  String? get _userId => authRepository.currentUser?.uid;

  Future<void> _onStarted(
    UserRoleEditStarted event,
    Emitter<UserRoleEditState> emit,
  ) async {
    final targetRole = systemRoleNameFromCode(event.user.roleName);
    final userId = _userId;
    if (userId == null || targetRole == null) {
      emit(
        state.copyWith(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: event.organizationId,
          user: event.user,
          currentRole: targetRole,
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

    final assignableRoles = result.fold<List<SystemRoleName>>(
      onSuccess: (membership) =>
          _assignableRolesForTarget(membership, targetRole),
      onFailure: (_) => const <SystemRoleName>[],
    );

    emit(
      state.copyWith(
        loadStatus: UserRoleEditLoadStatus.ready,
        organizationId: event.organizationId,
        user: event.user,
        currentRole: targetRole,
        selectedRole: assignableRoles.contains(targetRole) ? targetRole : null,
        assignableRoles: assignableRoles,
      ),
    );
  }

  List<SystemRoleName> _assignableRolesForTarget(
    Membership callerMembership,
    SystemRoleName targetRole,
  ) {
    if (callerMembership.status != MembershipStatus.active) {
      return const <SystemRoleName>[];
    }

    final callerRole = systemRoleNameFromCode(callerMembership.roleName);
    if (callerRole == null) {
      return const <SystemRoleName>[];
    }

    final callerRank = systemRoleRank[callerRole]!;
    final targetRank = systemRoleRank[targetRole]!;
    if (targetRank < callerRank) {
      return const <SystemRoleName>[];
    }

    return assignableRolesFor(callerRole);
  }

  void _onRoleSelected(
    UserRoleEditRoleSelected event,
    Emitter<UserRoleEditState> emit,
  ) {
    if (!state.assignableRoles.contains(event.role)) {
      return;
    }
    emit(state.copyWith(selectedRole: event.role, roleError: null));
  }

  Future<void> _onSubmitted(
    UserRoleEditSubmitted event,
    Emitter<UserRoleEditState> emit,
  ) async {
    final user = state.user;
    final selectedRole = state.selectedRole;
    if (user == null || selectedRole == null) {
      emit(state.copyWith(roleError: 'Selecione uma função.'));
      return;
    }

    if (selectedRole == state.currentRole) {
      emit(
        state.copyWith(roleError: 'Selecione uma função diferente da atual.'),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: UserRoleEditSubmissionStatus.submitting,
        failure: null,
        result: null,
      ),
    );

    final result = await updateUserRole(
      organizationId: state.organizationId,
      targetUserId: user.userId,
      roleName: selectedRole,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<UserRoleUpdateResult>(value: final update):
        await analyticsService.logEvent(
          AnalyticsEvents.userRoleUpdated,
          parameters: <String, Object?>{
            'previous_role': update.previousRoleName.code,
            'new_role': update.roleName.code,
          },
        );
        if (emit.isDone) {
          return;
        }
        emit(
          state.copyWith(
            submissionStatus: UserRoleEditSubmissionStatus.success,
            currentRole: update.roleName,
            selectedRole: update.roleName,
            failure: null,
            result: update,
          ),
        );
      case AppFailure<UserRoleUpdateResult>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: UserRoleEditSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
