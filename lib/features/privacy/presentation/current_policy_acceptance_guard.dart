import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/utils/utils.dart';
import '../domain/usecases/policy_acceptance_use_cases.dart';

final class CurrentPolicyAcceptanceGuard implements PolicyAcceptanceGuard {
  const CurrentPolicyAcceptanceGuard(this._authRepository, this._evaluate);

  final AuthRepository _authRepository;
  final EvaluatePolicyAcceptanceUseCase _evaluate;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final path = state.uri.path;
    if (path == LoginRoute.pathPattern ||
        path == SignUpRoute.pathPattern ||
        path == PasswordResetRoute.pathPattern ||
        path == TermsOfServiceRoute.pathPattern ||
        path == PolicyAcceptanceRoute.pathPattern ||
        path.startsWith('/invite/') ||
        path.startsWith('/share/')) {
      return null;
    }
    final user = _authRepository.currentUser;
    if (user == null) return null;
    final result = await _evaluate(user.uid);
    return switch (result) {
      AppSuccess<PolicyAcceptanceRequirement>(:final value) =>
        value.isSatisfied
            ? null
            : PolicyAcceptanceRoute(returnTo: state.uri.toString()).location,
      AppFailure<PolicyAcceptanceRequirement>() => PolicyAcceptanceRoute(
        returnTo: state.uri.toString(),
      ).location,
    };
  }
}
