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
  /// Creates the Organization identified by [id] if it does not exist yet.
  ///
  /// Idempotent: retrying with the same [id] after a network failure (e.g.
  /// an Outbox retry ahead of TASK-037) returns the Organization already
  /// created instead of creating a duplicate or failing with a conflict.
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
