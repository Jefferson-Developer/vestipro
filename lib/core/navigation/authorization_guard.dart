import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../permissions/permissions.dart';

/// Extension point for capability-based redirection (RBAC, TASK-029).
///
/// Unlike [AuthGuard]/`ActiveOrganizationGuard` — which every route shares
/// through `AppRouter`'s single global redirect chain — an
/// [AuthorizationGuard] is capability-specific: each protected [GoRoute]
/// wires it directly through its own `redirect`, passing the [Capability]
/// that particular route requires, e.g.:
///
/// ```dart
/// GoRoute(
///   path: '/org/:orgId/customers/:customerId/delete',
///   redirect: (context, state) => authorizationGuard.redirect(
///     context,
///     state,
///     requiredCapability: Capability.customerDelete,
///   ),
///   ...
/// )
/// ```
///
/// Hiding/disabling the action that would have triggered this navigation in
/// the first place (see `PermissionBuilder` in `lib/core/permissions/`) is a
/// UX nicety only — this guard, like the `PermissionService` it is built
/// on, is never a substitute for the server-side (Cloud Function/Firestore
/// Security Rule, TASK-030) authorization check every sensitive write must
/// also pass independently.
abstract interface class AuthorizationGuard {
  /// Returns the location to redirect to when the signed-in user is not
  /// granted [requiredCapability] in the organization [state] navigates to,
  /// or `null` when navigation may proceed.
  FutureOr<String?> redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  });
}

/// Stub used wherever a route does not yet wire a real
/// `PermissionAuthorizationGuard`. Always allows navigation.
final class AlwaysAllowAuthorizationGuard implements AuthorizationGuard {
  const AlwaysAllowAuthorizationGuard();

  @override
  FutureOr<String?> redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) => null;
}
