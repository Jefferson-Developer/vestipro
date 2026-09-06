import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_import_job.dart';
import '../../domain/entities/customer_import_preview.dart';
import '../../domain/entities/customer_import_report.dart';
import '../../domain/entities/customer_import_template.dart';
import '../../domain/value_objects/customer_import_field.dart';

enum CustomerImportStep { upload, mapping, progress }

enum CustomerImportFileStatus { idle, parsing, ready, failure }

enum CustomerImportTemplatesStatus { loading, ready, failure }

enum CustomerImportSubmitStatus { idle, submitting, success, failure }

enum CustomerImportReportStatus { idle, loading, ready, failure }

final class CustomerImportState {
  const CustomerImportState({
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.step = CustomerImportStep.upload,
    this.fileStatus = CustomerImportFileStatus.idle,
    this.preview,
    this.fileFailure,
    this.hasHeaderRow = true,
    this.columnByField = const <CustomerImportField, int>{},
    this.mappingFieldErrors = const <String, String>{},
    this.templatesStatus = CustomerImportTemplatesStatus.loading,
    this.templates = const <CustomerImportTemplate>[],
    this.selectedTemplateId,
    this.submitStatus = CustomerImportSubmitStatus.idle,
    this.submitFailure,
    this.job,
    this.reportStatus = CustomerImportReportStatus.idle,
    this.report,
    this.reportFailure,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final CustomerImportStep step;

  final CustomerImportFileStatus fileStatus;
  final CustomerImportPreview? preview;
  final Failure? fileFailure;

  final bool hasHeaderRow;
  final Map<CustomerImportField, int> columnByField;
  final Map<String, String> mappingFieldErrors;

  final CustomerImportTemplatesStatus templatesStatus;
  final List<CustomerImportTemplate> templates;
  final String? selectedTemplateId;

  final CustomerImportSubmitStatus submitStatus;
  final Failure? submitFailure;
  final CustomerImportJob? job;

  final CustomerImportReportStatus reportStatus;
  final CustomerImportReport? report;
  final Failure? reportFailure;

  CustomerImportState copyWith({
    String? organizationId,
    String? companyId,
    String? userId,
    CustomerImportStep? step,
    CustomerImportFileStatus? fileStatus,
    CustomerImportPreview? preview,
    Failure? fileFailure,
    bool clearFileFailure = false,
    bool? hasHeaderRow,
    Map<CustomerImportField, int>? columnByField,
    Map<String, String>? mappingFieldErrors,
    CustomerImportTemplatesStatus? templatesStatus,
    List<CustomerImportTemplate>? templates,
    String? selectedTemplateId,
    bool clearSelectedTemplateId = false,
    CustomerImportSubmitStatus? submitStatus,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
    CustomerImportJob? job,
    CustomerImportReportStatus? reportStatus,
    CustomerImportReport? report,
    Failure? reportFailure,
    bool clearReportFailure = false,
  }) {
    return CustomerImportState(
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      step: step ?? this.step,
      fileStatus: fileStatus ?? this.fileStatus,
      preview: preview ?? this.preview,
      fileFailure: clearFileFailure ? null : fileFailure ?? this.fileFailure,
      hasHeaderRow: hasHeaderRow ?? this.hasHeaderRow,
      columnByField: columnByField ?? this.columnByField,
      mappingFieldErrors: mappingFieldErrors ?? this.mappingFieldErrors,
      templatesStatus: templatesStatus ?? this.templatesStatus,
      templates: templates ?? this.templates,
      selectedTemplateId: clearSelectedTemplateId
          ? null
          : selectedTemplateId ?? this.selectedTemplateId,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: clearSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      job: job ?? this.job,
      reportStatus: reportStatus ?? this.reportStatus,
      report: report ?? this.report,
      reportFailure: clearReportFailure
          ? null
          : reportFailure ?? this.reportFailure,
    );
  }
}
