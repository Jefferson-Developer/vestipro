import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_import_job.dart';
import '../../domain/value_objects/customer_import_job_status.dart';
import '../dtos/customer_import_job_dto.dart';
import 'customer_import_mapping_codec.dart';

@injectable
final class CustomerImportJobMapper {
  const CustomerImportJobMapper();

  CustomerImportJob toEntity(CustomerImportJobDto dto) {
    return CustomerImportJob(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      fileName: dto.fileName,
      storagePath: dto.storagePath,
      reportStoragePath: dto.reportStoragePath,
      templateId: dto.templateId,
      mapping: CustomerImportMappingCodec.decode(
        hasHeaderRow: dto.hasHeaderRow,
        columnByField: dto.columnByField,
      ),
      status: CustomerImportJobStatusCode.fromCode(dto.status),
      totalRows: dto.totalRows,
      processedRows: dto.processedRows,
      importedCount: dto.importedCount,
      rejectedCount: dto.rejectedCount,
      duplicateCount: dto.duplicateCount,
      errorMessage: dto.errorMessage,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      startedAt: dto.startedAt,
      completedAt: dto.completedAt,
    );
  }
}
