import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/visit_route.dart';
import '../entities/visit_route_stop.dart';
import '../repositories/visit_route_repository.dart';

/// Applies a manual reorder of an already-built [VisitRoute]'s stops
/// (TASK-177: "o vendedor sempre pode reordenar ou remover paradas
/// manualmente antes de sair").
///
/// [orderedCustomerIds] must be exactly a permutation of [route]'s current
/// stop ids — this use case never adds or drops a stop, only resequences
/// the ones already there, and recomputes each stop's
/// distance/eta-from-previous from the new adjacency.
@injectable
class ReorderVisitRouteStopsUseCase {
  const ReorderVisitRouteStopsUseCase(this._repository);

  final VisitRouteRepository _repository;

  Future<AppResult<VisitRoute>> call({
    required VisitRoute route,
    required List<String> orderedCustomerIds,
    DateTime? now,
  }) async {
    final currentIds = route.stops.map((stop) => stop.customerId).toSet();
    final requestedIds = orderedCustomerIds.toSet();
    if (requestedIds.length != orderedCustomerIds.length ||
        !currentIds.containsAll(requestedIds) ||
        !requestedIds.containsAll(currentIds)) {
      return const AppFailure<VisitRoute>(
        ValidationFailure(
          'Reordered stops must be exactly the same stops already in the '
          'route.',
          code: 'visit_route_reorder_invalid_permutation',
        ),
      );
    }

    final stopsByCustomerId = <String, VisitRouteStop>{
      for (final stop in route.stops) stop.customerId: stop,
    };

    final reordered = <VisitRouteStop>[];
    for (var index = 0; index < orderedCustomerIds.length; index++) {
      final original = stopsByCustomerId[orderedCustomerIds[index]]!;
      final previous = index == 0 ? null : reordered[index - 1];
      final distanceKm = previous?.coordinates.distanceToKm(
        original.coordinates,
      );
      reordered.add(
        original.copyWith(
          sequence: index,
          distanceFromPreviousKm: distanceKm,
          etaMinutesFromPrevious: distanceKm == null
              ? null
              : ((distanceKm / 30) * 60).round(),
        ),
      );
    }

    final updated = route.copyWith(
      stops: reordered,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
    return _repository.save(updated);
  }
}
