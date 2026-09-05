import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/membership.dart';
import '../../../organizations/domain/repositories/membership_repository.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/report_export_result.dart';
import '../entities/report_schedule.dart';
import '../entities/saved_report.dart';
import '../repositories/report_schedule_repository.dart';
import '../services/report_schedule_next_run_calculator.dart';

Future<AppResult<Membership>> _resolveActiveMembership(
  MembershipRepository membershipRepository, {
  required String organizationId,
  required String userId,
}) async {
  final result = await membershipRepository.getByUser(
    organizationId: organizationId,
    userId: userId,
  );
  return result.fold(
    onSuccess: (membership) {
      if (membership.status != MembershipStatus.active) {
        return AppFailure<Membership>(
          const PermissionFailure(
            'Usuário não está mais ativo nesta organização.',
            code: 'report_schedule_requester_inactive',
          ),
        );
      }
      return AppSuccess<Membership>(membership);
    },
    onFailure: (failure) {
      if (failure is NotFoundFailure) {
        return AppFailure<Membership>(
          const PermissionFailure(
            'Usuário não está ativo nesta organização.',
            code: 'report_schedule_requester_inactive',
          ),
        );
      }
      return AppFailure<Membership>(failure);
    },
  );
}

bool _isOwnerOrAdmin(Membership membership) =>
    membership.roleName == SystemRoleName.owner.code ||
    membership.roleName == SystemRoleName.admin.code;

/// Whether [requesterId] may manage (pause/delete) [schedule]: its own
/// creator, or an OWNER/ADMIN — same "creator or admin" precedent as
/// `UpdateSavedReport`/`DeleteSavedReport` (TASK-145), never the wider
/// `Capability.reportSchedule` audience alone (which also grants *creating*
/// a new schedule, a strictly different action).
Future<AppResult<void>> _authorizeManage(
  MembershipRepository membershipRepository, {
  required String requesterId,
  required ReportSchedule schedule,
}) async {
  final membershipResult = await _resolveActiveMembership(
    membershipRepository,
    organizationId: schedule.organizationId,
    userId: requesterId,
  );
  if (membershipResult is AppFailure<Membership>) {
    return AppFailure<void>(membershipResult.failure);
  }
  final membership = (membershipResult as AppSuccess<Membership>).value;
  if (schedule.createdBy != requesterId && !_isOwnerOrAdmin(membership)) {
    return AppFailure<void>(
      const PermissionFailure(
        'Apenas quem criou o agendamento ou um administrador podem '
        'gerenciá-lo.',
        code: 'report_schedule_manage_denied',
      ),
    );
  }
  return const AppSuccess<void>(null);
}

/// Creates a periodic delivery (TASK-149) for an existing [SavedReport]
/// (TASK-145). Only `SALES_MANAGER`/`ADMIN`/`OWNER`
/// ([Capability.reportSchedule]) may call this successfully — never a plain
/// `SALES_REP`/`FINANCE`/`SALES_ASSISTANT`, even for their own saved view.
@injectable
final class CreateReportSchedule {
  CreateReportSchedule(
    this._repository,
    this._membershipRepository,
    this._permissionService, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  final ReportScheduleRepository _repository;
  final MembershipRepository _membershipRepository;
  final PermissionService _permissionService;
  final Uuid _uuid;

  Future<AppResult<ReportSchedule>> call({
    required String requesterId,
    required SavedReport savedReport,
    required ReportScheduleFrequency frequency,
    int? weekday,
    int? dayOfMonth,
    required int hour,
    required int minute,
    required ReportExportFormat format,
    ReportExportLocale locale = ReportExportLocale.ptBr,
    required List<String> recipientUserIds,
  }) async {
    final membershipResult = await _resolveActiveMembership(
      _membershipRepository,
      organizationId: savedReport.organizationId,
      userId: requesterId,
    );
    if (membershipResult is AppFailure<Membership>) {
      return AppFailure<ReportSchedule>(membershipResult.failure);
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: savedReport.organizationId,
      userId: requesterId,
      capability: Capability.reportSchedule,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<ReportSchedule>(permissionResult.failure);
    }
    final canSchedule = (permissionResult as AppSuccess<bool>).value;
    if (!canSchedule) {
      return AppFailure<ReportSchedule>(
        const PermissionFailure(
          'Seu perfil não pode agendar relatórios.',
          code: 'report_schedule_create_denied',
        ),
      );
    }

    final fieldErrors = <String, String>{};
    if (frequency == ReportScheduleFrequency.weekly &&
        (weekday == null ||
            weekday < DateTime.monday ||
            weekday > DateTime.sunday)) {
      fieldErrors['weekday'] = 'Selecione um dia da semana válido.';
    }
    if (frequency == ReportScheduleFrequency.monthly &&
        (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 28)) {
      fieldErrors['dayOfMonth'] = 'Selecione um dia do mês entre 1 e 28.';
    }
    if (hour < 0 || hour > 23) {
      fieldErrors['hour'] = 'Informe uma hora entre 0 e 23.';
    }
    if (minute < 0 || minute > 59) {
      fieldErrors['minute'] = 'Informe um minuto entre 0 e 59.';
    }
    final distinctRecipients = recipientUserIds.toSet().toList(growable: false);
    if (distinctRecipients.isEmpty) {
      fieldErrors['recipientUserIds'] =
          'Informe ao menos um destinatário para o agendamento.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ReportSchedule>(
        ValidationFailure(
          'Não foi possível agendar o relatório.',
          fieldErrors: fieldErrors,
          code: 'report_schedule_invalid',
        ),
      );
    }

    for (final recipientId in distinctRecipients) {
      final recipientMembershipResult = await _resolveActiveMembership(
        _membershipRepository,
        organizationId: savedReport.organizationId,
        userId: recipientId,
      );
      if (recipientMembershipResult is AppFailure<Membership>) {
        return AppFailure<ReportSchedule>(
          ValidationFailure(
            'Um ou mais destinatários não são membros ativos desta '
            'organização.',
            fieldErrors: <String, String>{
              'recipientUserIds': 'Remova destinatários inativos ou inválidos.',
            },
            code: 'report_schedule_invalid_recipient',
          ),
        );
      }
    }

    final now = DateTime.now();
    final nextRunAt = ReportScheduleNextRunCalculator.compute(
      frequency: frequency,
      weekday: weekday,
      dayOfMonth: dayOfMonth,
      hour: hour,
      minute: minute,
      from: now,
    );

    final schedule = ReportSchedule(
      id: _uuid.v4(),
      organizationId: savedReport.organizationId,
      companyId: savedReport.companyId,
      savedReportId: savedReport.id,
      savedReportName: savedReport.name,
      frequency: frequency,
      weekday: frequency == ReportScheduleFrequency.weekly ? weekday : null,
      dayOfMonth: frequency == ReportScheduleFrequency.monthly
          ? dayOfMonth
          : null,
      hour: hour,
      minute: minute,
      format: format,
      locale: locale,
      recipientUserIds: distinctRecipients,
      status: ReportScheduleStatus.active,
      nextRunAt: nextRunAt,
      createdAt: now,
      createdBy: requesterId,
      updatedAt: now,
      updatedBy: requesterId,
    );

    return _repository.create(schedule);
  }
}

