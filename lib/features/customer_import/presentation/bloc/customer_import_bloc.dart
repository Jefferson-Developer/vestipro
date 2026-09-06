import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_import_job.dart';
import '../../domain/entities/customer_import_mapping.dart';
import '../../domain/entities/customer_import_template.dart';
import '../../domain/services/customer_import_mapping_validator.dart';
import '../../domain/usecases/delete_customer_import_template_use_case.dart';
import '../../domain/usecases/get_customer_import_job_report_use_case.dart';
import '../../domain/usecases/list_customer_import_templates_use_case.dart';
import '../../domain/usecases/parse_customer_import_file_use_case.dart';
import '../../domain/usecases/resolve_customer_import_duplicate_use_case.dart';
import '../../domain/usecases/save_customer_import_template_use_case.dart';
import '../../domain/usecases/start_customer_import_job_use_case.dart';
import '../../domain/usecases/watch_customer_import_job_use_case.dart';
import '../../domain/value_objects/customer_import_field.dart';
import 'customer_import_event.dart';
import 'customer_import_state.dart';

/// Orchestrates the whole customer-import wizard (TASK-167): file
/// pick/parse (client-side preview only), column mapping (with optional
/// saved template), submitting the async job, and watching/reporting on its
/// progress. Never talks to Firestore/Storage/Cloud Functions itself — every
/// dependency below is a use case.
@injectable
final class CustomerImportBloc
    extends Bloc<CustomerImportEvent, CustomerImportState> {
  CustomerImportBloc({
    required this.parseCustomerImportFile,
    required this.listCustomerImportTemplates,
    required this.saveCustomerImportTemplate,
    required this.deleteCustomerImportTemplate,
    required this.startCustomerImportJob,
    required this.watchCustomerImportJob,
    required this.getCustomerImportJobReport,
    required this.resolveCustomerImportDuplicate,
  }) : _uuid = const Uuid(),
       super(const CustomerImportState()) {
    on<CustomerImportStarted>(_onStarted, transformer: restartable());
    on<CustomerImportFileSelected>(_onFileSelected, transformer: sequential());
    on<CustomerImportMappingColumnChanged>(_onMappingColumnChanged);
    on<CustomerImportHasHeaderRowChanged>(_onHasHeaderRowChanged);
    on<CustomerImportTemplateSelected>(_onTemplateSelected);
    on<CustomerImportTemplateSaveRequested>(
      _onTemplateSaveRequested,
      transformer: sequential(),
    );
    on<CustomerImportTemplateDeleteRequested>(
      _onTemplateDeleteRequested,
      transformer: sequential(),
    );
    on<CustomerImportSubmitRequested>(
      _onSubmitRequested,
      transformer: restartable(),
    );
    on<CustomerImportReportRequested>(
      _onReportRequested,
      transformer: sequential(),
    );
    on<CustomerImportDuplicateResolved>(
      _onDuplicateResolved,
      transformer: sequential(),
    );
    on<CustomerImportRestarted>(_onRestarted);
  }

  final ParseCustomerImportFileUseCase parseCustomerImportFile;
  final ListCustomerImportTemplatesUseCase listCustomerImportTemplates;
  final SaveCustomerImportTemplateUseCase saveCustomerImportTemplate;
  final DeleteCustomerImportTemplateUseCase deleteCustomerImportTemplate;
  final StartCustomerImportJobUseCase startCustomerImportJob;
  final WatchCustomerImportJobUseCase watchCustomerImportJob;
  final GetCustomerImportJobReportUseCase getCustomerImportJobReport;
  final ResolveCustomerImportDuplicateUseCase resolveCustomerImportDuplicate;
  final Uuid _uuid;

  /// Kept out of `CustomerImportState` on purpose: the raw file bytes are
  /// only ever needed once, to call [startCustomerImportJob] — duplicating
  /// them into every `copyWith`'d state would be wasteful and pointless.
  ({String fileName, bool isXlsx})? _pendingFile;
  Uint8List? _pendingFileBytes;

  Future<void> _onStarted(
    CustomerImportStarted event,
    Emitter<CustomerImportState> emit,
  ) async {
    emit(
      state.copyWith(
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        templatesStatus: CustomerImportTemplatesStatus.loading,
      ),
    );
    final result = await listCustomerImportTemplates(
      organizationId: event.organizationId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<CustomerImportTemplate>>(value: final templates):
        emit(
          state.copyWith(
            templatesStatus: CustomerImportTemplatesStatus.ready,
            templates: templates,
          ),
        );
      case AppFailure<List<CustomerImportTemplate>>():
        emit(
          state.copyWith(
            templatesStatus: CustomerImportTemplatesStatus.failure,
          ),
        );
    }
  }

  void _onFileSelected(
    CustomerImportFileSelected event,
    Emitter<CustomerImportState> emit,
  ) {
    emit(
      state.copyWith(
        fileStatus: CustomerImportFileStatus.parsing,
        clearFileFailure: true,
      ),
    );
    final result = parseCustomerImportFile(
      fileName: event.fileName,
      bytes: event.bytes,
    );
    switch (result) {
      case AppSuccess(value: final preview):
        _pendingFile = (fileName: event.fileName, isXlsx: preview.isXlsx);
        _pendingFileBytes = event.bytes;
        emit(
          state.copyWith(
            fileStatus: CustomerImportFileStatus.ready,
            preview: preview,
            step: CustomerImportStep.mapping,
            clearFileFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            fileStatus: CustomerImportFileStatus.failure,
            fileFailure: failure,
          ),
        );
    }
  }

  void _onMappingColumnChanged(
    CustomerImportMappingColumnChanged event,
    Emitter<CustomerImportState> emit,
  ) {
    final next = Map<CustomerImportField, int>.of(state.columnByField);
    if (event.column == null) {
      next.remove(event.field);
    } else {
      next[event.field] = event.column!;
    }
    emit(
      state.copyWith(
        columnByField: next,
        mappingFieldErrors: const <String, String>{},
        clearSelectedTemplateId: true,
      ),
    );
  }

  void _onHasHeaderRowChanged(
    CustomerImportHasHeaderRowChanged event,
    Emitter<CustomerImportState> emit,
  ) {
    emit(state.copyWith(hasHeaderRow: event.hasHeaderRow));
  }

  void _onTemplateSelected(
    CustomerImportTemplateSelected event,
    Emitter<CustomerImportState> emit,
  ) {
    if (event.templateId == null) {
      emit(state.copyWith(clearSelectedTemplateId: true));
      return;
    }
    final template = state.templates
        .where((candidate) => candidate.id == event.templateId)
        .firstOrNull;
    if (template == null) return;
    emit(
      state.copyWith(
        selectedTemplateId: template.id,
        hasHeaderRow: template.mapping.hasHeaderRow,
        columnByField: Map<CustomerImportField, int>.of(
          template.mapping.columnByField,
        ),
        mappingFieldErrors: const <String, String>{},
      ),
    );
  }

  Future<void> _onTemplateSaveRequested(
    CustomerImportTemplateSaveRequested event,
    Emitter<CustomerImportState> emit,
  ) async {
    final mapping = CustomerImportMapping(
      hasHeaderRow: state.hasHeaderRow,
      columnByField: state.columnByField,
    );
    final existing = state.templates
        .where((candidate) => candidate.id == state.selectedTemplateId)
        .firstOrNull;
    final result = await saveCustomerImportTemplate(
      id: existing?.id ?? _uuid.v4(),
      organizationId: state.organizationId,
      name: event.name,
      mapping: mapping,
      existingCreatedAt: existing?.createdAt,
      existingCreatedBy: existing?.createdBy,
      requestedBy: state.userId,
    );
    if (emit.isDone) return;
    if (result is AppSuccess<CustomerImportTemplate>) {
      final refreshed = await listCustomerImportTemplates(
        organizationId: state.organizationId,
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          templates: refreshed.fold(
            onSuccess: (templates) => templates,
            onFailure: (_) => state.templates,
          ),
          selectedTemplateId: result.value.id,
        ),
      );
    }
  }

  Future<void> _onTemplateDeleteRequested(
    CustomerImportTemplateDeleteRequested event,
    Emitter<CustomerImportState> emit,
  ) async {
    final result = await deleteCustomerImportTemplate(
      organizationId: state.organizationId,
      id: event.templateId,
    );
    if (emit.isDone) return;
    if (result is AppSuccess<void>) {
      emit(
        state.copyWith(
          templates: state.templates
              .where((template) => template.id != event.templateId)
              .toList(growable: false),
          clearSelectedTemplateId: state.selectedTemplateId == event.templateId,
        ),
      );
    }
  }

  Future<void> _onSubmitRequested(
    CustomerImportSubmitRequested event,
    Emitter<CustomerImportState> emit,
  ) async {
    final mapping = CustomerImportMapping(
      hasHeaderRow: state.hasHeaderRow,
      columnByField: state.columnByField,
    );
    final fieldErrors = validateCustomerImportMapping(mapping);
    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(mappingFieldErrors: fieldErrors));
      return;
    }
    final pendingFile = _pendingFile;
    final pendingBytes = _pendingFileBytes;
    if (pendingFile == null || pendingBytes == null) return;

    emit(
      state.copyWith(
        submitStatus: CustomerImportSubmitStatus.submitting,
        clearSubmitFailure: true,
      ),
    );
    final result = await startCustomerImportJob(
      organizationId: state.organizationId,
      companyId: state.companyId,
      fileName: pendingFile.fileName,
      isXlsx: pendingFile.isXlsx,
      fileBytes: pendingBytes,
      mapping: mapping,
      templateId: state.selectedTemplateId,
      createdBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CustomerImportJob>(value: final job):
        emit(
          state.copyWith(
            submitStatus: CustomerImportSubmitStatus.success,
            job: job,
            step: CustomerImportStep.progress,
          ),
        );
        await emit.forEach(
          watchCustomerImportJob(
            organizationId: state.organizationId,
            jobId: job.id,
          ),
          onData: (jobResult) => switch (jobResult) {
            AppSuccess<CustomerImportJob>(value: final updatedJob) =>
              state.copyWith(job: updatedJob),
            AppFailure<CustomerImportJob>() => state,
          },
        );
      case AppFailure<CustomerImportJob>(failure: final failure):
        emit(
          state.copyWith(
            submitStatus: CustomerImportSubmitStatus.failure,
            submitFailure: failure,
            mappingFieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  Future<void> _onReportRequested(
    CustomerImportReportRequested event,
    Emitter<CustomerImportState> emit,
  ) async {
    final job = state.job;
    final reportPath = job?.reportStoragePath;
    if (job == null || reportPath == null) return;

    emit(
      state.copyWith(
        reportStatus: CustomerImportReportStatus.loading,
        clearReportFailure: true,
      ),
    );
    final result = await getCustomerImportJobReport(
      organizationId: state.organizationId,
      jobId: job.id,
      reportStoragePath: reportPath,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(value: final report):
        emit(
          state.copyWith(
            reportStatus: CustomerImportReportStatus.ready,
            report: report,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            reportStatus: CustomerImportReportStatus.failure,
            reportFailure: failure,
          ),
        );
    }
  }

  Future<void> _onDuplicateResolved(
    CustomerImportDuplicateResolved event,
    Emitter<CustomerImportState> emit,
  ) async {
    final job = state.job;
    if (job == null) return;
    final result = await resolveCustomerImportDuplicate(
      organizationId: state.organizationId,
      jobId: job.id,
      rowNumber: event.rowNumber,
      resolution: event.resolution,
    );
    if (emit.isDone) return;
    if (result is AppSuccess<void>) {
      add(const CustomerImportReportRequested());
    }
  }

  void _onRestarted(
    CustomerImportRestarted event,
    Emitter<CustomerImportState> emit,
  ) {
    _pendingFile = null;
    _pendingFileBytes = null;
    emit(
      CustomerImportState(
        organizationId: state.organizationId,
        companyId: state.companyId,
        userId: state.userId,
        templatesStatus: state.templatesStatus,
        templates: state.templates,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
