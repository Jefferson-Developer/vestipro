import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import '../permissions/permissions.dart';
import 'app_route_paths.dart';
import 'authorization_guard.dart';

/// Redirects to [ForbiddenRoute] whenever the signed-in user's Membership in
/// the organization being navigated to (`state.pathParameters['orgId']`)
/// does not grant the route's [Capability] (`PermissionService`, TASK-029).
///
/// Fails closed: no signed-in session, a missing/blank `orgId` path
/// parameter, or a [PermissionService] failure (e.g. offline before the
/// Membership was ever cached locally) are all treated as "not granted",
/// never as "allow". Real authorization still lives server-side (TASK-030)
/// — this guard only improves the UX around an already-enforced backend
/// rule, it never replaces it.
final class PermissionAuthorizationGuard implements AuthorizationGuard {
  const PermissionAuthorizationGuard(
    this._permissionService,
    this._authRepository,
  );

  final PermissionService _permissionService;
  final AuthRepository _authRepository;

  @override
  Future<String?> redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) async {
    final currentUser = _authRepository.currentUser;
    final organizationId = state.pathParameters['orgId'];

    if (currentUser == null ||
        organizationId == null ||
        organizationId.isEmpty) {
      return const ForbiddenRoute().location;
    }

    final result = await _permissionService.hasPermission(
      organizationId: organizationId,
      userId: currentUser.uid,
      capability: requiredCapability,
    );

    return result.fold(
      onSuccess: (granted) => granted ? null : const ForbiddenRoute().location,
      onFailure: (_) => const ForbiddenRoute().location,
    );
  }
}
