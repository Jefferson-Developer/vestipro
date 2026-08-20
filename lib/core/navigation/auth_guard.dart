import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Extension point for authentication redirection.
///
/// Every route that requires a signed-in user is protected exclusively
/// through the `redirect` wired in `AppRouter` — never by a feature
/// reimplementing its own auth check. TASK-041 (persistent session, logout
/// and revocation) replaces [AlwaysAllowAuthGuard] with a guard backed by
/// real session state, without requiring any route declaration to change.
abstract class AuthGuard {
  /// Returns the location to redirect to when [state] is not allowed, or
  /// `null` when navigation may proceed.
  String? redirect(BuildContext context, GoRouterState state);
}

/// Stub used until TASK-041 wires a session-aware guard. Always allows
/// navigation.
final class AlwaysAllowAuthGuard implements AuthGuard {
  const AlwaysAllowAuthGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}
