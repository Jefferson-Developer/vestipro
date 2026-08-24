import '../value_objects/crm_activity_type.dart';
import '../value_objects/next_best_action_priority.dart';
import '../value_objects/next_best_action_type.dart';

final class NextBestAction {
  const NextBestAction({
    required this.id,
    required this.organizationId,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.priority,
    required this.suggestedAction,
    required this.reason,
    required this.evidence,
    required this.createdAt,
    this.relatedTaskId,
    this.suggestedActivityType,
  });

  final String id;
  final String organizationId;
  final String customerId;
  final String customerName;
  final NextBestActionType type;
  final NextBestActionPriority priority;
  final String suggestedAction;
  final String reason;
  final String evidence;
  final DateTime createdAt;
  final String? relatedTaskId;
  final CrmActivityType? suggestedActivityType;

  bool get hasTraceableEvidence =>
      suggestedAction.trim().isNotEmpty &&
      reason.trim().isNotEmpty &&
      evidence.trim().isNotEmpty;
}
