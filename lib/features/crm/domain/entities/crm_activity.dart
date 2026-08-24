import 'package:collection/collection.dart';

import '../value_objects/crm_activity_sync_status.dart';
import '../value_objects/crm_activity_type.dart';

final class CrmActivity {
  const CrmActivity({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.type,
    this.customerId,
    this.leadId,
    this.opportunityId,
    required this.userId,
    required this.occurredAt,
    required this.description,
    this.durationMinutes,
    this.attachmentUrls = const <String>[],
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String organizationId;
  final String? companyId;
  final CrmActivityType type;
  final String? customerId;
  final String? leadId;
  final String? opportunityId;
  final String userId;
  final DateTime occurredAt;
  final String description;
  final int? durationMinutes;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final CrmActivitySyncStatus syncStatus;

  bool get hasRequiredLink =>
      _hasText(customerId) || _hasText(leadId) || _hasText(opportunityId);

  bool get isPendingSync => syncStatus != CrmActivitySyncStatus.synced;

  CrmActivity copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    bool clearCompanyId = false,
    CrmActivityType? type,
    String? customerId,
    bool clearCustomerId = false,
    String? leadId,
    bool clearLeadId = false,
    String? opportunityId,
    bool clearOpportunityId = false,
    String? userId,
    DateTime? occurredAt,
    String? description,
    int? durationMinutes,
    bool clearDurationMinutes = false,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
    CrmActivitySyncStatus? syncStatus,
  }) {
    return CrmActivity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: clearCompanyId ? null : companyId ?? this.companyId,
      type: type ?? this.type,
      customerId: clearCustomerId ? null : customerId ?? this.customerId,
      leadId: clearLeadId ? null : leadId ?? this.leadId,
      opportunityId: clearOpportunityId
          ? null
          : opportunityId ?? this.opportunityId,
      userId: userId ?? this.userId,
      occurredAt: occurredAt ?? this.occurredAt,
      description: description ?? this.description,
      durationMinutes: clearDurationMinutes
          ? null
          : durationMinutes ?? this.durationMinutes,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CrmActivity &&
            other.id == id &&
            other.organizationId == organizationId &&
            other.companyId == companyId &&
            other.type == type &&
            other.customerId == customerId &&
            other.leadId == leadId &&
            other.opportunityId == opportunityId &&
            other.userId == userId &&
            other.occurredAt == occurredAt &&
            other.description == description &&
            other.durationMinutes == durationMinutes &&
            const ListEquality<String>().equals(
              other.attachmentUrls,
              attachmentUrls,
            ) &&
            other.createdAt == createdAt &&
            other.createdBy == createdBy &&
            other.updatedAt == updatedAt &&
            other.updatedBy == updatedBy &&
            other.version == version &&
            other.syncStatus == syncStatus;
  }

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    companyId,
    type,
    customerId,
    leadId,
    opportunityId,
    userId,
    occurredAt,
    description,
    durationMinutes,
    const ListEquality<String>().hash(attachmentUrls),
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    version,
    syncStatus,
  );
}
