import '../dtos/completed_sso_login_dto.dart';
import '../dtos/sso_login_route_dto.dart';

/// Contract for the two login-time corporate SSO Cloud Functions
/// (TASK-173): `resolveSsoForEmail` (no authentication required) and
/// `completeSsoLogin` (requires one). Always Cloud Function calls — no
/// Firestore read of `ssoConnections` ever happens directly here (see
/// `firestore.rules`: that collection is `if false` for every client, by
/// any role, unconditionally).
abstract interface class SsoDataSource {
  Future<SsoLoginRouteDto> resolveConnectionForEmail({required String email});

  Future<CompletedSsoLoginDto> completeSsoLogin();
}
