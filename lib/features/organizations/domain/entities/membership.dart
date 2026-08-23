import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/membership_status.dart';

part 'membership.freezed.dart';

/// The user-organization-role link (`tasks.md`, seção 3.3): every user only
/// has access to an [Organization] through an explicit [Membership] — no
/// other code path may ever infer it.
///
/// Stored at `organizations/{organizationId}/members/{userId}`, so [id] is
/// always equal to [userId]. [organizationId] and [userId] are assigned
/// once, at creation, and are never changed afterwards: moving a user to
/// another Organization means creating a brand new [Membership], never
/// editing this one. [MembershipRepository.update] only ever touches
/// [roleId], [roleName], [teamIds], [status] and audit metadata.
///
/// [name]/[email] (TASK-042) are a denormalized snapshot of the user's
/// `users/{uid}` profile, written once by the `createOrganization`/
/// `acceptInvite` Cloud Functions at Membership-creation time — never by any
/// client write, and never kept in sync with a later profile edit (there is
/// no such edit flow yet either). They exist purely so `UserListPage` can
/// render a name/e-mail per row without the client ever reading another
/// user's `users/{uid}` profile directly, which `firestore.rules` denies
/// (`allow get: if request.auth.uid == userId; allow list: if false;`).
/// Nullable/optional so every Membership built before this field existed
/// (or by a test fixture that does not care) keeps compiling and decoding
/// unchanged — a `null` is rendered as a graceful fallback by
/// `ListOrganizationUsersUseCase`, never as a crash.
@freezed
abstract class Membership with _$Membership {
  const factory Membership({
    required String id,
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    @Default(<String>[]) List<String> teamIds,
    required MembershipStatus status,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    String? name,
    String? email,
  }) = _Membership;
}
