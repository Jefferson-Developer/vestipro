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
  }) = _Membership;
}
