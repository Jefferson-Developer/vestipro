import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class InsightDto {
  const InsightDto({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.evidence,
    required this.estimatedImpact,
    required this.severity,
    required this.confidenceScore,
    required this.recommendation,
    required this.quickAction,
    required this.secondaryActions,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.generatedAt,
    required this.expiresAt,
    required this.status,
    this.customerId,
    this.productId,
    this.sellerId,
  });

  factory InsightDto.fromJson(Map<String, dynamic> json, {required String id}) {
    String requireString(String field) {
      final value = json[field];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      throw const ValidationException(
        'Invalid insight payload.',
        code: 'invalid_insight_payload',
      );
    }

    Timestamp requireTimestamp(String field) {
      final value = json[field];
      if (value is Timestamp) {
        return value;
      }
      throw const ValidationException(
        'Invalid insight payload.',
        code: 'invalid_insight_payload',
      );
    }

    final evidence = json['evidence'];
    final estimatedImpact = json['estimatedImpact'];
    final quickAction = json['quickAction'];
    final secondaryActions = json['secondaryActions'];
    final confidenceScore = json['confidenceScore'];
    if (evidence is! List<dynamic> ||
        estimatedImpact is! Map<String, dynamic> ||
        quickAction is! Map<String, dynamic> ||
        secondaryActions is! List<dynamic> ||
        confidenceScore is! num) {
      throw const ValidationException(
        'Invalid insight payload.',
        code: 'invalid_insight_payload',
      );
    }

    return InsightDto(
      id: id,
      type: requireString('type'),
      title: requireString('title'),
      description: requireString('description'),
      evidence: List<Map<String, dynamic>>.unmodifiable(
        evidence.map((item) => Map<String, dynamic>.from(item as Map)),
      ),
      estimatedImpact: Map<String, dynamic>.unmodifiable(estimatedImpact),
      severity: requireString('severity'),
      confidenceScore: confidenceScore.toDouble(),
      recommendation: requireString('recommendation'),
      quickAction: Map<String, dynamic>.unmodifiable(quickAction),
      secondaryActions: List<Map<String, dynamic>>.unmodifiable(
        secondaryActions.map((item) => Map<String, dynamic>.from(item as Map)),
      ),
      organizationId: requireString('organizationId'),
      companyId: requireString('companyId'),
      recipientUserId: requireString('recipientUserId'),
      customerId: json['customerId'] as String?,
      productId: json['productId'] as String?,
      sellerId: json['sellerId'] as String?,
      generatedAt: requireTimestamp('generatedAt').toDate(),
      expiresAt: requireTimestamp('expiresAt').toDate(),
      status: requireString('status'),
    );
  }

  final String id;
  final String type;
  final String title;
  final String description;
  final List<Map<String, dynamic>> evidence;
  final Map<String, dynamic> estimatedImpact;
  final String severity;
  final double confidenceScore;
  final String recommendation;
  final Map<String, dynamic> quickAction;
  final List<Map<String, dynamic>> secondaryActions;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String? customerId;
  final String? productId;
  final String? sellerId;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'title': title,
      'description': description,
      'evidence': evidence,
      'estimatedImpact': estimatedImpact,
      'severity': severity,
      'confidenceScore': confidenceScore,
      'recommendation': recommendation,
      'quickAction': quickAction,
      'secondaryActions': secondaryActions,
      'organizationId': organizationId,
      'companyId': companyId,
      'recipientUserId': recipientUserId,
      'customerId': customerId,
      'productId': productId,
      'sellerId': sellerId,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }
}
