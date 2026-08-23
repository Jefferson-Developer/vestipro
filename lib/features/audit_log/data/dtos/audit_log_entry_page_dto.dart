import 'audit_log_entry_dto.dart';

final class AuditLogEntryPageDto {
  const AuditLogEntryPageDto({required this.items, required this.hasMore});

  final List<AuditLogEntryDto> items;
  final bool hasMore;
}
