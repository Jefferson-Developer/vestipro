import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import 'app_route_paths.dart';
import 'auth_guard.dart';

/// Redirects to [LoginRoute] whenever no [SessionUser] is signed in.
///
/// Backed by the real [AuthRepository] session state (TASK-012), this
/// replaces [AlwaysAllowAuthGuard] wherever a route must require a signed-in
/// user. [AppRouter] keeps [AlwaysAllowAuthGuard] as its own default so
/// existing/example routes are unaffected until a feature opts into this
/// guard explicitly.
final class SessionAuthGuard implements AuthGuard {
  const SessionAuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (_authRepository.currentUser != null) return null;
    if (state.uri.path == const LoginRoute().location) return null;
    return const LoginRoute().location;
  }
}
