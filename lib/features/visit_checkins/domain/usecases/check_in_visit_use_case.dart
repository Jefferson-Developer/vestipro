import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../crm/crm.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../entities/visit_check_in_location_capture.dart';
import '../entities/visit_check_in_result.dart';
import '../services/visit_check_in_location_service.dart';
import '../value_objects/visit_check_in_location_status.dart';

/// Registers a seller's visit check-in (TASK-178, EPIC-24).
///
/// Owns exactly two concerns, neither of which ever blocks the other:
/// - Evidence: always registers a `visit` CRM activity linked to the
///   customer (`RegisterCrmActivityUseCase`, TASK-059's existing
///   timeline/repository — nothing new added to that entity), preserving
///   the exact device-local check-in instant as [CrmActivity.occurredAt]
///   regardless of whenever this record eventually gets synced.
/// - Location: only ever captured when [shareLocation] is `true` (explicit,
///   per-check-in consent) — denial/unavailability of location never fails
///   the check-in, it only changes what
///   [VisitCheckInResult.location]/[VisitCheckInLocationCapture.status]
///   reports back for the UI to explain.
///
/// Deliberately does **not** know about visit routes (TASK-177): marking a
/// route stop as visited after a successful check-in is the caller's
/// responsibility (e.g. `VisitRouteBloc`, which already holds the active
/// route and its own `MarkVisitRouteStopStatusUseCase`) — keeping this use
/// case's dependencies to `crm`/`customers` only avoids a circular
/// feature dependency between `visit_checkins` and `visit_routes`.
@injectable
class CheckInVisitUseCase {
  const CheckInVisitUseCase(this._registerCrmActivity, this._locationService);

  final RegisterCrmActivityUseCase _registerCrmActivity;
  final VisitCheckInLocationService _locationService;

  Future<AppResult<VisitCheckInResult>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String customerId,
    required String userId,
    String? note,
    bool shareLocation = false,
    GeoCoordinates? customerCoordinates,
    DateTime? now,
  }) async {
    final checkInAt = (now ?? DateTime.now()).toUtc();

    final location = await _captureLocation(
      shareLocation: shareLocation,
      customerCoordinates: customerCoordinates,
    );

    final activityResult = await _registerCrmActivity(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      type: CrmActivityType.visit,
      customerId: customerId,
      userId: userId,
      occurredAt: checkInAt,
      description: _buildDescription(note: note, location: location),
    );

    switch (activityResult) {
      case AppFailure<CrmActivity>(failure: final failure):
        return AppFailure<VisitCheckInResult>(failure);
      case AppSuccess<CrmActivity>(value: final activity):
        return AppSuccess<VisitCheckInResult>(
          VisitCheckInResult(activity: activity, location: location),
        );
    }
  }

  Future<VisitCheckInLocationCapture> _captureLocation({
    required bool shareLocation,
    required GeoCoordinates? customerCoordinates,
  }) async {
    if (!shareLocation) return VisitCheckInLocationCapture.skippedByUser;

    final result = await _locationService.captureCurrentLocation();
    return switch (result) {
      AppSuccess<VisitCheckInLocationCapture>(value: final capture) =>
        capture.withDistanceTo(customerCoordinates),
      AppFailure<VisitCheckInLocationCapture>() =>
        const VisitCheckInLocationCapture(
          status: VisitCheckInLocationStatus.unavailable,
        ),
    };
  }

  String _buildDescription({
    required String? note,
    required VisitCheckInLocationCapture location,
  }) {
    final trimmedNote = note?.trim();
    final buffer = StringBuffer('Check-in de visita.');
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(trimmedNote);
    }

    final coordinates = location.coordinates;
    if (coordinates != null) {
      buffer
        ..write(' [Localização: ')
        ..write(coordinates.latitude.toStringAsFixed(6))
        ..write(', ')
        ..write(coordinates.longitude.toStringAsFixed(6));
      final distance = location.distanceToCustomerKm;
      if (distance != null) {
        buffer
          ..write(' · ~')
          ..write(distance.toStringAsFixed(2))
          ..write(' km do endereço cadastrado do cliente');
      }
      buffer.write(']');
    } else if (location.status != VisitCheckInLocationStatus.skippedByUser) {
      buffer
        ..write(' [')
        ..write(location.status.label)
        ..write(']');
    }
    return buffer.toString();
  }
}
