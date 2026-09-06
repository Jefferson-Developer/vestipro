import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/customerImportJobs/{id}` (TASK-167) —
/// only ever written by `startCustomerImportJob`/`processCustomerImportJob`
/// (Cloud Functions, Admin SDK); the client only reads it (see
/// `CustomerImportJobRepository`'s docs).
final class CustomerImportJobDto {
  const CustomerImportJobDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.fileName,
    required this.storagePath,
    this.reportStoragePath,
    this.templateId,
    required this.hasHeaderRow,
    required this.columnByField,
    required this.status,
    this.totalRows,
    required this.processedRows,
    required this.importedCount,
    required this.rejectedCount,
    required this.duplicateCount,
    this.errorMessage,
    required this.createdAt,
    required this.createdBy,
    this.startedAt,
    this.completedAt,
  });

  factory CustomerImportJobDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final fileName = json['fileName'];
    final storagePath = json['storagePath'];
    final reportStoragePath = json['reportStoragePath'];
    final templateId = json['templateId'];
    final mapping = json['mapping'];
    final status = json['status'];
    final totalRows = json['totalRows'];
    final processedRows = json['processedRows'];
    final importedCount = json['importedCount'];
    final rejectedCount = json['rejectedCount'];
    final duplicateCount = json['duplicateCount'];
    final errorMessage = json['errorMessage'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final startedAt = json['startedAt'];
    final completedAt = json['completedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        fileName is! String ||
        storagePath is! String ||
        (reportStoragePath != null && reportStoragePath is! String) ||
        (templateId != null && templateId is! String) ||
        mapping is! Map ||
        mapping['hasHeaderRow'] is! bool ||
        mapping['columnByField'] is! Map ||
        status is! String ||
        (totalRows != null && totalRows is! int) ||
        processedRows is! int ||
        importedCount is! int ||
        rejectedCount is! int ||
        duplicateCount is! int ||
        (errorMessage != null && errorMessage is! String) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        (startedAt != null && startedAt is! Timestamp) ||
        (completedAt != null && completedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid customer import job payload.',
        code: 'invalid_customer_import_job_payload',
      );
    }

    final columnByField = <String, int>{};
    (mapping['columnByField'] as Map).forEach((key, value) {
      if (key is! String || value is! int) {
        throw const ValidationException(
          'Invalid customer import job mapping payload.',
          code: 'invalid_customer_import_job_payload',
        );
      }
      columnByField[key] = value;
    });

    return CustomerImportJobDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      fileName: fileName,
      storagePath: storagePath,
      reportStoragePath: reportStoragePath as String?,
      templateId: templateId as String?,
      hasHeaderRow: mapping['hasHeaderRow'] as bool,
      columnByField: columnByField,
      status: status,
      totalRows: totalRows as int?,
      processedRows: processedRows,
      importedCount: importedCount,
      rejectedCount: rejectedCount,
      duplicateCount: duplicateCount,
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
  final String? reportStoragePath;
  final String? templateId;
  final bool hasHeaderRow;
  final Map<String, int> columnByField;
  final String status;
  final int? totalRows;
  final int processedRows;
  final int importedCount;
  final int rejectedCount;
  final int duplicateCount;
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
      'reportStoragePath': reportStoragePath,
      'templateId': templateId,
      'mapping': <String, dynamic>{
        'hasHeaderRow': hasHeaderRow,
        'columnByField': columnByField,
      },
      'status': status,
      'totalRows': totalRows,
      'processedRows': processedRows,
      'importedCount': importedCount,
      'rejectedCount': rejectedCount,
      'duplicateCount': duplicateCount,
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
