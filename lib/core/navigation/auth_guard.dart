import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Extension point for authentication redirection.
///
/// Every route that requires a signed-in user is protected exclusively
/// through the `redirect` wired in `AppRouter` — never by a feature
/// reimplementing its own auth check. [SessionAuthGuard] (TASK-041) is the
/// real implementation, backed by `SessionService`; it is wired explicitly
/// at the composition root (`VestiProApp`, `lib/app/bootstrap.dart`), the
/// same way [PermissionAuthorizationGuard] is wired per-route instead of
/// changing `AppRouter`'s own default.
///
/// Returns `FutureOr<String?>` (not a plain `String?`) because deciding
/// whether a session is still valid may require an actual token refresh
/// round-trip (see [SessionService.ensureSessionIsActive]), the same
/// asynchronous shape `AuthorizationGuard` already uses for its own
/// permission check.
abstract class AuthGuard {
  /// Returns the location to redirect to when [state] is not allowed, or
  /// `null` when navigation may proceed.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

/// Stub used wherever a route does not yet wire a real [SessionAuthGuard].
/// Always allows navigation.
final class AlwaysAllowAuthGuard implements AuthGuard {
  const AlwaysAllowAuthGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}
