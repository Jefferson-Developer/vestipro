import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/user_access_update_result.dart';

part 'user_list_state.freezed.dart';

/// The load outcome of `UserListPage`'s roster.
enum UserListLoadStatus { loading, ready, failure }

/// The submission lifecycle for TASK-046 access changes.
enum UserListAccessMutationStatus { idle, submitting, success, failure }

/// Default page size for [UserListState.visibleCount].
const int kUserListPageSize = 20;

@freezed
abstract class UserListState with _$UserListState {
  const factory UserListState({
    @Default(UserListLoadStatus.loading) UserListLoadStatus loadStatus,
    @Default('') String organizationId,
    @Default(<OrganizationUser>[]) List<OrganizationUser> allUsers,
    Failure? loadFailure,
    @Default('') String searchQuery,
    String? roleFilter,
    MembershipStatus? statusFilter,
    @Default(kUserListPageSize) int visibleCount,
    @Default(UserListAccessMutationStatus.idle)
    UserListAccessMutationStatus accessMutationStatus,
    OrganizationUser? accessMutationUser,
    Failure? accessMutationFailure,
    UserAccessUpdateResult? accessMutationResult,
  }) = _UserListState;

  const UserListState._();

  /// [allUsers] narrowed by [searchQuery] (matched against name/e-mail,
  /// case-insensitively) and [roleFilter]/[statusFilter].
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
