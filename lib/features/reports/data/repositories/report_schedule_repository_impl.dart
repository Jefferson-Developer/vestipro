import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_schedule.dart';
import '../../domain/repositories/report_schedule_repository.dart';
import '../datasources/report_schedule_remote_data_source.dart';
import '../dtos/report_schedule_dto.dart';

@LazySingleton(as: ReportScheduleRepository)
final class ReportScheduleRepositoryImpl implements ReportScheduleRepository {
  const ReportScheduleRepositoryImpl(this._remote);

  final ReportScheduleRemoteDataSource _remote;

  @override
  Future<AppResult<List<ReportSchedule>>> listByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final dtos = await _remote.listByOrganization(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<ReportSchedule>>(
        dtos.map((dto) => dto.toEntity()).toList(growable: false),
      );
    } on AppException catch (error) {
      return AppFailure<List<ReportSchedule>>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<List<ReportSchedule>>(
        UnexpectedFailure(
          'Não foi possível carregar os agendamentos de relatório.',
          code: 'report_schedule_list_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportSchedule>> create(ReportSchedule schedule) async {
    try {
      await _remote.create(ReportScheduleDto.fromEntity(schedule));
      return AppSuccess<ReportSchedule>(schedule);
    } on AppException catch (error) {
      return AppFailure<ReportSchedule>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportSchedule>(
        UnexpectedFailure(
          'Não foi possível criar o agendamento de relatório.',
          code: 'report_schedule_create_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportSchedule>> update(ReportSchedule schedule) async {
    try {
      await _remote.update(ReportScheduleDto.fromEntity(schedule));
      return AppSuccess<ReportSchedule>(schedule);
    } on AppException catch (error) {
      return AppFailure<ReportSchedule>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportSchedule>(
        UnexpectedFailure(
          'Não foi possível atualizar o agendamento de relatório.',
          code: 'report_schedule_update_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String scheduleId,
  }) async {
    try {
      await _remote.delete(organizationId: organizationId, id: scheduleId);
      return const AppSuccess<void>(null);
    } on AppException catch (error) {
      return AppFailure<void>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Não foi possível excluir o agendamento de relatório.',
          code: 'report_schedule_delete_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> hasActiveScheduleReferencing({
    required String organizationId,
    required String savedReportId,
  }) async {
    try {
      final dtos = await _remote.listActiveBySavedReportId(
        organizationId: organizationId,
        savedReportId: savedReportId,
      );
      return AppSuccess<bool>(dtos.isNotEmpty);
    } on AppException catch (error) {
      return AppFailure<bool>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Não foi possível verificar agendamentos vinculados a esta visualização.',
          code: 'report_schedule_reference_check_unexpected',
          cause: error,
        ),
      );
    }
  }
}
