/// The federation protocol a corporate SSO connection uses (TASK-173,
/// EPIC-23) — mirrors `functions/src/sso/types.ts`'s own `SsoProtocol`.
/// Drives whether [SignInWithCorporateSsoUseCase] builds a
/// `SAMLAuthProvider` or an `OAuthProvider` before calling
/// `AuthRepository.signInWithFederatedProvider`.
enum SsoProtocol { saml, oidc }