/// Suspends [ReportSchedule.status] to [ReportScheduleStatus.paused]
/// (TASK-149) — configuration and delivery history are kept untouched, only
/// future cycles stop firing. Callable by [ReportSchedule.createdBy] or an
/// OWNER/ADMIN.
@injectable
final class PauseReportSchedule {
  const PauseReportSchedule(this._repository, this._membershipRepository);

  final ReportScheduleRepository _repository;
  final MembershipRepository _membershipRepository;

  Future<AppResult<ReportSchedule>> call({
    required String requesterId,
    required ReportSchedule schedule,
  }) async {
    final authorization = await _authorizeManage(
      _membershipRepository,
      requesterId: requesterId,
      schedule: schedule,
    );
    if (authorization is AppFailure<void>) {
      return AppFailure<ReportSchedule>(authorization.failure);
    }

    final updated = schedule.copyWith(
      status: ReportScheduleStatus.paused,
      updatedAt: DateTime.now(),
      updatedBy: requesterId,
      version: schedule.version + 1,
    );
    return _repository.update(updated);
  }
}

/// Permanently removes a [ReportSchedule] (TASK-149) — no future cycle ever
/// fires again. Never removes anything from `reportScheduleDeliveries`
/// (TASK-149's own delivery history), same "delete never touches history"
/// precedent audit-adjacent collections already follow elsewhere. Callable
/// by [ReportSchedule.createdBy] or an OWNER/ADMIN.
@injectable
final class DeleteReportSchedule {
  const DeleteReportSchedule(this._repository, this._membershipRepository);

  final ReportScheduleRepository _repository;
  final MembershipRepository _membershipRepository;

  Future<AppResult<void>> call({
    required String requesterId,
    required ReportSchedule schedule,
  }) async {
    final authorization = await _authorizeManage(
      _membershipRepository,
      requesterId: requesterId,
      schedule: schedule,
    );
    if (authorization is AppFailure<void>) {
      return AppFailure<void>(authorization.failure);
    }

    return _repository.delete(
      organizationId: schedule.organizationId,
      scheduleId: schedule.id,
    );
  }
}

/// Every [ReportSchedule] configured in one organization/company (TASK-149)
/// — the "tela mínima de gestão de agendamentos" list. Requires
/// [Capability.reportSchedule], same gate as [CreateReportSchedule].
@injectable
final class ListReportSchedules {
  const ListReportSchedules(this._repository, this._permissionService);

  final ReportScheduleRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<List<ReportSchedule>>> call({
    required String organizationId,
    required String companyId,
    required String requesterId,
  }) async {
    final permissionResult = await _permissionService.hasPermission(
      organizationId: organizationId,
      userId: requesterId,
      capability: Capability.reportSchedule,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<List<ReportSchedule>>(permissionResult.failure);
    }
    final canList = (permissionResult as AppSuccess<bool>).value;
    if (!canList) {
      return AppFailure<List<ReportSchedule>>(
        const PermissionFailure(
          'Seu perfil não pode visualizar agendamentos de relatório.',
          code: 'report_schedule_list_denied',
        ),
      );
    }

    return _repository.listByOrganization(
      organizationId: organizationId,
      companyId: companyId,
    );
  }
}
