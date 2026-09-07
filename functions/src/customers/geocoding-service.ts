/**
 * Pure geocoding logic for TASK-176 (mapa de clientes) — deliberately kept
 * free of Firestore/HTTP wiring so it can be unit tested without an
 * emulator, same precedent as `customer-scoring-service.ts`. The Firestore
 * orchestration and the real HTTP call to the Google Geocoding API live in
 * `geocode-customer-addresses.ts`.
 */

export interface GeocodableAddress {
  street: string;
  number?: string | null;
  district?: string | null;
  city: string;
  state: string;
  zipCode?: string | null;
  country?: string | null;
}

export interface GeocodeCoordinates {
  latitude: number;
  longitude: number;
}

export type GeocodeStatus = 'geocoded' | 'unavailable';

export interface GeocodeResult {
  status: GeocodeStatus;
  coordinates?: GeocodeCoordinates;
}

/** Minimal shape this module reads from a Google Geocoding API response. */
export interface GeocodingProviderResponse {
  status: string;
  results: Array<{
    geometry?: {
      location?: {
        lat?: unknown;
        lng?: unknown;
      };
    };
  }>;
}

/**
 * Performs the actual network call for a single address query string.
 * Injected so `geocodeAddress` (and every caller) stays testable without a
 * real HTTP client or a paid Google Maps API key.
 */
export type GeocodeFetcher = (
  addressQuery: string,
) => Promise<GeocodingProviderResponse>;

export const GEOCODING_TIMEOUT_MS = 5_000;

/**
 * Builds the free-text query the geocoding provider expects, or `null` when
 * the address is too incomplete to even attempt a lookup (`tasks.md`/
 * TASK-176: "tratamento de endereço não geocodificável").
 */
export function buildGeocodableAddressQuery(
  address: GeocodableAddress,
): string | null {
  const street = address.street.trim();
  const city = address.city.trim();
  const state = address.state.trim();
  if (street.length === 0 || city.length === 0 || state.length === 0) {
    return null;
  }

  const number = address.number?.trim();
  const streetLine = number && number.length > 0 ? `${street}, ${number}` : street;
  const parts = [
    streetLine,
    address.district?.trim(),
    city,
    state,
    address.zipCode?.trim(),
    address.country?.trim() || 'Brasil',
  ].filter((part): part is string => Boolean(part && part.length > 0));

  return parts.join(', ');
}

/**
 * Geocodes a single address, never throwing: any failure (incomplete
 * address, provider error status, timeout, malformed response) resolves to
 * `{ status: 'unavailable' }` so a caller can persist that outcome instead
 * of leaving the customer's geocoding stuck in an ambiguous state.
 */
export async function geocodeAddress(
  address: GeocodableAddress,
  fetcher: GeocodeFetcher,
  options: { timeoutMs?: number } = {},
): Promise<GeocodeResult> {
  const query = buildGeocodableAddressQuery(address);
  if (query == null) {
    return { status: 'unavailable' };
  }

  const timeoutMs = options.timeoutMs ?? GEOCODING_TIMEOUT_MS;
  try {
    const response = await withTimeout(fetcher(query), timeoutMs);
    return parseGeocodingResponse(response);
  } catch {
    return { status: 'unavailable' };
  }
}

function parseGeocodingResponse(
  response: GeocodingProviderResponse,
): GeocodeResult {
  if (response.status !== 'OK' || response.results.length === 0) {
    return { status: 'unavailable' };
  }
  const location = response.results[0]?.geometry?.location;
  const lat = location?.lat;
  const lng = location?.lng;
  if (!isFiniteNumber(lat) || !isFiniteNumber(lng)) {
    return { status: 'unavailable' };
  }
  return { status: 'geocoded', coordinates: { latitude: lat, longitude: lng } };
}

function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout>;
  const timeout = new Promise<T>((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error('geocoding_timeout')), timeoutMs);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}
