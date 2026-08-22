/// Public surface of `lib/core/permissions/`: VestiPro's RBAC building
/// blocks (`tasks.md`, seção 3.3; TASK-029) — used by `AuthorizationGuard`
/// (routes) and by every feature that needs to hide/disable an action for a
/// role that does not have the corresponding [Capability].
///
/// A `true` result from anything here is a UX nicety only: the real
/// authorization decision for every sensitive write is (or, once TASK-030
/// exists, will be) re-validated independently by a Cloud Function or
/// Firestore Security Rule.
library;

export 'capability.dart';
export 'permission_builder.dart';
export 'permission_service.dart';
export 'role_permission_matrix.dart';
