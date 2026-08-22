import '../../../../core/utils/utils.dart';
import '../entities/membership.dart';
import '../value_objects/membership_status.dart';

/// Contract for reading and writing [Membership] documents (the
/// user-organization-role link) scoped under one [Organization] (TASK-028).
///
/// Every method requires [organizationId] so no query can be built without a
/// tenant scope by mistake — Firestore Security Rules (TASK-030) remain the
/// real source of truth for isolation, this is defense-in-depth only.
/// Deliberately narrow: [update] takes no parameter that could rewrite
/// [Membership.organizationId] or [Membership.userId] — moving a user to
/// another Organization means creating a new [Membership], not editing this
/// one.
abstract interface class MembershipRepository {
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  });

  /// Lists every non-deleted Membership of [organizationId]. Never returns a
  /// Membership belonging to a different organization.
  Future<AppResult<List<Membership>>> listByOrganization(String organizationId);

  /// Returns the single [Membership] of [userId] within [organizationId].
  /// There is at most one non-deleted Membership per (organizationId,
  /// userId) pair — [create] always writes to document id [userId].
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  });

  /// Updates only [Membership.roleId], [Membership.roleName],
  /// [Membership.teamIds], [Membership.status] and audit fields of the
  /// Membership identified by [organizationId]/[userId].
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  });
}
