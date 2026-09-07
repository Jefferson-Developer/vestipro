import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/visit_route.dart';
import '../value_objects/visit_route_stop_status.dart';
import '../repositories/visit_route_repository.dart';

/// Persists a stop's progress status within an already-built [VisitRoute]
/// (TASK-177: "marcar progresso conforme os check-ins forem feitos").
///
/// This only flips/persists the status field — it implements no check-in
/// business rule of its own (geofencing, evidence, timestamps, ...). That
/// belongs to TASK-178, which is expected to call this same use case (or a
/// thin wrapper around this same repository) once a check-in is confirmed.
@injectable
class MarkVisitRouteStopStatusUseCase {
  const MarkVisitRouteStopStatusUseCase(this._repository);

  final VisitRouteRepository _repository;

  Future<AppResult<VisitRoute>> call({
    required VisitRoute route,
    required String customerId,
    required VisitRouteStopStatus status,
    DateTime? now,
  }) async {
    final index = route.stops.indexWhere(
      (stop) => stop.customerId == customerId,
    );
    if (index == -1) {
      return AppFailure<VisitRoute>(
        ValidationFailure(
          'Customer $customerId is not a stop of this visit route.',
          code: 'visit_route_stop_not_found',
        ),
      );
    }

    final updatedStops = List.of(route.stops);
    updatedStops[index] = updatedStops[index].copyWith(status: status);
    final updated = route.copyWith(
      stops: updatedStops,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
    return _repository.save(updated);
  }
}
