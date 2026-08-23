import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import '../utils/utils.dart';
import 'app_route_paths.dart';
import 'auth_guard.dart';

/// Redirects to [LoginRoute] whenever no [SessionUser] is signed in, or
/// whenever a previously signed-in session is detected as revoked
/// (TASK-041, via [SessionService.ensureSessionIsActive]).
///
/// Backed by [SessionService] instead of talking to `AuthRepository`
/// directly, so persistence, logout and revocation detection all live in
/// one place. Wired explicitly in `VestiProApp` (`lib/app/bootstrap.dart`)
/// as the real [AuthGuard] — [AppRouter] itself keeps [AlwaysAllowAuthGuard]
/// as its own default so a test/example route is never forced through a
/// real session check.
final class SessionAuthGuard implements AuthGuard {
  const SessionAuthGuard(this._sessionService);

  final SessionService _sessionService;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    // Never redirect a request that is already headed to the login page
    // itself — comparing only `.path` (not the full location) so this
    // still holds once `LoginRoute` carries `returnTo`/`reason` query
    // parameters of its own.
    if (state.uri.path == const LoginRoute().location) return null;

    if (_sessionService.currentUser == null) {
      return LoginRoute(returnTo: state.uri.toString()).location;
    }

    final sessionCheck = await _sessionService.ensureSessionIsActive();
    if (sessionCheck is AppFailure<void>) {
      return LoginRoute(
        returnTo: state.uri.toString(),
        endedSessionReason: SessionEndedReason.revoked,
      ).location;
    }

    return null;
  }
}
