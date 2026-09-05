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

/// PDF-only pré-visualização lifecycle (TASK-148) — deliberately separate
/// from [ReportExportStatus]: generating a preview never itself saves a
/// file (that only happens once [ReportBuilderState.pdfPreview] is
/// confirmed, which then *does* flow through [ReportExportStatus] like every
/// other format).
enum ReportPdfPreviewStatus { idle, loading, ready, failure }

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
    this.pdfPreviewStatus = ReportPdfPreviewStatus.idle,
    this.pdfPreview,
    this.pdfPreviewFailure,
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

  /// Loading/ready/failure state of the PDF pré-visualização flow
  /// (TASK-148). Stays [ReportPdfPreviewStatus.idle] for the large-volume
  /// (remote) path, which never shows a preview at all — that path reports
  /// its own outcome through [exportStatus] directly, same as CSV/XLSX.
  final ReportPdfPreviewStatus pdfPreviewStatus;

  /// The already-encoded, not-yet-saved PDF ready to be shown — only ever
  /// non-null while [pdfPreviewStatus] is [ReportPdfPreviewStatus.ready].
  final LocalReportPdfPreview? pdfPreview;
  final Failure? pdfPreviewFailure;

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
    ReportPdfPreviewStatus? pdfPreviewStatus,
    LocalReportPdfPreview? pdfPreview,
    bool clearPdfPreview = false,
    Failure? pdfPreviewFailure,
    bool clearPdfPreviewFailure = false,
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
    pdfPreviewStatus: pdfPreviewStatus ?? this.pdfPreviewStatus,
    pdfPreview: clearPdfPreview ? null : pdfPreview ?? this.pdfPreview,
    pdfPreviewFailure: clearPdfPreviewFailure
        ? null
        : pdfPreviewFailure ?? this.pdfPreviewFailure,
  );
}
