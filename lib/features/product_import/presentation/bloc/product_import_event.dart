import 'dart:typed_data';

import '../../domain/value_objects/product_import_field.dart';

sealed class ProductImportEvent {
  const ProductImportEvent();
}

final class ProductImportStarted extends ProductImportEvent {
  const ProductImportStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class ProductImportFileSelected extends ProductImportEvent {
  const ProductImportFileSelected({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

final class ProductImportMappingColumnChanged extends ProductImportEvent {
  const ProductImportMappingColumnChanged({
    required this.field,
    required this.column,
  });

  final ProductImportField field;

  /// `null` clears any column previously mapped to [field].
  final int? column;
}

final class ProductImportHasHeaderRowChanged extends ProductImportEvent {
  const ProductImportHasHeaderRowChanged(this.hasHeaderRow);

  final bool hasHeaderRow;
}

final class ProductImportSizeGridTemplateSelected extends ProductImportEvent {
  const ProductImportSizeGridTemplateSelected(this.sizeGridTemplateId);

  final String? sizeGridTemplateId;
}

final class ProductImportCreateMissingCategoriesChanged
    extends ProductImportEvent {
  const ProductImportCreateMissingCategoriesChanged(this.value);

  final bool value;
}

final class ProductImportCreateMissingCollectionsChanged
    extends ProductImportEvent {
  const ProductImportCreateMissingCollectionsChanged(this.value);

  final bool value;
}

/// Replaces the whole set of pending image files (TASK-168) — each keyed by
/// its original file name, expected to match a SKU/reference in the
/// spreadsheet. An empty map means "import without an image package".
final class ProductImportImagesSelected extends ProductImportEvent {
  const ProductImportImagesSelected(this.bytesByFileName);

  final Map<String, Uint8List> bytesByFileName;
}

final class ProductImportTemplateSelected extends ProductImportEvent {
  const ProductImportTemplateSelected(this.templateId);

  final String? templateId;
}

final class ProductImportTemplateSaveRequested extends ProductImportEvent {
  const ProductImportTemplateSaveRequested(this.name);

  final String name;
}

final class ProductImportTemplateDeleteRequested extends ProductImportEvent {
  const ProductImportTemplateDeleteRequested(this.templateId);

  final String templateId;
}

final class ProductImportSubmitRequested extends ProductImportEvent {
  const ProductImportSubmitRequested();
}

final class ProductImportReportRequested extends ProductImportEvent {
  const ProductImportReportRequested();
}

final class ProductImportRestarted extends ProductImportEvent {
  const ProductImportRestarted();
}
