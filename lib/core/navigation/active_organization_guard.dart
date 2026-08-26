import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/organizations/domain/usecases/get_user_membership_use_case.dart';
import '../../features/organizations/domain/usecases/resolve_active_organization_id_use_case.dart';
import '../../features/organizations/domain/value_objects/membership_status.dart';
import '../auth/auth.dart';
import 'app_route_paths.dart';

/// Extension point for active-organization redirection.
///
/// Guards a route from being reached without a valid active organization in
/// scope. TASK-026 (model Organization) and TASK-037 (create the first
/// Organization) replace [AlwaysAllowActiveOrganizationGuard] with a guard
/// that resolves and validates the `:orgId` path parameter against the
/// signed-in user's real organizations, without requiring any route
/// declaration to change.
abstract class ActiveOrganizationGuard {
  /// Returns the location to redirect to when [state] does not resolve to a
  /// valid active organization, or `null` when navigation may proceed.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

/// Stub used until TASK-026/TASK-037 wire a real organization-aware guard.
/// Always allows navigation.
final class AlwaysAllowActiveOrganizationGuard
    implements ActiveOrganizationGuard {
  const AlwaysAllowActiveOrganizationGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}

/// Real [ActiveOrganizationGuard]: validates the `:orgId` path parameter
/// (when the requested route carries one — routes such as [LoginRoute]/
/// [OnboardingWizardRoute] do not, and are always let through) against an
/// active, real Membership of the signed-in user, and self-heals whenever it
/// does not hold.
///
/// This is what actually fixes the "owner gets 'sem permissão'" bug every
/// route used to hit: [kPlaceholderOrganizationId] (`'default'`) was baked
/// into `AppRouter.initialLocation`/`LoginPage`'s post-login redirect/
/// `ForbiddenPage`/`NotFoundPage`, and never matched the real Organization
/// id `CompleteOnboardingUseCase` generates (a fresh UUID) — so
/// `PermissionAuthorizationGuard` always resolved an empty capability set
/// for it, even for the real OWNER. Rather than only deny that stale/wrong
/// `:orgId`, this guard also tries to resolve where the signed-in user
/// actually belongs ([_resolveActiveOrganizationId]) and redirects there —
/// same request path, only the `orgId` segment swapped — so a stale link
/// self-heals into the correct Organization instead of dead-ending on
/// [ForbiddenRoute].
///
/// Fails closed in every other case: no signed-in session, a
/// `GetUserMembershipUseCase`/`ResolveActiveOrganizationIdUseCase` failure
/// (e.g. offline before any Membership was ever cached locally), or a
/// resolved Organization that still does not match the one requested (would
/// otherwise redirect-loop) all redirect to [ForbiddenRoute] — never
/// "allow". Real authorization/tenant-isolation still lives server-side
/// (Firestore Security Rules, TASK-030): this guard only improves the UX
/// around an already-enforced backend rule, it never replaces it.
///
/// Does not attempt to resolve which of several active Memberships is
/// "correct" beyond what [ResolveActiveOrganizationIdUseCase] already
/// deterministically picks — no multi-organization switcher exists yet
/// (out of scope, see `tasks.md`).
final class MembershipActiveOrganizationGuard
    implements ActiveOrganizationGuard {
  const MembershipActiveOrganizationGuard(
    this._authRepository,
    this._getUserMembership,
    this._resolveActiveOrganizationId,
  );

  final AuthRepository _authRepository;
  final GetUserMembershipUseCase _getUserMembership;
  final ResolveActiveOrganizationIdUseCase _resolveActiveOrganizationId;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final requestedOrgId = state.pathParameters['orgId'];
    debugPrint(
      '[DEBUG-GUARD] uri=${state.uri} requestedOrgId=$requestedOrgId',
    );
    // Routes with no `:orgId` segment at all (login, sign-up, onboarding,
    // invite acceptance, forbidden, not-found) are outside this guard's
    // scope by construction — same precedent as `PermissionAuthorizationGuard`
    // only ever running on routes that opt into it.
    if (requestedOrgId == null || requestedOrgId.isEmpty) {
      debugPrint('[DEBUG-GUARD] no orgId segment -> pass through (null)');
      return null;
    }

    final currentUser = _authRepository.currentUser;
    debugPrint('[DEBUG-GUARD] currentUser=${currentUser?.uid}');
    if (currentUser == null) {
      // `SessionAuthGuard` runs first in `AppRouter._redirect` and already
      // handles the unauthenticated case — reached only defensively.
      debugPrint('[DEBUG-GUARD] no currentUser -> LoginRoute');
      return const LoginRoute().location;
    }

    final membershipResult = await _getUserMembership(
      organizationId: requestedOrgId,
      userId: currentUser.uid,
    );
    debugPrint(
      '[DEBUG-GUARD] getUserMembership(org=$requestedOrgId, uid=${currentUser.uid}) '
      '=> ${membershipResult.fold(onSuccess: (m) => 'SUCCESS status=${m.status} roleName=${m.roleName}', onFailure: (f) => 'FAILURE $f')}',
    );
    final isValidActiveMember = membershipResult.fold(
      onSuccess: (membership) => membership.status == MembershipStatus.active,
      onFailure: (_) => false,
    );
    if (isValidActiveMember) {
      debugPrint('[DEBUG-GUARD] isValidActiveMember=true -> pass through');
      return null;
    }

    final resolvedResult = await _resolveActiveOrganizationId(
      userId: currentUser.uid,
    );
    debugPrint(
      '[DEBUG-GUARD] resolveActiveOrganizationId(uid=${currentUser.uid}) '
      '=> ${resolvedResult.fold(onSuccess: (id) => 'SUCCESS realOrgId=$id', onFailure: (f) => 'FAILURE $f')}',
    );

    return resolvedResult.fold(
      onSuccess: (realOrgId) {
        if (realOrgId == null) {
          debugPrint('[DEBUG-GUARD] realOrgId=null -> OnboardingWizardRoute');
          return const OnboardingWizardRoute().location;
        }
        if (realOrgId == requestedOrgId) {
          // The user's own resolved Organization is exactly the one that
          // just failed validation (e.g. a genuinely deactivated
          // Membership) — redirecting again would loop. Fail closed.
          debugPrint(
            '[DEBUG-GUARD] realOrgId == requestedOrgId ($realOrgId) -> ForbiddenRoute (fail closed)',
          );
          return const ForbiddenRoute().location;
        }
        final target = _replaceOrgIdSegment(state.uri, realOrgId).toString();
        debugPrint('[DEBUG-GUARD] self-heal redirect -> $target');
        return target;
      },
      onFailure: (f) {
        debugPrint('[DEBUG-GUARD] resolvedResult FAILURE -> ForbiddenRoute: $f');
        return const ForbiddenRoute().location;
      },
    );
  }

  /// Rebuilds [uri] with its `/org/:orgId/...` segment swapped for
  /// [realOrgId], preserving the rest of the requested path (e.g.
  /// `settings/about`, `catalog`) and every query parameter — so self-heal
  /// lands the user exactly where they were headed, not always on
  /// [CatalogHomeRoute].
  Uri _replaceOrgIdSegment(Uri uri, String realOrgId) {
    final segments = List<String>.of(uri.pathSegments);
    if (segments.length < 2 || segments[0] != 'org') return uri;
    segments[1] = realOrgId;
    return uri.replace(pathSegments: segments);
  }
}
