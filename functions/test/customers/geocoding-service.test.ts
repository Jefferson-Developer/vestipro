import {
  buildGeocodableAddressQuery,
  geocodeAddress,
  type GeocodableAddress,
  type GeocodingProviderResponse,
} from '../../src/customers/geocoding-service';

const validAddress: GeocodableAddress = {
  street: 'Rua das Flores',
  number: '123',
  district: 'Centro',
  city: 'Blumenau',
  state: 'SC',
  zipCode: '89010-000',
  country: 'BR',
};

const okResponse = (lat: number, lng: number): GeocodingProviderResponse => ({
  status: 'OK',
  results: [{ geometry: { location: { lat, lng } } }],
});

describe('buildGeocodableAddressQuery', () => {
  it('joins every non-empty field into a single free-text query', () => {
    expect(buildGeocodableAddressQuery(validAddress)).toBe(
      'Rua das Flores, 123, Centro, Blumenau, SC, 89010-000, BR',
    );
  });

  it('falls back to "Brasil" when country is missing', () => {
    expect(
      buildGeocodableAddressQuery({ ...validAddress, country: undefined }),
    ).toContain('Brasil');
  });

  it('returns null for an incomplete address (missing street)', () => {
    expect(
      buildGeocodableAddressQuery({ ...validAddress, street: '   ' }),
    ).toBeNull();
  });

  it('returns null for an incomplete address (missing city)', () => {
    expect(buildGeocodableAddressQuery({ ...validAddress, city: '' })).toBeNull();
  });

  it('returns null for an incomplete address (missing state)', () => {
    expect(buildGeocodableAddressQuery({ ...validAddress, state: '' })).toBeNull();
  });
});

describe('geocodeAddress', () => {
  it('resolves coordinates for a valid, geocodable address', async () => {
    const result = await geocodeAddress(validAddress, async () =>
      okResponse(-26.9194, -49.0661),
    );

    expect(result).toEqual({
      status: 'geocoded',
      coordinates: { latitude: -26.9194, longitude: -49.0661 },
    });
  });

  it('never calls the fetcher for an incomplete/invalid address', async () => {
    const fetcher = jest.fn(async () => okResponse(0, 0));

    const result = await geocodeAddress({ ...validAddress, city: '' }, fetcher);

    expect(result).toEqual({ status: 'unavailable' });
    expect(fetcher).not.toHaveBeenCalled();
  });

  it('resolves to unavailable when the provider returns ZERO_RESULTS', async () => {
    const result = await geocodeAddress(validAddress, async () => ({
      status: 'ZERO_RESULTS',
      results: [],
    }));

    expect(result).toEqual({ status: 'unavailable' });
  });

  it('resolves to unavailable when the provider response is malformed', async () => {
    const result = await geocodeAddress(validAddress, async () => ({
      status: 'OK',
      results: [{ geometry: { location: { lat: 'not-a-number', lng: -49 } } }],
    }));

    expect(result).toEqual({ status: 'unavailable' });
  });

  it('resolves to unavailable when the fetcher times out', async () => {
    const result = await geocodeAddress(
      validAddress,
      () => new Promise((resolve) => setTimeout(() => resolve(okResponse(0, 0)), 50)),
      { timeoutMs: 5 },
    );

    expect(result).toEqual({ status: 'unavailable' });
  });

  it('resolves to unavailable when the fetcher throws', async () => {
    const result = await geocodeAddress(validAddress, async () => {
      throw new Error('network error');
    });

    expect(result).toEqual({ status: 'unavailable' });
  });
});
