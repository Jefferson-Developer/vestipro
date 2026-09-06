import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/productImportJobs/{id}` (TASK-168) — only
/// ever written by `startProductImportJob`/`processProductImportJob` (Cloud
/// Functions, Admin SDK); the client only reads it.
final class ProductImportJobDto {
  const ProductImportJobDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.fileName,
    required this.storagePath,
    this.imagesFolderPath,
    this.reportStoragePath,
    this.templateId,
    required this.hasHeaderRow,
    required this.columnByField,
    required this.sizeGridTemplateId,
    required this.status,
    this.totalRows,
    required this.processedRows,
    required this.createdProductsCount,
    required this.createdVariantsCount,
    required this.imagesAssociatedCount,
    required this.imagesOrphanCount,
    required this.rejectedCount,
    this.errorMessage,
    required this.createdAt,
    required this.createdBy,
    this.startedAt,
    this.completedAt,
  });

  factory ProductImportJobDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final fileName = json['fileName'];
    final storagePath = json['storagePath'];
    final imagesFolderPath = json['imagesFolderPath'];
    final reportStoragePath = json['reportStoragePath'];
    final templateId = json['templateId'];
    final mapping = json['mapping'];
    final status = json['status'];
    final totalRows = json['totalRows'];
    final processedRows = json['processedRows'];
    final createdProductsCount = json['createdProductsCount'];
    final createdVariantsCount = json['createdVariantsCount'];
    final imagesAssociatedCount = json['imagesAssociatedCount'];
    final imagesOrphanCount = json['imagesOrphanCount'];
    final rejectedCount = json['rejectedCount'];
    final errorMessage = json['errorMessage'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final startedAt = json['startedAt'];
    final completedAt = json['completedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        fileName is! String ||
        storagePath is! String ||
        (imagesFolderPath != null && imagesFolderPath is! String) ||
        (reportStoragePath != null && reportStoragePath is! String) ||
        (templateId != null && templateId is! String) ||
        mapping is! Map ||
        mapping['hasHeaderRow'] is! bool ||
        mapping['columnByField'] is! Map ||
        mapping['sizeGridTemplateId'] is! String ||
        status is! String ||
        (totalRows != null && totalRows is! int) ||
        processedRows is! int ||
        createdProductsCount is! int ||
        createdVariantsCount is! int ||
        imagesAssociatedCount is! int ||
        imagesOrphanCount is! int ||
        rejectedCount is! int ||
        (errorMessage != null && errorMessage is! String) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        (startedAt != null && startedAt is! Timestamp) ||
        (completedAt != null && completedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid product import job payload.',
        code: 'invalid_product_import_job_payload',
      );
    }

    final columnByField = <String, int>{};
    (mapping['columnByField'] as Map).forEach((key, value) {
      if (key is! String || value is! int) {
        throw const ValidationException(
          'Invalid product import job mapping payload.',
          code: 'invalid_product_import_job_payload',
        );
      }
      columnByField[key] = value;
    });

    return ProductImportJobDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      fileName: fileName,
      storagePath: storagePath,
      imagesFolderPath: imagesFolderPath as String?,
      reportStoragePath: reportStoragePath as String?,
      templateId: templateId as String?,
      hasHeaderRow: mapping['hasHeaderRow'] as bool,
      columnByField: columnByField,
      sizeGridTemplateId: mapping['sizeGridTemplateId'] as String,
      status: status,
      totalRows: totalRows as int?,
      processedRows: processedRows,
      createdProductsCount: createdProductsCount,
      createdVariantsCount: createdVariantsCount,
      imagesAssociatedCount: imagesAssociatedCount,
      imagesOrphanCount: imagesOrphanCount,
      rejectedCount: rejectedCount,
      errorMessage: errorMessage as String?,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      startedAt: (startedAt as Timestamp?)?.toDate(),
      completedAt: (completedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String fileName;
  final String storagePath;
  final String? imagesFolderPath;
  final String? reportStoragePath;
  final String? templateId;
  final bool hasHeaderRow;
  final Map<String, int> columnByField;
  final String sizeGridTemplateId;
  final String status;
  final int? totalRows;
  final int processedRows;
  final int createdProductsCount;
  final int createdVariantsCount;
  final int imagesAssociatedCount;
  final int imagesOrphanCount;
  final int rejectedCount;
  final String? errorMessage;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'fileName': fileName,
      'storagePath': storagePath,
      'imagesFolderPath': imagesFolderPath,
      'reportStoragePath': reportStoragePath,
      'templateId': templateId,
      'mapping': <String, dynamic>{
        'hasHeaderRow': hasHeaderRow,
        'columnByField': columnByField,
        'sizeGridTemplateId': sizeGridTemplateId,
      },
      'status': status,
      'totalRows': totalRows,
      'processedRows': processedRows,
      'createdProductsCount': createdProductsCount,
      'createdVariantsCount': createdVariantsCount,
      'imagesAssociatedCount': imagesAssociatedCount,
      'imagesOrphanCount': imagesOrphanCount,
      'rejectedCount': rejectedCount,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'startedAt': startedAt == null ? null : Timestamp.fromDate(startedAt!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
    };
  }
}
