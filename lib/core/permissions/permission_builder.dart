import 'package:flutter/widgets.dart';

import 'capability.dart';
import 'permission_service.dart';

/// Widget-level counterpart of `AuthorizationGuard`
/// (`lib/core/navigation/authorization_guard.dart`): hides or disables a
/// sensitive action in the UI when the signed-in user is not granted
/// [capability] inside [organizationId], resolved live through
/// [permissionService] — never assumed from a cached role shown elsewhere
/// on screen.
///
/// Like every other UI-side RBAC check in VestiPro, `granted == true` here
/// only means "show/enable this widget". It is **never**, by itself,
/// authorization to perform the underlying action: the corresponding use
/// case and its Cloud Function/Firestore Security Rule (TASK-030) must
/// re-validate the same [Capability] independently before the action
/// actually runs.
class PermissionBuilder extends StatelessWidget {
  const PermissionBuilder({
    super.key,
    required this.permissionService,
    required this.organizationId,
    required this.userId,
    required this.capability,
    required this.builder,
    this.placeholderBuilder,
  });

  final PermissionService permissionService;
  final String organizationId;
  final String userId;
  final Capability capability;

  /// Called with `granted == true` only once [permissionService] confirms
  /// the capability; called with `false` on any resolution failure and
  /// whenever the capability is actually denied. Callers that need to tell
  /// "loading" apart from "denied" should use [placeholderBuilder] instead
  /// of branching inside [builder].
  final Widget Function(BuildContext context, bool granted) builder;

  /// Shown while the permission check is still in flight. Defaults to
  /// `builder(context, false)`, so a slow/offline check never flashes a
  /// sensitive action before it is confirmed granted.
  final WidgetBuilder? placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _resolveGranted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return placeholderBuilder?.call(context) ?? builder(context, false);
        }
        return builder(context, snapshot.data!);
      },
    );
  }

  Future<bool> _resolveGranted() {
    return permissionService
        .hasPermission(
          organizationId: organizationId,
          userId: userId,
          capability: capability,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
  }
}
