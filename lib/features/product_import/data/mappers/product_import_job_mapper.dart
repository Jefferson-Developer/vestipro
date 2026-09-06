import 'package:injectable/injectable.dart';

import '../../domain/entities/product_import_job.dart';
import '../../domain/value_objects/product_import_job_status.dart';
import '../dtos/product_import_job_dto.dart';

@injectable
final class ProductImportJobMapper {
  const ProductImportJobMapper();

  ProductImportJob toEntity(ProductImportJobDto dto) {
    return ProductImportJob(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      fileName: dto.fileName,
      storagePath: dto.storagePath,
      imagesFolderPath: dto.imagesFolderPath,
      reportStoragePath: dto.reportStoragePath,
      templateId: dto.templateId,
      status: ProductImportJobStatusCode.fromCode(dto.status),
      totalRows: dto.totalRows,
      processedRows: dto.processedRows,
      createdProductsCount: dto.createdProductsCount,
      createdVariantsCount: dto.createdVariantsCount,
      imagesAssociatedCount: dto.imagesAssociatedCount,
      imagesOrphanCount: dto.imagesOrphanCount,
      rejectedCount: dto.rejectedCount,
      errorMessage: dto.errorMessage,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      startedAt: dto.startedAt,
      completedAt: dto.completedAt,
    );
  }
}
