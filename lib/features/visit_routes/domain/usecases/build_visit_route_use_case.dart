import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/domain/entities/customer_map_pin.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../entities/visit_route.dart';
import '../repositories/visit_route_repository.dart';
import '../services/route_optimization_service.dart';

/// Builds (or rebuilds) the seller's visit route for a given day out of a
/// set of already-selected customers, then persists it (TASK-177).
///
/// [selectedPins] must come exclusively from a `CustomerMapPin` list already
/// produced for the caller's own visible portfolio (`CustomerMapPinBuilder`
/// fed by `ListCustomerPortfolioUseCase`, already tenant/RBAC-scoped, same
/// trust boundary TASK-176's map view relies on) — this use case builds no
/// query of its own and therefore introduces no new leak vector: it can
/// only ever route to customers the caller could already see.
@injectable
class BuildVisitRouteUseCase {
  const BuildVisitRouteUseCase(this._repository, this._optimizationService);

  final VisitRouteRepository _repository;
  final RouteOptimizationService _optimizationService;

  Future<AppResult<VisitRoute>> call({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required List<CustomerMapPin> selectedPins,
    GeoCoordinates? origin,
    DateTime? date,
    DateTime? now,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final normalizedSalesRepId = salesRepId.trim();
    final fieldErrors = <String, String>{};
    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (normalizedSalesRepId.isEmpty) {
      fieldErrors['salesRepId'] = 'SalesRepId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<VisitRoute>(
        ValidationFailure(
          'Invalid visit route payload.',
          code: 'invalid_visit_route_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final optimizedResult = _optimizationService.optimize(
      selectedPins: selectedPins,
      origin: origin,
    );

    return optimizedResult.fold(
      onSuccess: (stops) async {
        final dateKey = VisitRoute.dateKey(date ?? now ?? DateTime.now());
        final timestamp = (now ?? DateTime.now()).toUtc();
        final route = VisitRoute(
          id: _routeId(
            organizationId: normalizedOrganizationId,
            salesRepId: normalizedSalesRepId,
            dateKey: dateKey,
          ),
          organizationId: normalizedOrganizationId,
          companyId: normalizedCompanyId,
          salesRepId: normalizedSalesRepId,
          date: dateKey,
          stops: stops,
          createdAt: timestamp,
          updatedAt: timestamp,
        );
        return _repository.save(route);
      },
      onFailure: (failure) async => AppFailure<VisitRoute>(failure),
    );
  }

  String _routeId({
    required String organizationId,
    required String salesRepId,
    required DateTime dateKey,
  }) {
    return '${organizationId}_${salesRepId}_${dateKey.toIso8601String()}';
  }
}
