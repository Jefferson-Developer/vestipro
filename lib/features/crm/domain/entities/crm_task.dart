import 'package:collection/collection.dart';

import '../value_objects/crm_task_priority.dart';
import '../value_objects/crm_task_status.dart';
import '../value_objects/crm_task_sync_status.dart';

final class CrmTask {
  const CrmTask({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.title,
    this.description,
    this.customerId,
    this.leadId,
    this.opportunityId,
    this.activityId,
    required this.responsibleUserId,
    required this.dueAt,
    required this.priority,
    required this.status,
    this.completedAt,
    this.previousDueDates = const <DateTime>[],
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
  final String title;
  final String? description;
  final String? customerId;
  final String? leadId;
  final String? opportunityId;
  final String? activityId;
  final String responsibleUserId;
  final DateTime dueAt;
  final CrmTaskPriority priority;
  final CrmTaskStatus status;
  final DateTime? completedAt;
  final List<DateTime> previousDueDates;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final CrmTaskSyncStatus syncStatus;

  bool isOverdue(DateTime now) {
    return status == CrmTaskStatus.pending && dueAt.isBefore(now.toUtc());
  }

  bool canBeChangedBy({
    required String actorUserId,
    required bool actorCanManageOthers,
  }) {
    return actorCanManageOthers || responsibleUserId == actorUserId.trim();
  }

  CrmTask copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    bool clearCompanyId = false,
    String? title,
    String? description,
    bool clearDescription = false,
    String? customerId,
    bool clearCustomerId = false,
    String? leadId,
    bool clearLeadId = false,
    String? opportunityId,
    bool clearOpportunityId = false,
    String? activityId,
    bool clearActivityId = false,
    String? responsibleUserId,
    DateTime? dueAt,
    CrmTaskPriority? priority,
    CrmTaskStatus? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<DateTime>? previousDueDates,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
    CrmTaskSyncStatus? syncStatus,
  }) {
    return CrmTask(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: clearCompanyId ? null : companyId ?? this.companyId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      customerId: clearCustomerId ? null : customerId ?? this.customerId,
      leadId: clearLeadId ? null : leadId ?? this.leadId,
      opportunityId: clearOpportunityId
          ? null
          : opportunityId ?? this.opportunityId,
      activityId: clearActivityId ? null : activityId ?? this.activityId,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      previousDueDates: previousDueDates ?? this.previousDueDates,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CrmTask &&
            other.id == id &&
            other.organizationId == organizationId &&
            other.companyId == companyId &&
            other.title == title &&
            other.description == description &&
            other.customerId == customerId &&
            other.leadId == leadId &&
            other.opportunityId == opportunityId &&
            other.activityId == activityId &&
            other.responsibleUserId == responsibleUserId &&
            other.dueAt == dueAt &&
            other.priority == priority &&
            other.status == status &&
            other.completedAt == completedAt &&
            const ListEquality<DateTime>().equals(
              other.previousDueDates,
              previousDueDates,
            ) &&
            other.createdAt == createdAt &&
            other.createdBy == createdBy &&
            other.updatedAt == updatedAt &&
            other.updatedBy == updatedBy &&
            other.version == version &&
            other.syncStatus == syncStatus;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    organizationId,
    companyId,
    title,
    description,
    customerId,
    leadId,
    opportunityId,
    activityId,
    responsibleUserId,
    dueAt,
    priority,
    status,
    completedAt,
    const ListEquality<DateTime>().hash(previousDueDates),
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    version,
    syncStatus,
  ]);
}
