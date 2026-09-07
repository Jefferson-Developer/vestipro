/// Geocoding lifecycle of a single [CustomerAddress] (TASK-176).
///
/// - [pending]: never geocoded yet (new address, or one created before this
///   feature existed) — eligible for the backfill job.
/// - [geocoded]: [CustomerAddress.coordinates] holds a usable pin location.
/// - [unavailable]: geocoding was attempted but the address could not be
///   resolved (incomplete/invalid address, provider timeout after retries).
///   The customer keeps appearing in every list/report — it just has no pin
///   on the map (`tasks.md`/TASK-176: "não trava a tela nem gera erro
///   visível").
enum CustomerGeocodingStatus { pending, geocoded, unavailable }

extension CustomerGeocodingStatusCode on CustomerGeocodingStatus {
  String get code {
    return switch (this) {
      CustomerGeocodingStatus.pending => 'pending',
      CustomerGeocodingStatus.geocoded => 'geocoded',
      CustomerGeocodingStatus.unavailable => 'unavailable',
    };
  }
}

CustomerGeocodingStatus customerGeocodingStatusFromCode(String? code) {
  return switch (code) {
    'geocoded' => CustomerGeocodingStatus.geocoded,
    'unavailable' => CustomerGeocodingStatus.unavailable,
    _ => CustomerGeocodingStatus.pending,
  };
}
