import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../../domain/entities/visit_route.dart';
import '../../domain/entities/visit_route_stop.dart';
import '../../domain/value_objects/visit_route_stop_status.dart';
import '../dtos/visit_route_stop_dto.dart';

/// Maps [VisitRoute] to/from the Drift row backing local persistence
/// (TASK-177).
@lazySingleton
final class VisitRouteLocalMapper {
  const VisitRouteLocalMapper();

  VisitRoutesTableCompanion toRow(VisitRoute route) {
    return VisitRoutesTableCompanion.insert(
      id: route.id,
      organizationId: route.organizationId,
      companyId: route.companyId,
      salesRepId: route.salesRepId,
      date: route.date.toUtc(),
      stopsJson: jsonEncode(
        route.stops.map(_stopToDto).map((dto) => dto.toJson()).toList(),
      ),
      createdAt: route.createdAt.toUtc(),
      updatedAt: route.updatedAt.toUtc(),
    );
  }

  VisitRoute toEntity(VisitRoutesTableData row) {
    final rawStops = jsonDecode(row.stopsJson) as List<dynamic>;
    final stops = rawStops
        .cast<Map<String, dynamic>>()
        .map(VisitRouteStopDto.fromJson)
        .map(_stopFromDto)
        .toList(growable: false);
    return VisitRoute(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      salesRepId: row.salesRepId,
      date: row.date.toUtc(),
      stops: stops,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  VisitRouteStopDto _stopToDto(VisitRouteStop stop) {
    return VisitRouteStopDto(
      customerId: stop.customerId,
      displayName: stop.displayName,
      latitude: stop.coordinates.latitude,
      longitude: stop.coordinates.longitude,
      sequence: stop.sequence,
      statusCode: stop.status.code,
      distanceFromPreviousKm: stop.distanceFromPreviousKm,
      etaMinutesFromPrevious: stop.etaMinutesFromPrevious,
    );
  }

  VisitRouteStop _stopFromDto(VisitRouteStopDto dto) {
    return VisitRouteStop(
      customerId: dto.customerId,
      displayName: dto.displayName,
      coordinates: GeoCoordinates.validated(
        latitude: dto.latitude,
        longitude: dto.longitude,
      ),
      sequence: dto.sequence,
      status: visitRouteStopStatusFromCode(dto.statusCode),
      distanceFromPreviousKm: dto.distanceFromPreviousKm,
      etaMinutesFromPrevious: dto.etaMinutesFromPrevious,
    );
  }
}
