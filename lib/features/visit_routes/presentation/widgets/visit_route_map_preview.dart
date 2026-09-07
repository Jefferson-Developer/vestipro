import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/visit_route_stop.dart';

/// Read-only map visualization of an already-built [VisitRoute]'s stops
/// (TASK-177): one numbered marker per stop, connected by a polyline in
/// visit order. Deliberately its own small widget rather than reusing
/// `CustomerPortfolioMapView`/`CustomerMapClusterer` (TASK-176): those exist
/// to cluster an unordered carteira, this shows a small, already-ordered
/// sequence — clustering stops here would hide the very order this screen
/// exists to communicate.
class VisitRouteMapPreview extends StatelessWidget {
  const VisitRouteMapPreview({required this.stops, super.key});

  final List<VisitRouteStop> stops;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final points = stops
        .map(
          (stop) =>
              LatLng(stop.coordinates.latitude, stop.coordinates.longitude),
        )
        .toList(growable: false);
    final markers = <Marker>{
      for (final stop in stops)
        Marker(
          markerId: MarkerId(stop.customerId),
          position: LatLng(
            stop.coordinates.latitude,
            stop.coordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: '${stop.sequence + 1}. ${stop.displayName}',
          ),
        ),
    };
    final polylines = <Polyline>{
      if (points.length > 1)
        Polyline(
          polylineId: const PolylineId('visit-route'),
          points: points,
          width: 4,
          color: context.colors.primary,
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.radius8),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: points.first, zoom: 12),
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: false,
      ),
    );
  }
}
