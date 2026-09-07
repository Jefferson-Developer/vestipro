import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type Firestore,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import {
  geocodeAddress,
  type GeocodableAddress,
  type GeocodeFetcher,
  type GeocodingProviderResponse,
} from './geocoding-service';

/**
 * TASK-176 (mapa de clientes): backfill job that geocodes every customer
 * address still `pending`, both newly created/edited customers (their
 * address DTO already defaults `geocodingStatus` to `pending` — see
 * `CustomerAddressDto`) and customers registered before this feature
 * existed. Deliberately server-side and asynchronous (never on the
 * client's create/update path) so creating/editing a customer offline never
 * depends on this network call — same "offline-first must not depend on a
 * server round-trip" precedent as `recalculateCustomerScores`.
 */
export const googleMapsGeocodingApiKey = defineSecret(
  'GOOGLE_MAPS_GEOCODING_API_KEY',
);

export const GEOCODE_BACKFILL_SCHEDULE_DESCRIPTION =
  'Daily at 04:00 America/Sao_Paulo';

const BATCH_COMMIT_THRESHOLD = 450;

export interface CustomerGeocodingBackfillSummary {
  organizationsProcessed: number;
  addressesGeocoded: number;
  addressesUnavailable: number;
}

export const geocodeCustomerAddresses = onSchedule(
  {
    schedule: '0 4 * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
    secrets: [googleMapsGeocodingApiKey],
  },
  async () => {
    const summary = await geocodeCustomerAddressesForAllOrganizations(
      getFirestore(),
      buildGoogleGeocodeFetcher(googleMapsGeocodingApiKey.value()),
    );
    logger.info('Customer address geocoding backfill finished', summary);
  },
);

/** Builds the real HTTP call to the Google Geocoding API (Node 20 global `fetch`). */
export function buildGoogleGeocodeFetcher(apiKey: string): GeocodeFetcher {
  return async (addressQuery: string): Promise<GeocodingProviderResponse> => {
    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    url.searchParams.set('address', addressQuery);
    url.searchParams.set('key', apiKey);
    const response = await fetch(url.toString());
    if (!response.ok) {
      throw new Error(`Geocoding HTTP error ${response.status}`);
    }
    return (await response.json()) as GeocodingProviderResponse;
  };
}

export async function geocodeCustomerAddressesForAllOrganizations(
  db: Firestore,
  fetcher: GeocodeFetcher,
): Promise<CustomerGeocodingBackfillSummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  let organizationsProcessed = 0;
  let addressesGeocoded = 0;
  let addressesUnavailable = 0;

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') {
      continue;
    }
    const summary = await geocodeCustomerAddressesForOrganization(
      db,
      organizationDoc.id,
      fetcher,
    );
    organizationsProcessed += 1;
    addressesGeocoded += summary.addressesGeocoded;
    addressesUnavailable += summary.addressesUnavailable;
  }

  return { organizationsProcessed, addressesGeocoded, addressesUnavailable };
}

export async function geocodeCustomerAddressesForOrganization(
  db: Firestore,
  organizationId: string,
  fetcher: GeocodeFetcher,
): Promise<Omit<CustomerGeocodingBackfillSummary, 'organizationsProcessed'>> {
  const customersSnapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .get();

  let batch = db.batch();
  let pendingWrites = 0;
  let addressesGeocoded = 0;
  let addressesUnavailable = 0;

  const commitIfNeeded = async (force = false): Promise<void> => {
    if (pendingWrites === 0 || (!force && pendingWrites < BATCH_COMMIT_THRESHOLD)) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    pendingWrites = 0;
  };

  for (const customerDoc of customersSnapshot.docs) {
    if (customerDoc.data().organizationId !== organizationId) {
      // Defense in depth: never trust a doc found outside its own tenant
      // subcollection path, mirroring `recalculate-customer-scores.ts`.
      continue;
    }
    const result = await geocodePendingAddressesForCustomer(customerDoc, fetcher);
    if (result == null) continue;

    batch.update(customerDoc.ref, { addresses: result.addresses });
    pendingWrites += 1;
    addressesGeocoded += result.geocoded;
    addressesUnavailable += result.unavailable;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return { addressesGeocoded, addressesUnavailable };
}

async function geocodePendingAddressesForCustomer(
  customerDoc: QueryDocumentSnapshot<DocumentData>,
  fetcher: GeocodeFetcher,
): Promise<{ addresses: unknown[]; geocoded: number; unavailable: number } | null> {
  const data = customerDoc.data();
  if (data.deletedAt != null) return null;

  const addresses = Array.isArray(data.addresses) ? data.addresses : [];
  let geocoded = 0;
  let unavailable = 0;
  let mutated = false;

  const updatedAddresses = await Promise.all(
    addresses.map(async (address: Record<string, unknown>) => {
      const status = address.geocodingStatus;
      if (status !== undefined && status !== 'pending') {
        // Already resolved (either way) — the backfill never re-attempts an
        // address, so a manual re-geocode would need a dedicated action.
        return address;
      }

      const result = await geocodeAddress(toGeocodableAddress(address), fetcher);
      mutated = true;
      if (result.status === 'geocoded' && result.coordinates != null) {
        geocoded += 1;
        return {
          ...address,
          latitude: result.coordinates.latitude,
          longitude: result.coordinates.longitude,
          geocodingStatus: 'geocoded',
          geocodedAt: Timestamp.now(),
        };
      }
      unavailable += 1;
      return { ...address, geocodingStatus: 'unavailable', geocodedAt: Timestamp.now() };
    }),
  );

  if (!mutated) return null;
  return { addresses: updatedAddresses, geocoded, unavailable };
}

function toGeocodableAddress(address: Record<string, unknown>): GeocodableAddress {
  return {
    street: stringOrEmpty(address.street),
    number: stringOrNull(address.number),
    district: stringOrNull(address.district),
    city: stringOrEmpty(address.city),
    state: stringOrEmpty(address.state),
    zipCode: stringOrNull(address.zipCode),
    country: stringOrNull(address.country),
  };
}

function stringOrEmpty(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}
