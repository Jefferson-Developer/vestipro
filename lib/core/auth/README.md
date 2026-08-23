Authentication session contracts and guards live here.

## Session persistence, logout and revocation (TASK-041)

- `AuthRepository.authStateChanges`/`currentUser` restore the session automatically on app start —
  Firebase Auth's own SDK already persists the real credential (refresh token) natively; nothing
  in this package duplicates that.
- `SecureSessionStore` (`data/datasources/`) persists only the minimal, non-sensitive session
  footprint this app is allowed to keep on disk: the last signed-in user id, via
  `flutter_secure_storage` (Keychain/Keystore/DPAPI-backed). Never a token, never a password.
- `SessionService` (`domain/services/session_service.dart`, impl in `data/services/`) is the
  single place that:
  - `logout()`s cleanly — signs out through `AuthRepository` and clears `SecureSessionStore`
    unconditionally, even if the remote sign-out call itself failed;
  - `ensureSessionIsActive()`s — forces a token refresh (`AuthRepository.refreshSession`) to
    detect an account disabled/deleted or a refresh token revoked remotely (e.g. an admin
    deactivating the user, TASK-046) since the last check. On success, (re)persists the signed-in
    uid in `SecureSessionStore`; only ends the session for a genuine `AuthenticationFailure` with
    a revocation-shaped code (`user-disabled`, `user-token-expired`, `invalid-user-token`,
    `user-not-found`) — clearing `SecureSessionStore` in that case. A connectivity/unexpected
    failure never ends an otherwise-valid session — an offline device keeps working exactly as
    before.
  - Deliberately does **not** touch `SecureSessionStore` from a background
    `authStateChanges` listener: every write is tied to an explicit, already-tested call
    (`logout`, `ensureSessionIsActive`), so merely resolving `SessionService` through DI — e.g. a
    widget test that boots the real app with nobody signed in — never performs any I/O.
- `SessionAuthGuard` (`lib/core/navigation/`) calls `ensureSessionIsActive()` on every navigation
  to a protected route, so a revoked session is caught without depending on the user manually
  reopening the app. Any future repository performing a sensitive authenticated operation may
  also call `SessionService.ensureSessionIsActive()` before proceeding — this is an extension
  point, not something only the router uses.
