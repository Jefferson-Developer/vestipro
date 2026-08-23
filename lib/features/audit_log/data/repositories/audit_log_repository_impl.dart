import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_log_entry_page.dart';
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
    String? actorUserId,
  }) async {
    final result = await listPageByOrganization(
      organizationId: organizationId,
      limit: limit,
      before: before,
      from: from,
      to: to,
      actions: action == null ? const <AuditAction>{} : <AuditAction>{action},
      actorUserId: actorUserId,
    );

    return result.fold(
      onSuccess: (page) => AppSuccess<List<AuditLogEntry>>(page.entries),
      onFailure: AppFailure<List<AuditLogEntry>>.new,
    );
  }

  @override
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) async {
    try {
      final page = await dataSource.listPageByOrganization(
        organizationId: organizationId,
        limit: limit,
        before: before,
        from: from,
        to: to,
        actionCodes: actions.map((action) => action.code).toSet(),
        actorUserId: actorUserId,
      );
      final entries = page.items.map(mapper.toEntity).toList(growable: false);
      return AppSuccess<AuditLogEntryPage>(
        AuditLogEntryPage(
          entries: entries,
          hasMore: page.hasMore,
          nextCursor: page.hasMore && entries.isNotEmpty
              ? entries.last.timestamp
              : null,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<AuditLogEntryPage>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<AuditLogEntryPage>(
        UnexpectedFailure(
          'Unexpected error listing audit log entries.',
          code: 'audit_log_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
