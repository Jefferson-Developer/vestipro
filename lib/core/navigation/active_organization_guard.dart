import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Extension point for active-organization redirection.
///
/// Guards a route from being reached without a valid active organization in
/// scope. TASK-026 (model Organization) and TASK-037 (create the first
/// Organization) replace [AlwaysAllowActiveOrganizationGuard] with a guard
/// that resolves and validates the `:orgId` path parameter against the
/// signed-in user's real organizations, without requiring any route
/// declaration to change.
abstract class ActiveOrganizationGuard {
  /// Returns the location to redirect to when [state] does not resolve to a
  /// valid active organization, or `null` when navigation may proceed.
  String? redirect(BuildContext context, GoRouterState state);
}

/// Stub used until TASK-026/TASK-037 wire a real organization-aware guard.
/// Always allows navigation.
final class AlwaysAllowActiveOrganizationGuard
    implements ActiveOrganizationGuard {
  const AlwaysAllowActiveOrganizationGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}
