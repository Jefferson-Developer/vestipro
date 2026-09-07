import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/visit_route.dart';
import '../repositories/visit_route_repository.dart';

/// Resumes the seller's already-built route for [date] (defaults to today),
/// if one exists — what makes the visit route survive an app close/reopen
/// (TASK-177).
@injectable
class GetActiveVisitRouteUseCase {
  const GetActiveVisitRouteUseCase(this._repository);

  final VisitRouteRepository _repository;

  Future<AppResult<VisitRoute?>> call({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    DateTime? date,
  }) {
    return _repository.getForDate(
      organizationId: organizationId,
      companyId: companyId,
      salesRepId: salesRepId,
      date: VisitRoute.dateKey(date ?? DateTime.now()),
    );
  }
}
