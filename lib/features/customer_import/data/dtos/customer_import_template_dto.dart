import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/customerImportTemplates/{id}` (TASK-167).
final class CustomerImportTemplateDto {
  const CustomerImportTemplateDto({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.hasHeaderRow,
    required this.columnByField,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory CustomerImportTemplateDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final name = json['name'];
    final hasHeaderRow = json['hasHeaderRow'];
    final columnByField = json['columnByField'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];

    if (organizationId is! String ||
        name is! String ||
        hasHeaderRow is! bool ||
        columnByField is! Map ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String) {
      throw const ValidationException(
        'Invalid customer import template payload.',
        code: 'invalid_customer_import_template_payload',
      );
    }

    final mapping = <String, int>{};
    columnByField.forEach((key, value) {
      if (key is! String || value is! int) {
        throw const ValidationException(
          'Invalid customer import template mapping payload.',
          code: 'invalid_customer_import_template_payload',
        );
      }
      mapping[key] = value;
    });

    return CustomerImportTemplateDto(
      id: id,
      organizationId: organizationId,
      name: name,
      hasHeaderRow: hasHeaderRow,
      columnByField: mapping,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final bool hasHeaderRow;
  final Map<String, int> columnByField;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'name': name,
      'hasHeaderRow': hasHeaderRow,
      'columnByField': columnByField,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}
