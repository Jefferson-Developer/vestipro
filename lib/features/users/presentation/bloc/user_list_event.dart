import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/membership_status.dart';

part 'user_list_event.freezed.dart';

@freezed
sealed class UserListEvent with _$UserListEvent {
  /// Loads the full user roster of [organizationId] — dispatched once,
  /// right when `UserListPage` is built.
  const factory UserListEvent.started(String organizationId) = UserListStarted;

  /// Reloads the same roster, e.g. from a retry button after a failure.
  const factory UserListEvent.refreshRequested() = UserListRefreshRequested;

  /// The (already debounced by `AppSearchField`) search box changed —
  /// matched against name/e-mail, case-insensitively. Resets pagination
  /// back to the first page.
  const factory UserListEvent.searchChanged(String query) =
      UserListSearchChanged;

  /// Narrows the roster to one system role code (e.g. `'OWNER'`), or clears
  /// the filter with `null`. Resets pagination back to the first page.
  const factory UserListEvent.roleFilterChanged(String? roleName) =
      UserListRoleFilterChanged;

  /// Narrows the roster to one [MembershipStatus], or clears the filter
  /// with `null`. Resets pagination back to the first page.
  const factory UserListEvent.statusFilterChanged(MembershipStatus? status) =
      UserListStatusFilterChanged;

  /// Reveals one more page of the already-loaded, already-filtered roster
  /// (`AppPagination`'s "carregar mais") — never triggers a new Firestore
  /// read, see `UserListBloc`'s own docs for why.
  const factory UserListEvent.loadMoreRequested() = UserListLoadMoreRequested;
}
