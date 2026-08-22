import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/organization_settings.dart';
import '../value_objects/organization_status.dart';

part 'organization.freezed.dart';

/// Root tenant of VestiPro's multi-tenant model (`tasks.md`, section 3.1).
///
/// Every Company, Branch, Team, Role and business document is scoped under
/// `organizations/{id}` (section 3.2/20 of `tasks.md`). [id] is assigned
/// once, at creation, and is never changed afterwards: [OrganizationRepository]
/// only exposes [OrganizationRepository.create], [OrganizationRepository.getById]
/// and [OrganizationRepository.updateSettings] — none of them can rewrite
/// [id], only [settings] and audit metadata.
@freezed
abstract class Organization with _$Organization {
  const factory Organization({
    required String id,
    required String name,
    required String slug,
    required OrganizationSettings settings,
    required OrganizationStatus status,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Organization;
}
