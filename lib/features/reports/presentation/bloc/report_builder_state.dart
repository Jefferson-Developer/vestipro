import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';

enum ReportBuilderStatus { initial, loading, ready, executing, failure }

/// Independent from [ReportBuilderStatus] on purpose: an export
/// (`ReportExportRequested`, TASK-146) never blocks/replaces the builder's
/// own preview/execution state — a user could, in principle, keep tweaking
/// the report while a large export is still being generated server-side.
enum ReportExportStatus { idle, exporting, success, failure }

final class ReportBuilderState {
  const ReportBuilderState({
    this.status = ReportBuilderStatus.initial,
    this.userId = '',
    this.definition,
    this.catalog,
    this.preview,
    this.validationMessage,
    this.failure,
    this.exportStatus = ReportExportStatus.idle,
    this.exportSummary,
    this.exportFailure,
  });

  final ReportBuilderStatus status;
  final String userId;
  final ReportDefinition? definition;
  final ReportCatalog? catalog;
  final ReportQueryResult? preview;
  final String? validationMessage;
  final Failure? failure;
  final ReportExportStatus exportStatus;
  final ReportExportSummary? exportSummary;
  final Failure? exportFailure;

  ReportBuilderState copyWith({
    ReportBuilderStatus? status,
    ReportDefinition? definition,
    ReportCatalog? catalog,
    ReportQueryResult? preview,
    bool clearPreview = false,
    String? validationMessage,
    bool clearValidation = false,
    Failure? failure,
    bool clearFailure = false,
    ReportExportStatus? exportStatus,
    ReportExportSummary? exportSummary,
    bool clearExportSummary = false,
    Failure? exportFailure,
    bool clearExportFailure = false,
  }) => ReportBuilderState(
    status: status ?? this.status,
    userId: userId,
    definition: definition ?? this.definition,
    catalog: catalog ?? this.catalog,
    preview: clearPreview ? null : preview ?? this.preview,
    validationMessage: clearValidation
        ? null
        : validationMessage ?? this.validationMessage,
    failure: clearFailure ? null : failure ?? this.failure,
    exportStatus: exportStatus ?? this.exportStatus,
    exportSummary: clearExportSummary
        ? null
        : exportSummary ?? this.exportSummary,
    exportFailure: clearExportFailure
        ? null
        : exportFailure ?? this.exportFailure,
  );
}
