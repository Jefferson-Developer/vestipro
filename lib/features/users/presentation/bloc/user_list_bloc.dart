import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/user_access_update_result.dart';
import '../../domain/usecases/deactivate_user_use_case.dart';
import '../../domain/usecases/list_organization_users_use_case.dart';
import '../../domain/usecases/reactivate_user_use_case.dart';
import 'user_list_event.dart';
import 'user_list_state.dart';

/// Drives `UserListPage` (TASK-042/TASK-046): loading the administrative
/// user roster, filtering it in memory and delegating sensitive access
/// changes to Cloud Functions-backed use cases.
@injectable
final class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({
    required this.listOrganizationUsers,
    required this.deactivateUser,
    required this.reactivateUser,
    required this.analyticsService,
  }) : super(const UserListState()) {
    on<UserListStarted>(_onStarted, transformer: restartable());
    on<UserListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<UserListSearchChanged>(_onSearchChanged, transformer: sequential());
    on<UserListRoleFilterChanged>(
      _onRoleFilterChanged,
      transformer: sequential(),
    );
    on<UserListStatusFilterChanged>(
      _onStatusFilterChanged,
      transformer: sequential(),
    );
    on<UserListLoadMoreRequested>(
      _onLoadMoreRequested,
      transformer: sequential(),
    );
    on<UserListAccessStatusChangeRequested>(
      _onAccessStatusChangeRequested,
      transformer: droppable(),
    );
  }

  final ListOrganizationUsersUseCase listOrganizationUsers;
  final DeactivateUserUseCase deactivateUser;
  final ReactivateUserUseCase reactivateUser;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    UserListStarted event,
    Emitter<UserListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: UserListLoadStatus.loading,
        organizationId: event.organizationId,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    UserListRefreshRequested event,
    Emitter<UserListState> emit,
  ) async {
    if (state.organizationId.isEmpty) {
      return;
    }
    emit(state.copyWith(loadStatus: UserListLoadStatus.loading));
    await _load(state.organizationId, emit);
  }

  Future<void> _load(String organizationId, Emitter<UserListState> emit) async {
    final result = await listOrganizationUsers(organizationId);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<List<OrganizationUser>>(value: final users):
        emit(
          state.copyWith(
            loadStatus: UserListLoadStatus.ready,
            allUsers: users,
            loadFailure: null,
            visibleCount: kUserListPageSize,
            accessMutationStatus: UserListAccessMutationStatus.idle,
            accessMutationUser: null,
            accessMutationFailure: null,
            accessMutationResult: null,
          ),
        );
      case AppFailure<List<OrganizationUser>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: UserListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    UserListSearchChanged event,
    Emitter<UserListState> emit,
  ) {
    emit(
      state.copyWith(searchQuery: event.query, visibleCount: kUserListPageSize),
    );
  }

  void _onRoleFilterChanged(
    UserListRoleFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    emit(
      state.copyWith(
        roleFilter: event.roleName,
        visibleCount: kUserListPageSize,
      ),
    );
  }

  void _onStatusFilterChanged(
    UserListStatusFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    emit(
      state.copyWith(
        statusFilter: event.status,
        visibleCount: kUserListPageSize,
      ),
    );
  }

  void _onLoadMoreRequested(
    UserListLoadMoreRequested event,
    Emitter<UserListState> emit,
  ) {
    if (!state.hasMore) {
      return;
    }
    emit(state.copyWith(visibleCount: state.visibleCount + kUserListPageSize));
  }

  Future<void> _onAccessStatusChangeRequested(
    UserListAccessStatusChangeRequested event,
    Emitter<UserListState> emit,
  ) async {
    if (state.organizationId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        accessMutationStatus: UserListAccessMutationStatus.submitting,
        accessMutationUser: event.user,
        accessMutationFailure: null,
        accessMutationResult: null,
      ),
    );

    final result = event.user.status == MembershipStatus.active
        ? await deactivateUser(
            organizationId: state.organizationId,
            targetUserId: event.user.userId,
          )
        : await reactivateUser(
            organizationId: state.organizationId,
            targetUserId: event.user.userId,
          );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<UserAccessUpdateResult>(value: final update):
        await analyticsService.logEvent(
          update.status == MembershipStatus.inactive
              ? AnalyticsEvents.userDeactivated
              : AnalyticsEvents.userReactivated,
          parameters: <String, Object?>{
            'previous_status': _statusCode(update.previousStatus),
            'new_status': _statusCode(update.status),
          },
        );
        if (emit.isDone) {
          return;
        }
        final updatedUsers = state.allUsers
            .map(
              (user) => user.userId == update.targetUserId
                  ? user.copyWith(status: update.status)
                  : user,
            )
            .toList(growable: false);
        emit(
          state.copyWith(
            allUsers: updatedUsers,
            accessMutationStatus: UserListAccessMutationStatus.success,
            accessMutationUser: updatedUsers.firstWhere(
              (user) => user.userId == update.targetUserId,
              orElse: () => event.user.copyWith(status: update.status),
            ),
            accessMutationFailure: null,
            accessMutationResult: update,
          ),
        );
      case AppFailure<UserAccessUpdateResult>(failure: final failure):
        emit(
          state.copyWith(
            accessMutationStatus: UserListAccessMutationStatus.failure,
            accessMutationFailure: failure,
          ),
        );
    }
  }

  String _statusCode(MembershipStatus status) {
    return switch (status) {
      MembershipStatus.active => 'active',
      MembershipStatus.inactive => 'inactive',
    };
  }
}
