import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/productImportTemplates/{id}` (TASK-168).
final class ProductImportTemplateDto {
  const ProductImportTemplateDto({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.hasHeaderRow,
    required this.columnByField,
    required this.sizeGridTemplateId,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory ProductImportTemplateDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final name = json['name'];
    final hasHeaderRow = json['hasHeaderRow'];
    final columnByField = json['columnByField'];
    final sizeGridTemplateId = json['sizeGridTemplateId'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];

    if (organizationId is! String ||
        name is! String ||
        hasHeaderRow is! bool ||
        columnByField is! Map ||
        sizeGridTemplateId is! String ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String) {
      throw const ValidationException(
        'Invalid product import template payload.',
        code: 'invalid_product_import_template_payload',
      );
    }

    final mapping = <String, int>{};
    columnByField.forEach((key, value) {
      if (key is! String || value is! int) {
        throw const ValidationException(
          'Invalid product import template mapping payload.',
          code: 'invalid_product_import_template_payload',
        );
      }
      mapping[key] = value;
    });

    return ProductImportTemplateDto(
      id: id,
      organizationId: organizationId,
      name: name,
      hasHeaderRow: hasHeaderRow,
      columnByField: mapping,
      sizeGridTemplateId: sizeGridTemplateId,
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
  final String sizeGridTemplateId;
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
      'sizeGridTemplateId': sizeGridTemplateId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}
