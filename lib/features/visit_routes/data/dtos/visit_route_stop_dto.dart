/// JSON shape of a single [VisitRouteStop] persisted inside
/// `VisitRoutesTable.stopsJson` (TASK-177).
final class VisitRouteStopDto {
  const VisitRouteStopDto({
    required this.customerId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.sequence,
    required this.statusCode,
    this.distanceFromPreviousKm,
    this.etaMinutesFromPrevious,
  });

  factory VisitRouteStopDto.fromJson(Map<String, dynamic> json) {
    return VisitRouteStopDto(
      customerId: json['customerId'] as String,
      displayName: json['displayName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sequence: json['sequence'] as int,
      statusCode: json['status'] as String? ?? 'pending',
      distanceFromPreviousKm: (json['distanceFromPreviousKm'] as num?)
          ?.toDouble(),
      etaMinutesFromPrevious: json['etaMinutesFromPrevious'] as int?,
    );
  }

  final String customerId;
  final String displayName;
  final double latitude;
  final double longitude;
  final int sequence;
  final String statusCode;
  final double? distanceFromPreviousKm;
  final int? etaMinutesFromPrevious;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customerId': customerId,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
      'status': statusCode,
      'distanceFromPreviousKm': distanceFromPreviousKm,
      'etaMinutesFromPrevious': etaMinutesFromPrevious,
    };
  }
}
