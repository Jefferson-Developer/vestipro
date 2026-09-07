import '../../../../core/utils/utils.dart';
import '../entities/visit_route.dart';

/// Local-only persistence for a seller's [VisitRoute] (TASK-177): survives
/// app restart (`AppDatabase`/`VisitRoutesTable`), scoped by
/// organization/company/sales rep/day. There is no remote/Firestore
/// counterpart today — a visit route is a personal, device-local planning
/// artifact, not a synced business record (see TASK-177 conclusion doc).
abstract interface class VisitRouteRepository {
  Future<AppResult<VisitRoute?>> getForDate({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required DateTime date,
  });

  Future<AppResult<VisitRoute>> save(VisitRoute route);
}
