import 'dart:math' as math;

import '../entities/customer_map_pin.dart';

/// Groups nearby [CustomerMapPin]s into [MapCluster]s so a dense region does
/// not render one marker per customer at a low zoom level (TASK-176).
///
/// The grid cell size shrinks as [zoom] increases (same "tile size in
/// degrees" approximation every slippy-map tile scheme uses: the world
/// spans 360 degrees of longitude split across `2^zoom` tiles), so pins
/// naturally separate back into individual markers as the sales rep zooms
/// in, without ever needing the map widget's screen-pixel projection — this
/// keeps the whole algorithm pure and unit-testable outside Flutter/Google
/// Maps.
final class CustomerMapClusterer {
  const CustomerMapClusterer();

  static const double minZoom = 0;
  static const double maxZoom = 20;

  List<MapCluster> cluster({
    required List<CustomerMapPin> pins,
    required double zoom,
  }) {
    if (pins.isEmpty) return const <MapCluster>[];

    final cellSizeDegrees = _cellSizeDegreesForZoom(zoom);
    final buckets = <String, List<CustomerMapPin>>{};
    for (final pin in pins) {
      final cellX = (pin.coordinates.longitude / cellSizeDegrees).floor();
      final cellY = (pin.coordinates.latitude / cellSizeDegrees).floor();
      (buckets['$cellX:$cellY'] ??= <CustomerMapPin>[]).add(pin);
    }

    return <MapCluster>[
      for (final bucketPins in buckets.values)
        MapCluster(
          latitude: _average(bucketPins.map((pin) => pin.coordinates.latitude)),
          longitude: _average(
            bucketPins.map((pin) => pin.coordinates.longitude),
          ),
          pins: List.unmodifiable(bucketPins),
        ),
    ];
  }

  double _cellSizeDegreesForZoom(double zoom) {
    final clampedZoom = zoom.clamp(minZoom, maxZoom);
    return 360 / math.pow(2, clampedZoom + 1);
  }

  double _average(Iterable<double> values) {
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      sum += value;
      count += 1;
    }
    return count == 0 ? 0 : sum / count;
  }
}
