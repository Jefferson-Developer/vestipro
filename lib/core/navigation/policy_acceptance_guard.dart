import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract interface class PolicyAcceptanceGuard {
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

final class AlwaysAllowPolicyAcceptanceGuard implements PolicyAcceptanceGuard {
  const AlwaysAllowPolicyAcceptanceGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) => null;
}
