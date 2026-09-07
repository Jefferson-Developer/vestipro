import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_checkins/visit_checkins.dart';

void main() {
  group('CheckInVisitUseCase (TASK-178)', () {
    late _InMemoryCrmActivityRepository activityRepository;
    late _FakeVisitCheckInLocationService locationService;
    late CheckInVisitUseCase useCase;

    setUp(() {
      activityRepository = _InMemoryCrmActivityRepository();
      locationService = _FakeVisitCheckInLocationService();
      useCase = CheckInVisitUseCase(
        RegisterCrmActivityUseCase(activityRepository),
        locationService,
      );
    });

    final customerCoordinates = GeoCoordinates.validated(
      latitude: -26.9,
      longitude: -49.06,
    );

    test('registers the visit evidence with captured coordinates when location '
        'permission is granted', () async {
      locationService.nextResult = AppSuccess<VisitCheckInLocationCapture>(
        VisitCheckInLocationCapture(
          status: VisitCheckInLocationStatus.captured,
          coordinates: GeoCoordinates.validated(
            latitude: -26.901,
            longitude: -49.061,
          ),
        ),
      );

      final result = await useCase(
        id: 'checkin-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        userId: 'rep-1',
        note: 'Cliente confirmou pedido',
        shareLocation: true,
        customerCoordinates: customerCoordinates,
      );

      expect(result, isA<AppSuccess<VisitCheckInResult>>());
      final checkIn = (result as AppSuccess<VisitCheckInResult>).value;
      expect(checkIn.activity.type, CrmActivityType.visit);
      expect(checkIn.activity.customerId, 'customer-1');
      expect(checkIn.location.hasCoordinates, isTrue);
      expect(checkIn.location.distanceToCustomerKm, isNotNull);
      expect(checkIn.activity.description, contains('Cliente confirmou'));
      expect(checkIn.activity.description, contains('Localização'));
      expect(locationService.captureCalls, 1);
    });

    test('still registers the check-in when location permission is denied — '
        'geolocation never blocks it', () async {
      locationService.nextResult =
          const AppSuccess<VisitCheckInLocationCapture>(
            VisitCheckInLocationCapture(
              status: VisitCheckInLocationStatus.permissionDenied,
            ),
          );

      final result = await useCase(
        id: 'checkin-2',
        organizationId: 'org-1',
        customerId: 'customer-1',
        userId: 'rep-1',
        shareLocation: true,
      );

      expect(result, isA<AppSuccess<VisitCheckInResult>>());
      final checkIn = (result as AppSuccess<VisitCheckInResult>).value;
      expect(checkIn.activity.type, CrmActivityType.visit);
      expect(checkIn.location.hasCoordinates, isFalse);
      expect(
        checkIn.location.status,
        VisitCheckInLocationStatus.permissionDenied,
      );
    });

    test('never asks for location when the seller did not opt in for this '
        'check-in', () async {
      final result = await useCase(
        id: 'checkin-3',
        organizationId: 'org-1',
        customerId: 'customer-1',
        userId: 'rep-1',
      );

      expect(result, isA<AppSuccess<VisitCheckInResult>>());
      final checkIn = (result as AppSuccess<VisitCheckInResult>).value;
      expect(checkIn.location, VisitCheckInLocationCapture.skippedByUser);
      expect(locationService.captureCalls, 0);
    });

    test('links the check-in as a visit CRM activity for the correct customer '
        '(evidence available to the timeline)', () async {
      await useCase(
        id: 'checkin-4',
        organizationId: 'org-1',
        customerId: 'customer-42',
        userId: 'rep-1',
      );

      expect(activityRepository.activities, hasLength(1));
      final stored = activityRepository.activities.single;
      expect(stored.customerId, 'customer-42');
      expect(stored.type, CrmActivityType.visit);
      expect(stored.syncStatus, CrmActivitySyncStatus.pending);
    });

    test('preserves the exact device-local check-in instant as occurredAt, '
        'independent from whenever the record is created/synced', () async {
      final checkInInstant = DateTime.utc(2026, 3, 10, 14, 30);

      final result = await useCase(
        id: 'checkin-5',
        organizationId: 'org-1',
        customerId: 'customer-1',
        userId: 'rep-1',
        now: checkInInstant,
      );

      final checkIn = (result as AppSuccess<VisitCheckInResult>).value;
      expect(checkIn.activity.occurredAt, checkInInstant);
    });

    test('propagates a failure from evidence registration without treating it '
        'as a location problem', () async {
      final result = await useCase(
        id: 'checkin-6',
        organizationId: '   ',
        customerId: 'customer-1',
        userId: 'rep-1',
      );

      expect(result, isA<AppFailure<VisitCheckInResult>>());
      expect(activityRepository.activities, isEmpty);
    });
  });
}

final class _FakeVisitCheckInLocationService
    implements VisitCheckInLocationService {
  int captureCalls = 0;
  AppResult<VisitCheckInLocationCapture> nextResult =
      const AppSuccess<VisitCheckInLocationCapture>(
        VisitCheckInLocationCapture(
          status: VisitCheckInLocationStatus.unavailable,
        ),
      );

  @override
  Future<AppResult<VisitCheckInLocationCapture>>
  captureCurrentLocation() async {
    captureCalls++;
    return nextResult;
  }
}

final class _InMemoryCrmActivityRepository implements CrmActivityRepository {
  final List<CrmActivity> activities = <CrmActivity>[];

  @override
  Future<AppResult<CrmActivity>> create({required CrmActivity activity}) async {
    activities.add(activity);
    return AppSuccess<CrmActivity>(activity);
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForCustomer({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForLead({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForOpportunity({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }
}
