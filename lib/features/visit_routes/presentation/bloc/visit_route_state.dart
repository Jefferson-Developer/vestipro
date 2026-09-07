import '../../../../core/errors/errors.dart';
import '../../../customers/domain/entities/customer_map_pin.dart';
import '../../../visit_checkins/domain/entities/visit_check_in_result.dart';
import '../../domain/entities/visit_route.dart';

enum VisitRouteStatus { initial, loading, ready, failure }

/// Status of the last visit check-in attempt (TASK-178), independent from
/// [VisitRouteStatus] (which tracks loading/building the route itself) —
/// consumed by the page to show a one-shot confirmation/error, never to
/// gate the route list itself.
enum VisitRouteCheckInStatus { idle, submitting, success, failure }

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
    this.checkInStatus = VisitRouteCheckInStatus.idle,
    this.lastCheckIn,
    this.checkInFailure,
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

  final VisitRouteCheckInStatus checkInStatus;

  /// The most recently completed check-in (evidence + location outcome),
  /// so the page can show what happened (e.g. "sem localização: permissão
  /// negada"). `null` before any check-in this session.
  final VisitCheckInResult? lastCheckIn;
  final Failure? checkInFailure;

  bool get isLoading => status == VisitRouteStatus.loading;

  bool get hasRoute => route != null && route!.stops.isNotEmpty;

  bool get isCheckingIn => checkInStatus == VisitRouteCheckInStatus.submitting;

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
    VisitRouteCheckInStatus? checkInStatus,
    VisitCheckInResult? lastCheckIn,
    bool clearLastCheckIn = false,
    Failure? checkInFailure,
    bool clearCheckInFailure = false,
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
      checkInStatus: checkInStatus ?? this.checkInStatus,
      lastCheckIn: clearLastCheckIn ? null : lastCheckIn ?? this.lastCheckIn,
      checkInFailure: clearCheckInFailure
          ? null
          : checkInFailure ?? this.checkInFailure,
    );
  }
}
