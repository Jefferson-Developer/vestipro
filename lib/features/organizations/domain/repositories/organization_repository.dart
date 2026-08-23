import '../../../../core/utils/utils.dart';
import '../entities/organization.dart';
import '../value_objects/organization_settings.dart';

/// Contract for reading and writing the [Organization] tenant root
/// (TASK-026).
///
/// Deliberately narrow: there is no generic `update`, so nothing outside
/// this contract can rewrite [Organization.id] or an arbitrary field —
/// only [create], [getById] and [updateSettings] exist.
abstract interface class OrganizationRepository {
  /// Creates the Organization identified by [id] if it does not exist yet,
  /// via the `createOrganization` callable Cloud Function (TASK-037) —
  /// never by writing to Firestore directly, which `firestore.rules` denies
  /// for the client since that task. The Function also seeds the 7 system
  /// roles and grants [createdBy] the `OWNER` Membership in the same
  /// server-side transaction, none of which this contract exposes: callers
  /// only ever see the created [Organization] itself.
  ///
  /// Idempotent: retrying with the same [id] after a network failure (e.g.
  /// an Outbox retry) returns the Organization already created instead of
  /// creating a duplicate or failing with a conflict — and, more strongly,
  /// the Function's own idempotency does not even depend on [id] staying
  /// the same across retries, since it tracks "does [createdBy] already own
  /// an Organization" independently of the requested id (see the Function's
  /// docs for why).
  Future<AppResult<Organization>> create({
    required String id,
    required String name,
    required String slug,
    required OrganizationSettings settings,
    required String createdBy,
  });

  Future<AppResult<Organization>> getById(String id);

  /// Updates only [Organization.settings] and audit fields (`updatedAt`,
  /// `updatedBy`) of the Organization identified by [id]. Never accepts nor
  /// changes [Organization.id].
  Future<AppResult<Organization>> updateSettings({
    required String id,
    required OrganizationSettings settings,
    required String updatedBy,
  });
}
