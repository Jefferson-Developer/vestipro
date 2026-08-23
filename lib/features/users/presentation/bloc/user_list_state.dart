import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../domain/entities/organization_user.dart';

part 'user_list_state.freezed.dart';

/// The load outcome of `UserListPage`'s roster — same three-way shape as
/// `InviteListState`/every other list screen in this app (loading/ready
/// never hides a partial failure behind a silently-empty list).
enum UserListLoadStatus { loading, ready, failure }

/// Default page size for [UserListState.visibleCount] (`AppPagination`'s
/// "carregar mais").
const int kUserListPageSize = 20;

@freezed
abstract class UserListState with _$UserListState {
  const factory UserListState({
    @Default(UserListLoadStatus.loading) UserListLoadStatus loadStatus,
    @Default('') String organizationId,

    /// Every user of the organization, unfiltered and unpaginated — the
    /// single result of [ListOrganizationUsersUseCase]. `UserListBloc`
    /// applies [searchQuery]/[roleFilter]/[statusFilter] and pagination
    /// entirely in memory on top of this list: an internal (not a raw
    /// Firestore) roster is the only way to search by name/e-mail at all,
    /// since `Membership`/`users/{uid}` cannot be joined by a Firestore
    /// query — see `ListOrganizationUsersUseCase`'s own docs.
    @Default(<OrganizationUser>[]) List<OrganizationUser> allUsers,

    /// Only meaningful when [loadStatus] is [UserListLoadStatus.failure].
    Failure? loadFailure,
    @Default('') String searchQuery,
    String? roleFilter,
    MembershipStatus? statusFilter,

    /// How many of [filteredUsers] are currently revealed
    /// (`AppPagination`'s "carregar mais"). Reset to [kUserListPageSize]
    /// whenever [searchQuery]/[roleFilter]/[statusFilter] changes.
    @Default(kUserListPageSize) int visibleCount,
  }) = _UserListState;

  const UserListState._();

  /// [allUsers] narrowed by [searchQuery] (matched against name/e-mail,
  /// case-insensitively) and [roleFilter]/[statusFilter] (combinable) —
  /// always recomputed from [allUsers], never stored separately, so it can
  /// never drift out of sync with it.
  List<OrganizationUser> get filteredUsers {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return allUsers
        .where((user) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              user.name.toLowerCase().contains(normalizedQuery) ||
              user.email.toLowerCase().contains(normalizedQuery);
          final matchesRole = roleFilter == null || user.roleName == roleFilter;
          final matchesStatus =
              statusFilter == null || user.status == statusFilter;
          return matchesQuery && matchesRole && matchesStatus;
        })
        .toList(growable: false);
  }

  /// The page of [filteredUsers] currently rendered by `AppDataTable`.
  List<OrganizationUser> get visibleUsers =>
      filteredUsers.take(visibleCount).toList(growable: false);

  /// Whether `AppPagination` should still offer "carregar mais".
  bool get hasMore => visibleCount < filteredUsers.length;
}
