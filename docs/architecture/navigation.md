# VestiPro Navigation

`go_router` is the single navigation mechanism for VestiPro. No feature may create its own
`GoRouter`, navigate through raw `Navigator` calls, or hardcode a route path string inside a
widget — every route is declared in `lib/core/navigation/` and referenced by the typed classes it
exposes.

## Route convention

Every authenticated route lives under the organization-scoped prefix:

```text
/org/:orgId/...
```

Examples this convention anticipates for future features (`tasks.md`, EPIC-06 to EPIC-18):

```text
/org/:orgId/customers/:customerId
/org/:orgId/catalog/:collectionSlug
/org/:orgId/orders/:orderId
/org/:orgId/dashboards/executive
/org/:orgId/reports/:reportId
```

The example module (TASK-004) uses this convention today:

```text
/org/:orgId/settings/about
```

A route is declared once as a type in `lib/core/navigation/app_route_paths.dart`
(`AboutAppRoute`, `ForbiddenRoute`, `NotFoundRoute`), exposing `pathPattern` (for `GoRoute.path`)
and `location` (the resolved path for a concrete instance). Features build the `location` from
their own IDs — never a literal string — so deep links and page reload keep working.

Until a real active organization exists (TASK-026, TASK-037), the router starts at
`kPlaceholderOrganizationId` (`"default"`). This value is not validated by
`ActiveOrganizationGuard` today; it only becomes meaningful once a real active organization can be
resolved.

## Guards

`AppRouter` composes two guard extension points, both evaluated in its `redirect` callback:

- `AuthGuard` (`lib/core/navigation/auth_guard.dart`) — decides whether the signed-in user may
  reach the requested location. `AlwaysAllowAuthGuard` is `AppRouter`'s own default (kept so a
  test/example route is never forced through a real session check); `SessionAuthGuard`
  (TASK-041), backed by `SessionService`, is the real implementation, wired explicitly at the
  composition root (`VestiProApp`, `lib/app/bootstrap.dart`) the same way `PermissionAuthorizationGuard`
  is wired per-route instead of changing `AppRouter`'s own default. `AuthGuard.redirect` returns
  `FutureOr<String?>` because deciding a session is still valid may require an actual token
  refresh round-trip (`SessionService.ensureSessionIsActive`) — same asynchronous shape
  `AuthorizationGuard` already used. `SessionAuthGuard`'s redirect to `LoginRoute` carries
  `returnTo` (the location that was originally requested) and, when an already-signed-in session
  just ended, `reason` (`SessionEndedReason.name`) — both are carried as query parameters only;
  reading them and rendering a "session ended" message is not wired into `LoginPage` yet (no
  front-end agent was in TASK-041's scope), so this is a pending integration point for whichever
  task builds real post-login navigation.
- `ActiveOrganizationGuard` (`lib/core/navigation/active_organization_guard.dart`) — decides
  whether the requested `:orgId` resolves to a valid active organization for the signed-in user.
  `AlwaysAllowActiveOrganizationGuard` is the stub used today; TASK-026/TASK-037 supply the real
  implementation.

Both guards return `null` to allow navigation, or a redirect location (typically
`ForbiddenRoute().location`) to deny it. No feature reimplements this check locally — a feature
that needs protection is simply registered as a route under `AppRouter`.

## Fallback routes

- `ForbiddenPage` (403) is rendered when a guard denies access.
- `NotFoundPage` (404) is rendered by `AppRouter`'s `errorBuilder` for any location that matches no
  declared route.

Both are intentionally generic `Scaffold` pages; they will be replaced by dedicated Design System
empty-state components once EPIC-02 ships one.

## Deep links and Flutter Web

- `bootstrap()` calls `usePathUrlStrategy()` so Flutter Web serves clean paths (no `#`) and
  preserves the current route across a page reload.
- Route parameters are passed as IDs (`:orgId`, `:customerId`, ...), never as serialized objects,
  so a reloaded page can resolve the same screen from the URL alone.
- List-style routes may carry filters as query parameters (`state.uri.queryParameters`); `go_router`
  already supports this, so a future listing feature does not need to invent its own mechanism.

### Native deep links (pending)

Android intent-filters and iOS associated domains for universal/app links are **not activated
yet** — VestiPro does not have a production domain configured. `android/app/src/main/AndroidManifest.xml`
and `ios/Runner/Info.plist` carry a commented skeleton documenting the shape those entries will
take once a domain is available. This is a documented pendency, not a regression: in-app
navigation (including Flutter Web deep links) is fully functional without it.

## Example module wiring

`AppRouter` receives the example module's page builder from the composition root
(`lib/app/bootstrap.dart`), not by importing the `settings` feature directly — `lib/core` never
depends on `lib/features/*`. `VestiProApp` also accepts an optional `AppRouter` override so tests
can inject custom guards or a fake page builder without going through dependency injection.
