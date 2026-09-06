import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/usecases/create_category_use_case.dart';
import '../../../products/domain/usecases/create_collection_use_case.dart';
import '../../../products/domain/usecases/list_categories_use_case.dart';
import '../../../products/domain/usecases/list_collections_use_case.dart';
import '../../../products/domain/usecases/list_product_colors_use_case.dart';
import '../../../products/domain/usecases/list_size_grid_templates_use_case.dart';
import '../../domain/entities/product_import_job.dart';
import '../../domain/entities/product_import_lookup.dart';
import '../../domain/entities/product_import_mapping.dart';
import '../../domain/entities/product_import_template.dart';
import '../../domain/services/product_import_mapping_validator.dart';
import '../../domain/usecases/delete_product_import_template_use_case.dart';
import '../../domain/usecases/get_product_import_job_report_use_case.dart';
import '../../domain/usecases/list_product_import_templates_use_case.dart';
import '../../domain/usecases/parse_product_import_file_use_case.dart';
import '../../domain/usecases/save_product_import_template_use_case.dart';
import '../../domain/usecases/start_product_import_job_use_case.dart';
import '../../domain/usecases/watch_product_import_job_use_case.dart';
import '../../domain/value_objects/product_import_field.dart';
import 'product_import_event.dart';
import 'product_import_state.dart';

