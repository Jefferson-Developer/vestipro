import '../../../customers/domain/entities/customer_map_pin.dart';

sealed class VisitRouteEvent {
  const VisitRouteEvent();
}

/// Resumes today's already-built route for this seller, if any (TASK-177:
/// "retomada caso o app feche").
final class VisitRouteStarted extends VisitRouteEvent {
  const VisitRouteStarted({
    required this.organizationId,
    required this.companyId,
    required this.salesRepId,
  });

  final String organizationId;
  final String companyId;
  final String salesRepId;
}

/// The candidate customers (already geocoded, already tenant/RBAC-scoped —
/// see `CustomerMapPinBuilder`) the seller may pick from to build a route.
/// Dispatched by the page whenever the underlying `CustomerPortfolioBloc`
/// portfolio changes.
final class VisitRouteAvailablePinsChanged extends VisitRouteEvent {
  const VisitRouteAvailablePinsChanged(this.pins);

  final List<CustomerMapPin> pins;
}

/// Adds/removes a single customer from the current selection.
final class VisitRouteCustomerSelectionToggled extends VisitRouteEvent {
  const VisitRouteCustomerSelectionToggled(this.customerId);

  final String customerId;
}

/// Builds (or rebuilds) the optimized route out of the current selection.
final class VisitRouteBuildRequested extends VisitRouteEvent {
  const VisitRouteBuildRequested();
}

/// Manual reorder of an already-built route's stops (drag and drop).
final class VisitRouteStopsReordered extends VisitRouteEvent {
  const VisitRouteStopsReordered(this.orderedCustomerIds);

  final List<String> orderedCustomerIds;
}

/// Flips a stop's progress status (pending <-> completed).
final class VisitRouteStopStatusToggled extends VisitRouteEvent {
  const VisitRouteStopStatusToggled(this.customerId);

  final String customerId;
}

/// Discards the built route from view (not from disk — rebuilding today
/// simply upserts the same row) to go back to customer selection.
final class VisitRouteSelectionReopened extends VisitRouteEvent {
  const VisitRouteSelectionReopened();
}
