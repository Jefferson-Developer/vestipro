import 'package:cloud_firestore/cloud_firestore.dart';

/// `organizations/{organizationId}/logisticsIssues/{logisticsIssueId}`
/// document shape (TASK-214) — mirrors `registerLogisticsIssue`/
/// `resolveLogisticsIssue`/`detectShipmentDelays`'s own write field for
/// field.
final class LogisticsIssueDto {
  const LogisticsIssueDto({
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

  factory LogisticsIssueDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return LogisticsIssueDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      shipmentId: json['shipmentId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      customerId: json['customerId'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      responsibleUserId: json['responsibleUserId'] as String? ?? '',
      nextAction: json['nextAction'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      source: json['source'] as String? ?? 'manual',
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['createdByName'] as String?,
      resolvedAt: _asDate(json['resolvedAt']),
      resolvedBy: json['resolvedBy'] as String?,
      resolutionNote: json['resolutionNote'] as String?,
    );
  }

  final String id;
  final String organizationId;
  final String shipmentId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String type;
  final String description;
  final String responsibleUserId;
  final String nextAction;
  final String status;
  final String source;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNote;

  /// Never actually sent to Firestore (`LogisticsIssue` is read-only from
  /// the client) — kept only for symmetry with [LogisticsIssueDto.fromJson].
  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'shipmentId': shipmentId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'customerId': customerId,
    'sellerId': sellerId,
    'type': type,
    'description': description,
    'responsibleUserId': responsibleUserId,
    'nextAction': nextAction,
    'status': status,
    'source': source,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'createdByName': createdByName,
    'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
    'resolvedBy': resolvedBy,
    'resolutionNote': resolutionNote,
  };
}

DateTime? _asDate(Object? value) => value is Timestamp ? value.toDate() : null;
