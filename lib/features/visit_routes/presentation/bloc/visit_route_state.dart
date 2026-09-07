import '../../../../core/errors/errors.dart';
import '../../../customers/domain/entities/customer_map_pin.dart';
import '../../domain/entities/visit_route.dart';

enum VisitRouteStatus { initial, loading, ready, failure }

final class VisitRouteState {
  const VisitRouteState({
    this.status = VisitRouteStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.salesRepId = '',
    this.availablePins = const <CustomerMapPin>[],
    this.selectedCustomerIds = const <String>{},
    this.route,
    this.failure,
  });

  final VisitRouteStatus status;
  final String organizationId;
  final String companyId;
  final String salesRepId;

  /// Customers the seller may pick from — already geocoded and already
  /// scoped to their own visible portfolio (see
  /// `VisitRouteAvailablePinsChanged` doc).
  final List<CustomerMapPin> availablePins;
  final Set<String> selectedCustomerIds;

  /// The built/persisted route for today, once one exists. `null` means the
  /// seller is still in the selection step (or has not built one yet).
  final VisitRoute? route;
  final Failure? failure;

  bool get isLoading => status == VisitRouteStatus.loading;

  bool get hasRoute => route != null && route!.stops.isNotEmpty;

  VisitRouteState copyWith({
    VisitRouteStatus? status,
    String? organizationId,
    String? companyId,
    String? salesRepId,
    List<CustomerMapPin>? availablePins,
    Set<String>? selectedCustomerIds,
    VisitRoute? route,
    bool clearRoute = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return VisitRouteState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      salesRepId: salesRepId ?? this.salesRepId,
      availablePins: availablePins ?? this.availablePins,
      selectedCustomerIds: selectedCustomerIds ?? this.selectedCustomerIds,
      route: clearRoute ? null : route ?? this.route,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
