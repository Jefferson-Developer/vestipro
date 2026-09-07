import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/data/mappers/visit_route_local_mapper.dart';
import 'package:vestipro/features/visit_routes/data/repositories/drift_visit_route_repository.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('DriftVisitRouteRepository (TASK-177)', () {
    late File dbFile;

    setUp(() {
      dbFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task177_route_'
        '${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
    });

    tearDown(() {
      if (dbFile.existsSync()) dbFile.deleteSync();
    });

    test('a saved route survives the app being closed and reopened (a new '
        'AppDatabase instance against the same on-disk file resolves the '
        'exact same route back)', () async {
      const mapper = VisitRouteLocalMapper();
      final now = DateTime.utc(2026, 9, 7, 8);
      final route = VisitRoute(
        id: 'org-1_rep-1_2026-09-07',
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: VisitRoute.dateKey(now),
        stops: <VisitRouteStop>[
          VisitRouteStop(
            customerId: 'customer-1',
            displayName: 'Cliente 1',
            coordinates: GeoCoordinates.validated(
              latitude: -26.9194,
              longitude: -49.0661,
            ),
            sequence: 0,
          ),
          VisitRouteStop(
            customerId: 'customer-2',
            displayName: 'Cliente 2',
            coordinates: GeoCoordinates.validated(
              latitude: -26.92,
              longitude: -49.07,
            ),
            sequence: 1,
            status: VisitRouteStopStatus.completed,
            distanceFromPreviousKm: 1.2,
            etaMinutesFromPrevious: 3,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // 1. "The app is running": save the route.
      final firstDatabase = AppDatabase(NativeDatabase(dbFile));
      final firstRepository = DriftVisitRouteRepository(firstDatabase, mapper);
      final saveResult = await firstRepository.save(route);
      expect(saveResult, isA<AppSuccess<VisitRoute>>());
      await firstDatabase.close();

      // 2. "The app is closed and reopened": a brand-new AppDatabase
      // instance against the same file, with no in-memory state carried
      // over.
      final secondDatabase = AppDatabase(NativeDatabase(dbFile));
      final secondRepository = DriftVisitRouteRepository(
        secondDatabase,
        mapper,
      );
      final result = await secondRepository.getForDate(
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: VisitRoute.dateKey(now),
      );
      await secondDatabase.close();

      expect(result, isA<AppSuccess<VisitRoute?>>());
      final resumed = (result as AppSuccess<VisitRoute?>).value;
      expect(resumed, isNotNull);
      expect(resumed, route);
    });

    test('rebuilding the route for the same day upserts the same row instead '
        'of accumulating a second one', () async {
      const mapper = VisitRouteLocalMapper();
      final database = AppDatabase(NativeDatabase(dbFile));
      addTearDown(() => database.close());
      final repository = DriftVisitRouteRepository(database, mapper);
      final now = DateTime.utc(2026, 9, 7);

      VisitRoute buildRoute(List<VisitRouteStop> stops) {
        return VisitRoute(
          id: 'org-1_rep-1_2026-09-07',
          organizationId: 'org-1',
          companyId: 'company-1',
          salesRepId: 'rep-1',
          date: VisitRoute.dateKey(now),
          stops: stops,
          createdAt: now,
          updatedAt: now,
        );
      }

      await repository.save(
        buildRoute(<VisitRouteStop>[
          VisitRouteStop(
            customerId: 'customer-1',
            displayName: 'Cliente 1',
            coordinates: GeoCoordinates.validated(latitude: 1, longitude: 1),
            sequence: 0,
          ),
        ]),
      );
      await repository.save(
        buildRoute(<VisitRouteStop>[
          VisitRouteStop(
            customerId: 'customer-1',
            displayName: 'Cliente 1',
            coordinates: GeoCoordinates.validated(latitude: 1, longitude: 1),
            sequence: 0,
          ),
          VisitRouteStop(
            customerId: 'customer-2',
            displayName: 'Cliente 2',
            coordinates: GeoCoordinates.validated(latitude: 2, longitude: 2),
            sequence: 1,
          ),
        ]),
      );

      final rows = await database.select(database.visitRoutesTable).get();
      expect(rows, hasLength(1));

      final result = await repository.getForDate(
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: VisitRoute.dateKey(now),
      );
      final resumed = (result as AppSuccess<VisitRoute?>).value;
      expect(resumed!.stops, hasLength(2));
    });
  });
}
