import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/saved_report.dart';
import '../../domain/repositories/saved_report_repository.dart';
import '../datasources/saved_report_remote_data_source.dart';
import '../dtos/saved_report_dto.dart';

@LazySingleton(as: SavedReportRepository)
final class SavedReportRepositoryImpl implements SavedReportRepository {
  const SavedReportRepositoryImpl(this._remote);

  final SavedReportRemoteDataSource _remote;

  @override
  Future<AppResult<List<SavedReport>>> listOwned({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    try {
      final dtos = await _remote.listOwned(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      );
      return AppSuccess<List<SavedReport>>(
        dtos.map((dto) => dto.toEntity()).toList(growable: false),
      );
    } on AppException catch (error) {
      return AppFailure<List<SavedReport>>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<List<SavedReport>>(
        UnexpectedFailure(
          'Não foi possível carregar suas visualizações salvas.',
          code: 'saved_report_list_owned_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<SavedReport>>> listSharedWithMe({
    required String organizationId,
    required String companyId,
    required String userId,
    required List<String> teamIds,
  }) async {
    try {
      final dtos = await _remote.listNonPrivate(
        organizationId: organizationId,
        companyId: companyId,
      );
      final teamIdSet = teamIds.toSet();
      final shared = dtos
          .where((dto) {
            if (dto.ownerId == userId) return false;
            if (dto.visibility == SavedReportVisibility.organization) {
              return true;
            }
            if (dto.visibility == SavedReportVisibility.team) {
              return dto.sharedWithTeamIds.any(teamIdSet.contains);
            }
            return false;
          })
          .map((dto) => dto.toEntity())
          .toList(growable: false);
      return AppSuccess<List<SavedReport>>(shared);
    } on AppException catch (error) {
      return AppFailure<List<SavedReport>>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<List<SavedReport>>(
        UnexpectedFailure(
          'Não foi possível carregar as visualizações compartilhadas.',
          code: 'saved_report_list_shared_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<SavedReport>> create(SavedReport report) async {
    try {
      await _remote.create(SavedReportDto.fromEntity(report));
      return AppSuccess<SavedReport>(report);
    } on AppException catch (error) {
      return AppFailure<SavedReport>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<SavedReport>(
        UnexpectedFailure(
          'Não foi possível salvar a visualização.',
          code: 'saved_report_create_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<SavedReport>> update(SavedReport report) async {
    try {
      await _remote.update(SavedReportDto.fromEntity(report));
      return AppSuccess<SavedReport>(report);
    } on AppException catch (error) {
      return AppFailure<SavedReport>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<SavedReport>(
        UnexpectedFailure(
          'Não foi possível atualizar a visualização.',
          code: 'saved_report_update_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String reportId,
  }) async {
    try {
      await _remote.delete(organizationId: organizationId, id: reportId);
      return const AppSuccess<void>(null);
    } on AppException catch (error) {
      return AppFailure<void>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Não foi possível excluir a visualização.',
          code: 'saved_report_delete_unexpected',
          cause: error,
        ),
      );
    }
  }
}
