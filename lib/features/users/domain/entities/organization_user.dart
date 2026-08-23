import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/membership_status.dart';

part 'organization_user.freezed.dart';

/// One row of the administrative user roster (`UserListPage`, TASK-042):
/// [Membership] joined with its denormalized display fields and, when
/// resolvable, the names of the [Team]s it belongs to.
///
/// [ListOrganizationUsersUseCase] is the only place that builds this entity
/// — `UserListPage`/`UserListBloc` never read `Membership`/`Team` directly,
/// so there is exactly one place that knows how to join them.
@freezed
abstract class OrganizationUser with _$OrganizationUser {
  const factory OrganizationUser({
    required String userId,

    /// Never blank: falls back to [userId] when the denormalized
    /// `Membership.name` is missing (e.g. a Membership created before
    /// TASK-042 denormalized it) — see [ListOrganizationUsersUseCase].
    required String name,

    /// Never blank: falls back to an empty string only when the
    /// denormalized `Membership.email` is missing; `UserListPage` renders
    /// that as an explicit "—", never a raw empty cell.
    required String email,

    /// The raw system role code (e.g. `'OWNER'`), exactly as stored on
    /// `Membership.roleName` — never re-validated here.
    required String roleName,
    required MembershipStatus status,
    @Default(<String>[]) List<String> teamIds,

    /// Resolved [Team.name]s for every id in [teamIds] that still exists
    /// (non-deleted) in the organization — shorter than [teamIds] whenever
    /// a team was deleted or could not be loaded; never throws for that.
    @Default(<String>[]) List<String> teamNames,
  }) = _OrganizationUser;
}
