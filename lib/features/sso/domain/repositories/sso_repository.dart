import '../../../../core/utils/utils.dart';
import '../entities/completed_sso_login.dart';
import '../entities/sso_login_route.dart';

/// Contract for the two login-time corporate SSO Cloud Functions
/// (TASK-173): `resolveSsoForEmail` (no authentication required — the whole
/// point is being safe to call *before* anyone is signed in, same rationale
/// `InviteAcceptanceRepository.validate` already documents for
/// `validateInvite`) and `completeSsoLogin` (requires the caller to already
/// be authenticated via a federated SAML/OIDC provider).
///
/// Deliberately never talks to Firestore directly: `organizations/{organizationId}/
/// ssoConnections` is never client-readable at all (`firestore.rules`) —
/// every decision this contract exposes only ever comes from a Cloud
/// Function's own response.
abstract interface class SsoRepository {
  /// Resolves which organization's corporate SSO connection (if any) [email]
  /// routes to. Returns a `null` value inside [AppSuccess] — never an
  /// [AppFailure] — for the ordinary "no SSO configured for this e-mail"
  /// outcome; only a genuine technical failure (network, server error)
  /// surfaces as an [AppFailure].
  Future<AppResult<SsoLoginRoute?>> resolveConnectionForEmail({
    required String email,
  });

  /// Completes a corporate SSO sign-in for the already-authenticated caller
  /// (a federated SAML/OIDC session, started by
  /// `AuthRepository.signInWithFederatedProvider`) — creates/refreshes the
  /// caller's Membership just-in-time, exactly as `completeSsoLogin` (server
  /// side) decides. Requires the caller to already be signed in; enforced
  /// server-side, independent of anything this client-side call assumes.
  Future<AppResult<CompletedSsoLogin>> completeSsoLogin();
}
