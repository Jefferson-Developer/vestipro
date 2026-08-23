import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/usecases/list_organization_users_use_case.dart';
import 'user_list_event.dart';
import 'user_list_state.dart';

/// Drives `UserListPage` (TASK-042): loading the administrative user roster
/// of one Organization and applying search/role/status filters plus
/// "carregar mais" pagination entirely in memory on top of it.
///
/// `UserListPage` never talks to [ListOrganizationUsersUseCase] directly —
/// every state transition goes through this bloc, same precedent as
/// `InviteListBloc`.
///
/// Search/filter/pagination are deliberately client-side, over the single
/// roster [ListOrganizationUsersUseCase] already loaded, instead of a
/// per-keystroke Firestore query: `Membership`/`users/{uid}` cannot be
/// joined by Firestore, so a real server-side name/e-mail search would need
/// either denormalizing a search-optimized field or a dedicated search
/// index (neither exists yet) — see `ListOrganizationUsersUseCase`'s own
/// docs. `AppSearchField` already debounces keystrokes before ever
/// dispatching [UserListEvent.searchChanged], so this bloc never needs its
/// own debounce timer on top of that.
@injectable
final class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({required this.listOrganizationUsers})
    : super(const UserListState()) {
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
  }

  final ListOrganizationUsersUseCase listOrganizationUsers;

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
}
