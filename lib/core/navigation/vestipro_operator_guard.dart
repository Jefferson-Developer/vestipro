import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_portal/admin_portal.dart';
import 'app_route_paths.dart';

abstract interface class VestiProOperatorGuard {
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

final class AlwaysAllowVestiProOperatorGuard implements VestiProOperatorGuard {
  const AlwaysAllowVestiProOperatorGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}

final class RepositoryVestiProOperatorGuard implements VestiProOperatorGuard {
  const RepositoryVestiProOperatorGuard(this._repository);

  final AdminPortalRepository _repository;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final result = await _repository.resolveOperatorSession();
    return result.fold(
      onSuccess: (session) => session.can(VestiProOperatorPermission.viewPortal)
          ? null
          : const ForbiddenRoute().location,
      onFailure: (_) => const ForbiddenRoute().location,
    );
  }
}
