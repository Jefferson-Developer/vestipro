import '../dtos/membership_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/members/{userId}` documents (TASK-028).
/// [FirestoreMembershipDataSource] is the only implementation today.
abstract interface class MembershipDataSource {
  Future<MembershipDto> create(MembershipDto dto);

  /// Lists every non-deleted Membership document under [organizationId].
  /// Never queries across organizations.
  Future<List<MembershipDto>> listByOrganization(String organizationId);

  /// Returns `null` when no document exists for [userId] under
  /// [organizationId].
  Future<MembershipDto?> getByUser({
    required String organizationId,
    required String userId,
  });

  /// Overwrites only `roleId`, `roleName`, `teamIds`, `status`, `updatedAt`
  /// and `updatedBy` on the existing document identified by
  /// [organizationId]/[userId]; never `organizationId` or `userId`.
  /// `version` is bumped atomically (Firestore `FieldValue.increment(1)`),
  /// never taken from the caller.
  Future<MembershipDto> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  });

  /// Every non-deleted, `active` Membership document belonging to [userId],
  /// across every Organization (a Firestore collection-group query on
  /// `members` filtered by `userId`) — see [MembershipRepository]'s own docs
  /// for why this is the one method not scoped by `organizationId`.
  Future<List<MembershipDto>> listActiveByUser(String userId);
}
