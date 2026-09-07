import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/cep.dart';
import '../value_objects/customer_address_type.dart';
import '../value_objects/customer_geocoding_status.dart';
import '../value_objects/geo_coordinates.dart';

part 'customer_address.freezed.dart';

@freezed
abstract class CustomerAddress with _$CustomerAddress {
  const CustomerAddress._();

  const factory CustomerAddress({
    required String id,
    required CustomerAddressType type,
    required String street,
    String? number,
    String? complement,
    String? district,
    required String city,
    required String state,
    required Cep zipCode,
    @Default('BR') String country,
    @Default(false) bool isPrimary,
    // TASK-176: geocoded pin location for the customer map, derived from the
    // fields above. Never set directly from a form field — always the
    // output of a geocoding attempt (client best-effort or server backfill).
    GeoCoordinates? coordinates,
    @Default(CustomerGeocodingStatus.pending)
    CustomerGeocodingStatus geocodingStatus,
    DateTime? geocodedAt,
  }) = _CustomerAddress;

  String get summary {
    final numberLabel = number == null || number!.isEmpty ? 's/n' : number!;
    return '$street, $numberLabel - $city/$state';
  }

  bool get hasCoordinates =>
      coordinates != null &&
      geocodingStatus == CustomerGeocodingStatus.geocoded;
}
