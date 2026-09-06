import 'dart:typed_data';

import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../domain/entities/product_import_job.dart';
import '../../domain/entities/product_import_preview.dart';
import '../../domain/entities/product_import_report.dart';
import '../../domain/entities/product_import_template.dart';
import '../../domain/value_objects/product_import_field.dart';

enum ProductImportStep { upload, mapping, progress }

enum ProductImportFileStatus { idle, parsing, ready, failure }

enum ProductImportCatalogStatus { loading, ready, failure }

enum ProductImportTemplatesStatus { loading, ready, failure }

enum ProductImportSubmitStatus { idle, submitting, success, failure }

enum ProductImportReportStatus { idle, loading, ready, failure }

final class ProductImportState {
  const ProductImportState({
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.step = ProductImportStep.upload,
    this.fileStatus = ProductImportFileStatus.idle,
    this.preview,
    this.fileFailure,
    this.hasHeaderRow = true,
    this.columnByField = const <ProductImportField, int>{},
    this.mappingFieldErrors = const <String, String>{},
    this.catalogStatus = ProductImportCatalogStatus.loading,
    this.categories = const <Category>[],
    this.collections = const <Collection>[],
    this.colors = const <ProductColor>[],
    this.sizeGridTemplates = const <SizeGridTemplate>[],
    this.selectedSizeGridTemplateId,
    this.createMissingCategories = false,
    this.createMissingCollections = false,
    this.imageBytesByFileName = const <String, Uint8List>{},
    this.templatesStatus = ProductImportTemplatesStatus.loading,
    this.templates = const <ProductImportTemplate>[],
    this.selectedTemplateId,
    this.submitStatus = ProductImportSubmitStatus.idle,
    this.submitFailure,
    this.job,
    this.reportStatus = ProductImportReportStatus.idle,
    this.report,
    this.reportFailure,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final ProductImportStep step;

  final ProductImportFileStatus fileStatus;
  final ProductImportPreview? preview;
  final Failure? fileFailure;

  final bool hasHeaderRow;
  final Map<ProductImportField, int> columnByField;
  final Map<String, String> mappingFieldErrors;

  final ProductImportCatalogStatus catalogStatus;
  final List<Category> categories;
  final List<Collection> collections;
  final List<ProductColor> colors;
  final List<SizeGridTemplate> sizeGridTemplates;
  final String? selectedSizeGridTemplateId;
  final bool createMissingCategories;
  final bool createMissingCollections;
  final Map<String, Uint8List> imageBytesByFileName;

  final ProductImportTemplatesStatus templatesStatus;
  final List<ProductImportTemplate> templates;
  final String? selectedTemplateId;

  final ProductImportSubmitStatus submitStatus;
  final Failure? submitFailure;
  final ProductImportJob? job;

  final ProductImportReportStatus reportStatus;
  final ProductImportReport? report;
  final Failure? reportFailure;

  ProductImportState copyWith({
    String? organizationId,
    String? companyId,
    String? userId,
    ProductImportStep? step,
    ProductImportFileStatus? fileStatus,
    ProductImportPreview? preview,
    Failure? fileFailure,
    bool clearFileFailure = false,
    bool? hasHeaderRow,
    Map<ProductImportField, int>? columnByField,
    Map<String, String>? mappingFieldErrors,
    ProductImportCatalogStatus? catalogStatus,
    List<Category>? categories,
    List<Collection>? collections,
    List<ProductColor>? colors,
    List<SizeGridTemplate>? sizeGridTemplates,
    String? selectedSizeGridTemplateId,
    bool clearSelectedSizeGridTemplateId = false,
    bool? createMissingCategories,
    bool? createMissingCollections,
    Map<String, Uint8List>? imageBytesByFileName,
    ProductImportTemplatesStatus? templatesStatus,
    List<ProductImportTemplate>? templates,
    String? selectedTemplateId,
    bool clearSelectedTemplateId = false,
    ProductImportSubmitStatus? submitStatus,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
    ProductImportJob? job,
    ProductImportReportStatus? reportStatus,
    ProductImportReport? report,
    Failure? reportFailure,
    bool clearReportFailure = false,
  }) {
    return ProductImportState(
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
      catalogStatus: catalogStatus ?? this.catalogStatus,
      categories: categories ?? this.categories,
      collections: collections ?? this.collections,
      colors: colors ?? this.colors,
      sizeGridTemplates: sizeGridTemplates ?? this.sizeGridTemplates,
      selectedSizeGridTemplateId: clearSelectedSizeGridTemplateId
          ? null
          : selectedSizeGridTemplateId ?? this.selectedSizeGridTemplateId,
      createMissingCategories:
          createMissingCategories ?? this.createMissingCategories,
      createMissingCollections:
          createMissingCollections ?? this.createMissingCollections,
      imageBytesByFileName: imageBytesByFileName ?? this.imageBytesByFileName,
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
