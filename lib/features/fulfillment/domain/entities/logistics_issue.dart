import '../value_objects/logistics_issue_type.dart';

/// One ocorrência logística — atraso, avaria, divergência de volume,
/// endereço inválido ou devolução de transporte (TASK-214, EPIC-32) — always
/// carrying a [responsibleUserId] and [nextAction] (`tasks.md`: "com
/// responsável e próxima ação"), never an empty occurrence record.
///
/// Exclusively written by `registerLogisticsIssue`/`resolveLogisticsIssue`/
/// `detectShipmentDelays` (Cloud Functions) — the UI never mutates one
/// directly, only ever reads it back through
/// [FulfillmentRepository.watchLogisticsIssues].
final class LogisticsIssue {
  const LogisticsIssue({
    required this.id,
    required this.organizationId,
    required this.shipmentId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.type,
    required this.description,
    required this.responsibleUserId,
    required this.nextAction,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.createdBy,
    this.createdByName,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNote,
  });

  final String id;
  final String organizationId;
  final String shipmentId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final LogisticsIssueType type;
  final String description;
  final String responsibleUserId;
  final String nextAction;
  final LogisticsIssueStatus status;

  /// `'manual'` (registrado por vendedor/gestor) ou `'auto'`
  /// (`detectShipmentDelays`, TASK-214).
  final String source;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNote;

  bool get isOpen => status != LogisticsIssueStatus.resolved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogisticsIssue &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.shipmentId == shipmentId &&
          other.orderId == orderId &&
          other.type == type &&
          other.description == description &&
          other.responsibleUserId == responsibleUserId &&
          other.nextAction == nextAction &&
          other.status == status &&
          other.source == source &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy &&
          other.resolvedAt == resolvedAt &&
          other.resolvedBy == resolvedBy &&
          other.resolutionNote == resolutionNote);

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    shipmentId,
    orderId,
    type,
    description,
    responsibleUserId,
    nextAction,
    status,
    source,
    createdAt,
    createdBy,
    Object.hash(resolvedAt, resolvedBy, resolutionNote),
  );
}
