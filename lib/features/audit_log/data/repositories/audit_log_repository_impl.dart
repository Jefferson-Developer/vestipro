import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/value_objects/audit_action.dart';
import '../datasources/audit_log_data_source.dart';
import '../mappers/audit_log_entry_mapper.dart';

@LazySingleton(as: AuditLogRepository)
final class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final AuditLogDataSource dataSource;
  final AuditLogEntryMapper mapper;

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    try {
      final createdDto = await dataSource.record(mapper.toDto(entry));
      return AppSuccess<AuditLogEntry>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<AuditLogEntry>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<AuditLogEntry>(
        UnexpectedFailure(
          'Unexpected error recording audit log entry.',
          code: 'audit_log_record_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
  }) async {
    try {
      final dtos = await dataSource.listByOrganization(
        organizationId: organizationId,
        limit: limit,
        before: before,
        from: from,
        to: to,
        actionCode: action?.code,
      );
      return AppSuccess<List<AuditLogEntry>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<AuditLogEntry>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<AuditLogEntry>>(
        UnexpectedFailure(
          'Unexpected error listing audit log entries.',
          code: 'audit_log_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
