import 'package:injectable/injectable.dart';

import '../../features/organizations/domain/repositories/membership_repository.dart';
import '../../features/organizations/domain/value_objects/membership_status.dart';
import '../errors/errors.dart';
import '../utils/utils.dart';
import 'capability.dart';
import 'role_permission_matrix.dart';

/// Resolves which [Capability]s a user is granted inside one Organization,
/// from their real `Membership`/role (`tasks.md`, seção 3.3; TASK-029) —
/// never from any role or `organizationId` the client claims out-of-band.
///
/// This is the layer `AuthorizationGuard` (routes) and `PermissionBuilder`
/// (widgets) both delegate to so no screen ever reimplements its own
/// authorization check. Resolving `true` for a [Capability] only means the
/// UI is allowed to show/enable the corresponding action — it is **never**
/// a substitute for server-side authorization: every sensitive capability
/// this resolves must also be independently re-validated by a Cloud
/// Function/Firestore Security Rule (TASK-030) against the same user's real
/// Membership.
///
/// Deliberately does not cache the resolved Membership/capabilities across
/// calls: every check re-reads [MembershipRepository.getByUser], so a role
/// change (`AssignRoleToUserUseCase`) is reflected starting on the very
/// next check, with no invalidation logic to get wrong.
@lazySingleton
final class PermissionService {
  const PermissionService(this._membershipRepository);

  final MembershipRepository _membershipRepository;

  /// All [Capability]s granted to [userId] inside [organizationId] right
  /// now. A missing Membership, or one whose [MembershipStatus] is
  /// [MembershipStatus.inactive], both resolve to an empty (default-deny)
  /// set on the `AppSuccess` branch — only a repository failure other than
  /// "not found" propagates as an `AppFailure`, so callers can tell
  /// "denied" apart from "could not check".
  Future<AppResult<Set<Capability>>> resolveCapabilities({
    required String organizationId,
    required String userId,
  }) async {
    final membershipResult = await _membershipRepository.getByUser(
      organizationId: organizationId,
      userId: userId,
    );

    return membershipResult.fold(
      onSuccess: (membership) {
        if (membership.status != MembershipStatus.active) {
          return const AppSuccess<Set<Capability>>(<Capability>{});
        }
        return AppSuccess<Set<Capability>>(
          RolePermissionMatrix.capabilitiesForRoleName(membership.roleName),
        );
      },
      onFailure: (failure) {
        if (failure is NotFoundFailure) {
          return const AppSuccess<Set<Capability>>(<Capability>{});
        }
        return AppFailure<Set<Capability>>(failure);
      },
    );
  }

  /// Whether [userId] is granted [capability] inside [organizationId].
  Future<AppResult<bool>> hasPermission({
    required String organizationId,
    required String userId,
    required Capability capability,
  }) async {
    final result = await resolveCapabilities(
      organizationId: organizationId,
      userId: userId,
    );

    return result.fold(
      onSuccess: (capabilities) =>
          AppSuccess<bool>(capabilities.contains(capability)),
      onFailure: AppFailure<bool>.new,
    );
  }

  /// Whether [userId] is granted at least one of [capabilities] inside
  /// [organizationId].
  Future<AppResult<bool>> hasAnyPermission({
    required String organizationId,
    required String userId,
    required List<Capability> capabilities,
  }) async {
    final result = await resolveCapabilities(
      organizationId: organizationId,
      userId: userId,
    );

    return result.fold(
      onSuccess: (granted) =>
          AppSuccess<bool>(capabilities.any(granted.contains)),
      onFailure: AppFailure<bool>.new,
    );
  }
}
