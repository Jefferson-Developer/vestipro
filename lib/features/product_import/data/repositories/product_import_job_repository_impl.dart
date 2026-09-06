import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/storage/storage.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_import_job.dart';
import '../../domain/entities/product_import_lookup.dart';
import '../../domain/entities/product_import_mapping.dart';
import '../../domain/entities/product_import_report.dart';
import '../../domain/repositories/product_import_job_repository.dart';
import '../datasources/product_import_functions_data_source.dart';
import '../datasources/product_import_job_data_source.dart';
import '../mappers/product_import_job_mapper.dart';
import '../mappers/product_import_mapping_codec.dart';
import '../mappers/product_import_report_mapper.dart';

/// Storage path prefix for an uploaded product-import source file (TASK-168)
/// — mirrors `_customerImportSourcePath` (TASK-167). `batchId` is a
/// client-generated id used only to namespace this upload, independent of
/// the Firestore job id the `startProductImportJob` callable later creates.
String _productImportSourcePath({
  required String organizationId,
  required String batchId,
  required String fileName,
}) {
  return 'organizations/$organizationId/productImports/$batchId/source_$fileName';
}

String _productImportImagePath({
  required String organizationId,
  required String batchId,
  required String fileName,
}) {
  return 'organizations/$organizationId/productImports/$batchId/images/$fileName';
}

@LazySingleton(as: ProductImportJobRepository)
final class ProductImportJobRepositoryImpl
    implements ProductImportJobRepository {
  ProductImportJobRepositoryImpl(
    this._jobDataSource,
    this._functionsDataSource,
    this._storage,
    this._jobMapper,
    this._reportMapper,
  ) : _uuid = const Uuid();

  final ProductImportJobDataSource _jobDataSource;
  final ProductImportFunctionsDataSource _functionsDataSource;
  final StorageDataSource _storage;
  final ProductImportJobMapper _jobMapper;
  final ProductImportReportMapper _reportMapper;
  final Uuid _uuid;

  @override
  Future<AppResult<ProductImportJob>> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required ProductImportMapping mapping,
    required ProductImportLookup lookup,
    required bool createMissingCategories,
    required bool createMissingCollections,
    Map<String, Uint8List>? imageBytesByFileName,
    String? templateId,
    required String createdBy,
  }) async {
    try {
      final batchId = _uuid.v4();
      final storagePath = _productImportSourcePath(
        organizationId: organizationId,
        batchId: batchId,
        fileName: fileName,
      );
      await _storage.uploadFile(
        path: storagePath,
        bytes: fileBytes,
        contentType: isXlsx
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'text/csv',
      );

      String? imagesFolderPath;
      final images = imageBytesByFileName;
      if (images != null && images.isNotEmpty) {
        imagesFolderPath =
            'organizations/$organizationId/productImports/$batchId/images/';
        for (final entry in images.entries) {
          await _storage.uploadFile(
            path: _productImportImagePath(
              organizationId: organizationId,
              batchId: batchId,
              fileName: entry.key,
            ),
            bytes: entry.value,
            contentType: _imageContentTypeForFileName(entry.key),
          );
        }
      }

      final returnedJobId = await _functionsDataSource.startJob(
        organizationId: organizationId,
        companyId: companyId,
        fileName: fileName,
        storagePath: storagePath,
        imagesFolderPath: imagesFolderPath,
        hasHeaderRow: mapping.hasHeaderRow,
        columnByField: ProductImportMappingCodec.encodeColumns(mapping),
        sizeGridTemplateId: mapping.sizeGridTemplateId,
        categoryIdByName: lookup.categoryIdByName,
        collectionIdByName: lookup.collectionIdByName,
        colorIdByName: lookup.colorIdByName,
        sizeIdByLabel: lookup.sizeIdByLabel,
        createMissingCategories: createMissingCategories,
        createMissingCollections: createMissingCollections,
        templateId: templateId,
      );

      final dto = await _jobDataSource
          .watchJob(organizationId: organizationId, jobId: returnedJobId)
          .firstWhere((dto) => dto != null);
      if (dto == null) {
        return AppFailure<ProductImportJob>(
          const NotFoundFailure(
            'Import job not found right after creation.',
            code: 'product_import_job_not_found_after_create',
          ),
        );
      }
      return AppSuccess<ProductImportJob>(_jobMapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<ProductImportJob>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<ProductImportJob>(
        UnexpectedFailure(
          'Unexpected error starting product import job.',
          code: 'product_import_job_start_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<AppResult<ProductImportJob>> watchJob({
    required String organizationId,
    required String jobId,
  }) {
    return _jobDataSource
        .watchJob(organizationId: organizationId, jobId: jobId)
        .map((dto) {
          if (dto == null) {
            return AppFailure<ProductImportJob>(
              const NotFoundFailure(
                'Import job not found.',
                code: 'product_import_job_not_found',
              ),
            );
          }
          return AppSuccess<ProductImportJob>(_jobMapper.toEntity(dto));
        });
  }

  @override
  Future<AppResult<List<ProductImportJob>>> listByOrganization({
    required String organizationId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _jobDataSource.listByOrganization(
        organizationId: organizationId,
        limit: limit,
      );
      return AppSuccess<List<ProductImportJob>>(
        dtos.map(_jobMapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<ProductImportJob>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<ProductImportJob>>(
        UnexpectedFailure(
          'Unexpected error listing product import jobs.',
          code: 'product_import_job_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductImportReport>> getReport({
    required String organizationId,
    required String jobId,
    required String reportStoragePath,
  }) async {
    try {
      final bytes = await _storage.downloadBytes(path: reportStoragePath);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return AppFailure<ProductImportReport>(
          const ValidationFailure(
            'Invalid product import report file.',
            code: 'invalid_product_import_report_file',
          ),
        );
      }
      return AppSuccess<ProductImportReport>(_reportMapper.fromJson(decoded));
    } on AppException catch (exception) {
      return AppFailure<ProductImportReport>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ProductImportReport>(
        UnexpectedFailure(
          'Unexpected error loading product import report.',
          code: 'product_import_report_load_unexpected',
          cause: exception,
        ),
      );
    }
  }

  String _imageContentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
