import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/storage/storage.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_import_job.dart';
import '../../domain/entities/customer_import_mapping.dart';
import '../../domain/entities/customer_import_report.dart';
import '../../domain/repositories/customer_import_job_repository.dart';
import '../../domain/value_objects/customer_import_duplicate_resolution.dart';
import '../datasources/customer_import_functions_data_source.dart';
import '../datasources/customer_import_job_data_source.dart';
import '../mappers/customer_import_job_mapper.dart';
import '../mappers/customer_import_mapping_codec.dart';
import '../mappers/customer_import_report_mapper.dart';

/// Storage path prefix for uploaded customer-import source files/reports
/// (TASK-167) — kept alongside `StoragePaths` conventions (`organizations/
/// {organizationId}/customerImports/{jobId}/{fileName}`), never hand-built
/// at another call site.
String _customerImportSourcePath({
  required String organizationId,
  required String jobId,
  required String fileName,
}) {
  return 'organizations/$organizationId/customerImports/$jobId/source_$fileName';
}

@LazySingleton(as: CustomerImportJobRepository)
final class CustomerImportJobRepositoryImpl
    implements CustomerImportJobRepository {
  CustomerImportJobRepositoryImpl(
    this._jobDataSource,
    this._functionsDataSource,
    this._storage,
    this._jobMapper,
    this._reportMapper,
  ) : _uuid = const Uuid();

  final CustomerImportJobDataSource _jobDataSource;
  final CustomerImportFunctionsDataSource _functionsDataSource;
  final StorageDataSource _storage;
  final CustomerImportJobMapper _jobMapper;
  final CustomerImportReportMapper _reportMapper;
  final Uuid _uuid;

  @override
  Future<AppResult<CustomerImportJob>> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required CustomerImportMapping mapping,
    String? templateId,
    required String createdBy,
  }) async {
    try {
      final jobId = _uuid.v4();
      final storagePath = _customerImportSourcePath(
        organizationId: organizationId,
        jobId: jobId,
        fileName: fileName,
      );
      await _storage.uploadFile(
        path: storagePath,
        bytes: fileBytes,
        contentType: isXlsx
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'text/csv',
      );

      final returnedJobId = await _functionsDataSource.startJob(
        organizationId: organizationId,
        companyId: companyId,
        fileName: fileName,
        storagePath: storagePath,
        hasHeaderRow: mapping.hasHeaderRow,
        columnByField: CustomerImportMappingCodec.encodeColumns(mapping),
        templateId: templateId,
      );

      final dto = await _jobDataSource
          .watchJob(organizationId: organizationId, jobId: returnedJobId)
          .firstWhere((dto) => dto != null);
      if (dto == null) {
        return AppFailure<CustomerImportJob>(
          const NotFoundFailure(
            'Import job not found right after creation.',
            code: 'customer_import_job_not_found_after_create',
          ),
        );
      }
      return AppSuccess<CustomerImportJob>(_jobMapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<CustomerImportJob>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<CustomerImportJob>(
        UnexpectedFailure(
          'Unexpected error starting customer import job.',
          code: 'customer_import_job_start_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<AppResult<CustomerImportJob>> watchJob({
    required String organizationId,
    required String jobId,
  }) {
    return _jobDataSource
        .watchJob(organizationId: organizationId, jobId: jobId)
        .map((dto) {
          if (dto == null) {
            return AppFailure<CustomerImportJob>(
              const NotFoundFailure(
                'Import job not found.',
                code: 'customer_import_job_not_found',
              ),
            );
          }
          return AppSuccess<CustomerImportJob>(_jobMapper.toEntity(dto));
        });
  }

  @override
  Future<AppResult<List<CustomerImportJob>>> listByOrganization({
    required String organizationId,
    int limit = 20,
  }) async {
    try {
      final dtos = await _jobDataSource.listByOrganization(
        organizationId: organizationId,
        limit: limit,
      );
      return AppSuccess<List<CustomerImportJob>>(
        dtos.map(_jobMapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<CustomerImportJob>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<CustomerImportJob>>(
        UnexpectedFailure(
          'Unexpected error listing customer import jobs.',
          code: 'customer_import_job_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CustomerImportReport>> getReport({
    required String organizationId,
    required String jobId,
    required String reportStoragePath,
  }) async {
    try {
      final bytes = await _storage.downloadBytes(path: reportStoragePath);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return AppFailure<CustomerImportReport>(
          const ValidationFailure(
            'Invalid customer import report file.',
            code: 'invalid_customer_import_report_file',
          ),
        );
      }
      return AppSuccess<CustomerImportReport>(_reportMapper.fromJson(decoded));
    } on AppException catch (exception) {
      return AppFailure<CustomerImportReport>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<CustomerImportReport>(
        UnexpectedFailure(
          'Unexpected error loading customer import report.',
          code: 'customer_import_report_load_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> resolveDuplicateRow({
    required String organizationId,
    required String jobId,
    required int rowNumber,
    required CustomerImportDuplicateResolution resolution,
  }) async {
    try {
      await _functionsDataSource.resolveDuplicateRow(
        organizationId: organizationId,
        jobId: jobId,
        rowNumber: rowNumber,
        resolution: resolution.code,
      );
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error resolving customer import duplicate row.',
          code: 'customer_import_duplicate_resolve_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
