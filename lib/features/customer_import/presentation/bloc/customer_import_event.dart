import 'dart:typed_data';

import '../../domain/value_objects/customer_import_duplicate_resolution.dart';
import '../../domain/value_objects/customer_import_field.dart';

sealed class CustomerImportEvent {
  const CustomerImportEvent();
}

final class CustomerImportStarted extends CustomerImportEvent {
  const CustomerImportStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class CustomerImportFileSelected extends CustomerImportEvent {
  const CustomerImportFileSelected({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

final class CustomerImportMappingColumnChanged extends CustomerImportEvent {
  const CustomerImportMappingColumnChanged({
    required this.field,
    required this.column,
  });

  final CustomerImportField field;

  /// `null` clears any column previously mapped to [field].
  final int? column;
}

final class CustomerImportHasHeaderRowChanged extends CustomerImportEvent {
  const CustomerImportHasHeaderRowChanged(this.hasHeaderRow);

  final bool hasHeaderRow;
}

final class CustomerImportTemplateSelected extends CustomerImportEvent {
  const CustomerImportTemplateSelected(this.templateId);

  final String? templateId;
}

final class CustomerImportTemplateSaveRequested extends CustomerImportEvent {
  const CustomerImportTemplateSaveRequested(this.name);

  final String name;
}

final class CustomerImportTemplateDeleteRequested extends CustomerImportEvent {
  const CustomerImportTemplateDeleteRequested(this.templateId);

  final String templateId;
}

final class CustomerImportSubmitRequested extends CustomerImportEvent {
  const CustomerImportSubmitRequested();
}

final class CustomerImportReportRequested extends CustomerImportEvent {
  const CustomerImportReportRequested();
}

final class CustomerImportDuplicateResolved extends CustomerImportEvent {
  const CustomerImportDuplicateResolved({
    required this.rowNumber,
    required this.resolution,
  });

  final int rowNumber;
  final CustomerImportDuplicateResolution resolution;
}

final class CustomerImportRestarted extends CustomerImportEvent {
  const CustomerImportRestarted();
}
