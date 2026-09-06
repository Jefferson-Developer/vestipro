import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_import_report.dart';
import '../../domain/entities/product_import_row_report.dart';
import '../../domain/value_objects/product_import_row_outcome.dart';

/// Parses the JSON report `processProductImportJob` writes to
/// `ProductImportJob.reportStoragePath` (TASK-168) — mirrors
/// `CustomerImportReportMapper` (TASK-167).
@injectable
final class ProductImportReportMapper {
  const ProductImportReportMapper();

  ProductImportReport fromJson(Map<String, dynamic> json) {
    final totalRows = json['totalRows'];
    final createdProductsCount = json['createdProductsCount'];
    final createdVariantsCount = json['createdVariantsCount'];
    final imagesAssociatedCount = json['imagesAssociatedCount'];
    final imagesOrphanCount = json['imagesOrphanCount'];
    final rejectedCount = json['rejectedCount'];
    final rows = json['rows'];
    final orphanImageFileNames = json['orphanImageFileNames'];

    if (totalRows is! int ||
        createdProductsCount is! int ||
        createdVariantsCount is! int ||
        imagesAssociatedCount is! int ||
        imagesOrphanCount is! int ||
        rejectedCount is! int ||
        rows is! List) {
      throw const ValidationException(
        'Invalid product import report payload.',
        code: 'invalid_product_import_report_payload',
      );
    }

    return ProductImportReport(
      totalRows: totalRows,
      createdProductsCount: createdProductsCount,
      createdVariantsCount: createdVariantsCount,
      imagesAssociatedCount: imagesAssociatedCount,
      imagesOrphanCount: imagesOrphanCount,
      rejectedCount: rejectedCount,
      rows: rows
          .map((item) => _rowFromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      orphanImageFileNames: orphanImageFileNames == null
          ? const <String>[]
          : List<String>.from(orphanImageFileNames as List),
    );
  }

  ProductImportRowReport _rowFromJson(Map<String, dynamic> json) {
    final rowNumber = json['rowNumber'];
    final outcome = json['outcome'];
    final rawValues = json['rawValues'];

    if (rowNumber is! int || outcome is! String) {
      throw const ValidationException(
        'Invalid product import report row payload.',
        code: 'invalid_product_import_report_payload',
      );
    }

    return ProductImportRowReport(
      rowNumber: rowNumber,
      outcome: ProductImportRowOutcomeCode.fromCode(outcome),
      reason: json['reason'] as String?,
      sku: json['sku'] as String?,
      createdProductId: json['createdProductId'] as String?,
      createdVariantId: json['createdVariantId'] as String?,
      imageAssociated: json['imageAssociated'] as bool? ?? false,
      rawValues: rawValues == null
          ? const <String, String>{}
          : Map<String, String>.from(rawValues as Map),
    );
  }
}
