import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/visit_route.dart';
import '../../domain/repositories/visit_route_repository.dart';
import '../mappers/visit_route_local_mapper.dart';

/// Local-only [VisitRouteRepository] (TASK-177): [AppDatabase]'s
/// [VisitRoutesTable] is the sole source of truth, no remote call involved —
/// a visit route is a device-local planning artifact (see this feature's
/// domain repository doc).
@LazySingleton(as: VisitRouteRepository)
final class DriftVisitRouteRepository implements VisitRouteRepository {
  const DriftVisitRouteRepository(this._database, this._mapper);

  final AppDatabase _database;
  final VisitRouteLocalMapper _mapper;

  @override
  Future<AppResult<VisitRoute?>> getForDate({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required DateTime date,
  }) async {
    try {
      final row = await _database.getVisitRoute(
        organizationId: organizationId,
        salesRepId: salesRepId,
        date: date,
      );
      return AppSuccess<VisitRoute?>(
        row == null ? null : _mapper.toEntity(row),
      );
    } catch (exception) {
      return AppFailure<VisitRoute?>(
        UnexpectedFailure(
          'Unexpected error loading the visit route.',
          code: 'visit_route_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<VisitRoute>> save(VisitRoute route) async {
    try {
      await _database.upsertVisitRoute(_mapper.toRow(route));
      return AppSuccess<VisitRoute>(route);
    } catch (exception) {
      return AppFailure<VisitRoute>(
        UnexpectedFailure(
          'Unexpected error saving the visit route.',
          code: 'visit_route_save_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