/// Orchestrates the whole product-import wizard (TASK-168): file
/// pick/parse, column mapping (with size-grid selection, optional saved
/// template and category/collection/color resolution), optional image
/// package, submitting the async job, and watching/reporting on its
/// progress — same shape as `CustomerImportBloc` (TASK-167), plus the
/// catalog-resolution steps `ProductImportLookup`'s docs explain are only
/// possible client-side today.
@injectable
final class ProductImportBloc
    extends Bloc<ProductImportEvent, ProductImportState> {
  ProductImportBloc({
    required this.parseProductImportFile,
    required this.listProductImportTemplates,
    required this.saveProductImportTemplate,
    required this.deleteProductImportTemplate,
    required this.startProductImportJob,
    required this.watchProductImportJob,
    required this.getProductImportJobReport,
    required this.listCategories,
    required this.listCollections,
    required this.listProductColors,
    required this.listSizeGridTemplates,
    required this.createCategory,
    required this.createCollection,
  }) : _uuid = const Uuid(),
       super(const ProductImportState()) {
    on<ProductImportStarted>(_onStarted, transformer: restartable());
    on<ProductImportFileSelected>(_onFileSelected, transformer: sequential());
    on<ProductImportMappingColumnChanged>(_onMappingColumnChanged);
    on<ProductImportHasHeaderRowChanged>(_onHasHeaderRowChanged);
    on<ProductImportSizeGridTemplateSelected>(_onSizeGridTemplateSelected);
    on<ProductImportCreateMissingCategoriesChanged>(
      _onCreateMissingCategoriesChanged,
    );
    on<ProductImportCreateMissingCollectionsChanged>(
      _onCreateMissingCollectionsChanged,
    );
    on<ProductImportImagesSelected>(_onImagesSelected);
    on<ProductImportTemplateSelected>(_onTemplateSelected);
    on<ProductImportTemplateSaveRequested>(
      _onTemplateSaveRequested,
      transformer: sequential(),
    );
    on<ProductImportTemplateDeleteRequested>(
      _onTemplateDeleteRequested,
      transformer: sequential(),
    );
    on<ProductImportSubmitRequested>(
      _onSubmitRequested,
      transformer: restartable(),
    );
    on<ProductImportReportRequested>(
      _onReportRequested,
      transformer: sequential(),
    );
    on<ProductImportRestarted>(_onRestarted);
  }

  final ParseProductImportFileUseCase parseProductImportFile;
  final ListProductImportTemplatesUseCase listProductImportTemplates;
  final SaveProductImportTemplateUseCase saveProductImportTemplate;
  final DeleteProductImportTemplateUseCase deleteProductImportTemplate;
  final StartProductImportJobUseCase startProductImportJob;
  final WatchProductImportJobUseCase watchProductImportJob;
  final GetProductImportJobReportUseCase getProductImportJobReport;
  final ListCategoriesUseCase listCategories;
  final ListCollectionsUseCase listCollections;
  final ListProductColorsUseCase listProductColors;
  final ListSizeGridTemplatesUseCase listSizeGridTemplates;
  final CreateCategoryUseCase createCategory;
  final CreateCollectionUseCase createCollection;
  final Uuid _uuid;

  /// Kept out of `ProductImportState` on purpose (same rationale as
  /// `CustomerImportBloc._pendingFileBytes`): only ever needed once, to call
  /// [startProductImportJob].
  ({String fileName, bool isXlsx})? _pendingFile;
  Uint8List? _pendingFileBytes;

  Future<void> _onStarted(
    ProductImportStarted event,
    Emitter<ProductImportState> emit,
  ) async {
    emit(
      state.copyWith(
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        templatesStatus: ProductImportTemplatesStatus.loading,
        catalogStatus: ProductImportCatalogStatus.loading,
      ),
    );

    final templatesResult = await listProductImportTemplates(
      organizationId: event.organizationId,
    );
    if (emit.isDone) return;
    switch (templatesResult) {
      case AppSuccess<List<ProductImportTemplate>>(value: final templates):
        emit(
          state.copyWith(
            templatesStatus: ProductImportTemplatesStatus.ready,
            templates: templates,
          ),
        );
      case AppFailure<List<ProductImportTemplate>>():
        emit(
          state.copyWith(templatesStatus: ProductImportTemplatesStatus.failure),
        );
    }

    final categoriesResult = await listCategories(event.organizationId);
    if (emit.isDone) return;
    final categories = categoriesResult.fold(
      onSuccess: (value) => value,
      onFailure: (_) => const <Category>[],
    );
    emit(state.copyWith(categories: categories));

    final collectionsResult = await listCollections(event.organizationId);
    if (emit.isDone) return;
    final collections = collectionsResult.fold(
      onSuccess: (value) => value,
      onFailure: (_) => const <Collection>[],
    );
    emit(state.copyWith(collections: collections));

    final colorsResult = await listProductColors(event.organizationId);
    if (emit.isDone) return;
    final colors = colorsResult.fold(
      onSuccess: (value) => value,
      onFailure: (_) => const <ProductColor>[],
    );
    emit(state.copyWith(colors: colors));

    final sizeGridTemplatesResult = await listSizeGridTemplates(
      event.organizationId,
    );
    if (emit.isDone) return;
    final sizeGridTemplates = sizeGridTemplatesResult.fold(
      onSuccess: (value) => value,
      onFailure: (_) => const <SizeGridTemplate>[],
    );
    emit(
      state.copyWith(
        sizeGridTemplates: sizeGridTemplates,
        catalogStatus: ProductImportCatalogStatus.ready,
      ),
    );
  }

  void _onFileSelected(
    ProductImportFileSelected event,
    Emitter<ProductImportState> emit,
  ) {
    emit(
      state.copyWith(
        fileStatus: ProductImportFileStatus.parsing,
        clearFileFailure: true,
      ),
    );
    final result = parseProductImportFile(
      fileName: event.fileName,
      bytes: event.bytes,
    );
    switch (result) {
      case AppSuccess(value: final preview):
        _pendingFile = (fileName: event.fileName, isXlsx: preview.isXlsx);
        _pendingFileBytes = event.bytes;
        emit(
          state.copyWith(
            fileStatus: ProductImportFileStatus.ready,
            preview: preview,
            step: ProductImportStep.mapping,
            clearFileFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            fileStatus: ProductImportFileStatus.failure,
            fileFailure: failure,
          ),
        );
    }
  }

  void _onMappingColumnChanged(
    ProductImportMappingColumnChanged event,
    Emitter<ProductImportState> emit,
  ) {
    final next = Map<ProductImportField, int>.of(state.columnByField);
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
    ProductImportHasHeaderRowChanged event,
    Emitter<ProductImportState> emit,
  ) {
    emit(state.copyWith(hasHeaderRow: event.hasHeaderRow));
  }

  void _onSizeGridTemplateSelected(
    ProductImportSizeGridTemplateSelected event,
    Emitter<ProductImportState> emit,
  ) {
    emit(
      state.copyWith(
        selectedSizeGridTemplateId: event.sizeGridTemplateId,
        clearSelectedSizeGridTemplateId: event.sizeGridTemplateId == null,
        mappingFieldErrors: const <String, String>{},
      ),
    );
  }

  void _onCreateMissingCategoriesChanged(
    ProductImportCreateMissingCategoriesChanged event,
    Emitter<ProductImportState> emit,
  ) {
    emit(state.copyWith(createMissingCategories: event.value));
  }

  void _onCreateMissingCollectionsChanged(
    ProductImportCreateMissingCollectionsChanged event,
    Emitter<ProductImportState> emit,
  ) {
    emit(state.copyWith(createMissingCollections: event.value));
  }

  void _onImagesSelected(
    ProductImportImagesSelected event,
    Emitter<ProductImportState> emit,
  ) {
    emit(state.copyWith(imageBytesByFileName: event.bytesByFileName));
  }

  void _onTemplateSelected(
    ProductImportTemplateSelected event,
    Emitter<ProductImportState> emit,
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
        columnByField: Map<ProductImportField, int>.of(
          template.mapping.columnByField,
        ),
        selectedSizeGridTemplateId: template.mapping.sizeGridTemplateId,
        mappingFieldErrors: const <String, String>{},
      ),
    );
  }

  Future<void> _onTemplateSaveRequested(
    ProductImportTemplateSaveRequested event,
    Emitter<ProductImportState> emit,
  ) async {
    final sizeGridTemplateId = state.selectedSizeGridTemplateId;
    if (sizeGridTemplateId == null) return;
    final mapping = ProductImportMapping(
      hasHeaderRow: state.hasHeaderRow,
      columnByField: state.columnByField,
      sizeGridTemplateId: sizeGridTemplateId,
    );
    final existing = state.templates
        .where((candidate) => candidate.id == state.selectedTemplateId)
        .firstOrNull;
    final result = await saveProductImportTemplate(
      id: existing?.id ?? _uuid.v4(),
      organizationId: state.organizationId,
      name: event.name,
      mapping: mapping,
      existingCreatedAt: existing?.createdAt,
      existingCreatedBy: existing?.createdBy,
      requestedBy: state.userId,
    );
    if (emit.isDone) return;
    if (result is AppSuccess<ProductImportTemplate>) {
      final refreshed = await listProductImportTemplates(
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
    ProductImportTemplateDeleteRequested event,
    Emitter<ProductImportState> emit,
  ) async {
    final result = await deleteProductImportTemplate(
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
    ProductImportSubmitRequested event,
    Emitter<ProductImportState> emit,
  ) async {
    final sizeGridTemplateId = state.selectedSizeGridTemplateId ?? '';
    final mapping = ProductImportMapping(
      hasHeaderRow: state.hasHeaderRow,
      columnByField: state.columnByField,
      sizeGridTemplateId: sizeGridTemplateId,
    );
    final fieldErrors = validateProductImportMapping(mapping);
    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(mappingFieldErrors: fieldErrors));
      return;
    }
    final pendingFile = _pendingFile;
    final pendingBytes = _pendingFileBytes;
    if (pendingFile == null || pendingBytes == null) return;

    emit(
      state.copyWith(
        submitStatus: ProductImportSubmitStatus.submitting,
        clearSubmitFailure: true,
      ),
    );

    final lookup = await _resolveLookup(emit);
    if (emit.isDone) return;

    final result = await startProductImportJob(
      organizationId: state.organizationId,
      companyId: state.companyId,
      fileName: pendingFile.fileName,
      isXlsx: pendingFile.isXlsx,
      fileBytes: pendingBytes,
      mapping: mapping,
      lookup: lookup,
      createMissingCategories: state.createMissingCategories,
      createMissingCollections: state.createMissingCollections,
      imageBytesByFileName: state.imageBytesByFileName.isEmpty
          ? null
          : state.imageBytesByFileName,
      templateId: state.selectedTemplateId,
      createdBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<ProductImportJob>(value: final job):
        emit(
          state.copyWith(
            submitStatus: ProductImportSubmitStatus.success,
            job: job,
            step: ProductImportStep.progress,
          ),
        );
        await emit.forEach(
          watchProductImportJob(
            organizationId: state.organizationId,
            jobId: job.id,
          ),
          onData: (jobResult) => switch (jobResult) {
            AppSuccess<ProductImportJob>(value: final updatedJob) =>
              state.copyWith(job: updatedJob),
            AppFailure<ProductImportJob>() => state,
          },
        );
      case AppFailure<ProductImportJob>(failure: final failure):
        emit(
          state.copyWith(
            submitStatus: ProductImportSubmitStatus.failure,
            submitFailure: failure,
            mappingFieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  /// Resolves every distinct categoria/coleção/cor name visible in the
  /// file's bounded preview against the organization's local catalog
  /// (TASK-168, see `ProductImportLookup`'s docs on why this happens
  /// client-side). When [ProductImportState.createMissingCategories]/
  /// [createMissingCollections] is on, a name absent from the local catalog
  /// is created right here (never for color — `tasks.md` never allows
  /// auto-creating a color from an import).
  Future<ProductImportLookup> _resolveLookup(
    Emitter<ProductImportState> emit,
  ) async {
    var categories = state.categories;
    var collections = state.collections;
    final colors = state.colors;

    final categoryNames = <String>{
      ..._distinctValuesForField(ProductImportField.categoryName),
      ..._distinctValuesForField(ProductImportField.subcategoryName),
    };
    final collectionNames = _distinctValuesForField(
      ProductImportField.collectionName,
    );

    final categoryIdByName = <String, String>{
      for (final category in categories)
        category.name.trim().toLowerCase(): category.id,
    };
    final collectionIdByName = <String, String>{
      for (final collection in collections)
        collection.name.trim().toLowerCase(): collection.id,
    };
    final colorIdByName = <String, String>{
      for (final color in colors) ...<String, String>{
        color.name.trim().toLowerCase(): color.id,
        color.code.trim().toLowerCase(): color.id,
      },
    };

    final selectedGrid = state.sizeGridTemplates
        .where((template) => template.id == state.selectedSizeGridTemplateId)
        .firstOrNull;
    final sizeIdByLabel = <String, String>{
      if (selectedGrid != null)
        for (final size in selectedGrid.sizes)
          size.label.trim().toLowerCase(): size.id,
    };

    if (state.createMissingCategories) {
      for (final name in categoryNames) {
        final normalized = name.trim().toLowerCase();
        if (normalized.isEmpty || categoryIdByName.containsKey(normalized)) {
          continue;
        }
        final result = await createCategory(
          id: _uuid.v4(),
          organizationId: state.organizationId,
          name: name,
          createdBy: state.userId,
        );
        if (result is AppSuccess<Category>) {
          categoryIdByName[normalized] = result.value.id;
          categories = <Category>[...categories, result.value];
        }
      }
    }

    if (state.createMissingCollections) {
      for (final name in collectionNames) {
        final normalized = name.trim().toLowerCase();
        if (normalized.isEmpty || collectionIdByName.containsKey(normalized)) {
          continue;
        }
        final result = await createCollection(
          id: _uuid.v4(),
          organizationId: state.organizationId,
          name: name,
          createdBy: state.userId,
        );
        if (result is AppSuccess<Collection>) {
          collectionIdByName[normalized] = result.value.id;
          collections = <Collection>[...collections, result.value];
        }
      }
    }

    if (!emit.isDone) {
      emit(state.copyWith(categories: categories, collections: collections));
    }

    return ProductImportLookup(
      categoryIdByName: categoryIdByName,
      collectionIdByName: collectionIdByName,
      colorIdByName: colorIdByName,
      sizeIdByLabel: sizeIdByLabel,
    );
  }

  List<String> _distinctValuesForField(ProductImportField field) {
    final preview = state.preview;
    final column = state.columnByField[field];
    if (preview == null || column == null) return const <String>[];
    final values = <String>{};
    for (final row in preview.sampleRows) {
      if (column < 0 || column >= row.length) continue;
      final value = row[column].trim();
      if (value.isNotEmpty) values.add(value);
    }
    return values.toList(growable: false);
  }

  Future<void> _onReportRequested(
    ProductImportReportRequested event,
    Emitter<ProductImportState> emit,
  ) async {
    final job = state.job;
    final reportPath = job?.reportStoragePath;
    if (job == null || reportPath == null) return;

    emit(
      state.copyWith(
        reportStatus: ProductImportReportStatus.loading,
        clearReportFailure: true,
      ),
    );
    final result = await getProductImportJobReport(
      organizationId: state.organizationId,
      jobId: job.id,
      reportStoragePath: reportPath,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(value: final report):
        emit(
          state.copyWith(
            reportStatus: ProductImportReportStatus.ready,
            report: report,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            reportStatus: ProductImportReportStatus.failure,
            reportFailure: failure,
          ),
        );
    }
  }

  void _onRestarted(
    ProductImportRestarted event,
    Emitter<ProductImportState> emit,
  ) {
    _pendingFile = null;
    _pendingFileBytes = null;
    emit(
      ProductImportState(
        organizationId: state.organizationId,
        companyId: state.companyId,
        userId: state.userId,
        templatesStatus: state.templatesStatus,
        templates: state.templates,
        catalogStatus: state.catalogStatus,
        categories: state.categories,
        collections: state.collections,
        colors: state.colors,
        sizeGridTemplates: state.sizeGridTemplates,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
