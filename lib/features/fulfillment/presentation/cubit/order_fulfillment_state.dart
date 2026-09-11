import '../../domain/entities/logistics_issue.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/tracking_event.dart';

enum OrderFulfillmentStatus { initial, loading, ready, failure }

/// Drives [OrderFulfillmentPanel] (TASK-214, EPIC-32) — the pedido's own
/// rastreio logístico section embedded in `OrderHistoryPage`. Only the most
/// recently created `Shipment` for the pedido is watched in detail
/// ([trackingEvents]/[logisticsIssues]); [shipments] still lists every
/// romaneio ever opened for it (see [OrderFulfillmentState.hasEarlierShipments]),
/// a deliberate scope decision documented in this task's "Pendências" —
/// entregas parciais expedidas em mais de um romaneio separado are rare
/// enough in fashion B2B that a full multi-shipment detail view was not
/// justified for this task's scope.
final class OrderFulfillmentState {
  const OrderFulfillmentState({
    this.status = OrderFulfillmentStatus.initial,
    this.shipments = const <Shipment>[],
    this.trackingEvents = const <TrackingEvent>[],
    this.logisticsIssues = const <LogisticsIssue>[],
    this.failureMessage,
    this.isSubmittingIssue = false,
    this.issueFailureMessage,
    this.lastRegisteredIssueId,
    this.lastResolvedIssueId,
  });

  final OrderFulfillmentStatus status;
  final List<Shipment> shipments;
  final List<TrackingEvent> trackingEvents;
  final List<LogisticsIssue> logisticsIssues;
  final String? failureMessage;
  final bool isSubmittingIssue;
  final String? issueFailureMessage;

  /// Set (once) right after `reportIssue`/`resolveIssue` succeeds — a
  /// one-shot signal the widget consumes to show a confirmation snackbar
  /// without re-showing it on every rebuild.
  final String? lastRegisteredIssueId;
  final String? lastResolvedIssueId;

  Shipment? get selectedShipment => shipments.isEmpty ? null : shipments.last;

  bool get hasEarlierShipments => shipments.length > 1;

  bool get isLoading =>
      status == OrderFulfillmentStatus.initial ||
      status == OrderFulfillmentStatus.loading;

  OrderFulfillmentState copyWith({
    OrderFulfillmentStatus? status,
    List<Shipment>? shipments,
    List<TrackingEvent>? trackingEvents,
    List<LogisticsIssue>? logisticsIssues,
    String? failureMessage,
    bool clearFailureMessage = false,
    bool? isSubmittingIssue,
    String? issueFailureMessage,
    bool clearIssueFailureMessage = false,
    String? lastRegisteredIssueId,
    String? lastResolvedIssueId,
  }) {
    return OrderFulfillmentState(
      status: status ?? this.status,
      shipments: shipments ?? this.shipments,
      trackingEvents: trackingEvents ?? this.trackingEvents,
      logisticsIssues: logisticsIssues ?? this.logisticsIssues,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      isSubmittingIssue: isSubmittingIssue ?? this.isSubmittingIssue,
      issueFailureMessage: clearIssueFailureMessage
          ? null
          : (issueFailureMessage ?? this.issueFailureMessage),
      lastRegisteredIssueId:
          lastRegisteredIssueId ?? this.lastRegisteredIssueId,
      lastResolvedIssueId: lastResolvedIssueId ?? this.lastResolvedIssueId,
    );
  }
}
