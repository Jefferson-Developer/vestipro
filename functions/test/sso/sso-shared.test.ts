import { HttpsError } from 'firebase-functions/v2/https';

import {
  SSO_MANAGE_ROLES,
  assertCanManageSso,
  buildProviderId,
  extractEmailDomain,
  isFederatedSignInProvider,
  normalizeEmailDomain,
  validateDefaultRoleName,
  validateEmailDomains,
  validateOidcInput,
  validateSamlInput,
  validateSsoProtocol,
} from '../../src/sso/sso-shared';

describe('assertCanManageSso', () => {
  it('allows only OWNER/ADMIN', () => {
    expect(SSO_MANAGE_ROLES.has('OWNER')).toBe(true);
    expect(SSO_MANAGE_ROLES.has('ADMIN')).toBe(true);
    expect(() => assertCanManageSso('OWNER')).not.toThrow();
    expect(() => assertCanManageSso('ADMIN')).not.toThrow();
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'denies %s',
    (roleName) => {
      expect(() => assertCanManageSso(roleName)).toThrow(HttpsError);
    },
  );
});

describe('validateDefaultRoleName', () => {
  it('accepts a known, non-administrative system role', () => {
    expect(validateDefaultRoleName('SALES_REP')).toBe('SALES_REP');
    expect(validateDefaultRoleName('read_only')).toBe('READ_ONLY');
  });

  it.each(['OWNER', 'ADMIN', 'owner', 'admin'])(
    'rejects an administrative role (%s) — SSO nunca provisiona com papel administrativo por padrão',
    (roleName) => {
      expect(() => validateDefaultRoleName(roleName)).toThrow(HttpsError);
    },
  );

  it('rejects an unknown role name', () => {
    expect(() => validateDefaultRoleName('SUPER_USER')).toThrow(HttpsError);
  });

  it('rejects an empty/missing value', () => {
    expect(() => validateDefaultRoleName(undefined)).toThrow(HttpsError);
    expect(() => validateDefaultRoleName('')).toThrow(HttpsError);
    expect(() => validateDefaultRoleName('   ')).toThrow(HttpsError);
  });
});

describe('validateSsoProtocol', () => {
  it('accepts "saml" and "oidc"', () => {
    expect(validateSsoProtocol('saml')).toBe('saml');
    expect(validateSsoProtocol('oidc')).toBe('oidc');
  });

  it('rejects anything else', () => {
    expect(() => validateSsoProtocol('oauth2')).toThrow(HttpsError);
    expect(() => validateSsoProtocol(undefined)).toThrow(HttpsError);
    expect(() => validateSsoProtocol('')).toThrow(HttpsError);
  });
});

describe('normalizeEmailDomain / validateEmailDomains', () => {
  it('lower-cases and trims a plausible domain', () => {
    expect(normalizeEmailDomain('  Malwee.COM.br  ')).toBe('malwee.com.br');
  });

  it('rejects a domain without a dot, with spaces or containing "@"', () => {
    expect(() => normalizeEmailDomain('malwee')).toThrow(HttpsError);
    expect(() => normalizeEmailDomain('mal wee.com')).toThrow(HttpsError);
    expect(() => normalizeEmailDomain('user@malwee.com')).toThrow(HttpsError);
    expect(() => normalizeEmailDomain('')).toThrow(HttpsError);
  });

  it('validates a non-empty list, deduplicating case-insensitively', () => {
    expect(validateEmailDomains(['Malwee.com.br', 'malwee.com.br', 'grupomalwee.com'])).toEqual([
      'malwee.com.br',
      'grupomalwee.com',
    ]);
  });

  it('rejects an empty or non-array value', () => {
    expect(() => validateEmailDomains([])).toThrow(HttpsError);
    expect(() => validateEmailDomains(undefined)).toThrow(HttpsError);
    expect(() => validateEmailDomains('malwee.com.br')).toThrow(HttpsError);
  });
});

describe('extractEmailDomain', () => {
  it('extracts and lower-cases the domain portion of an e-mail', () => {
    expect(extractEmailDomain('Usuario@Malwee.COM.br')).toBe('malwee.com.br');
  });

  it('returns null for an e-mail without "@" or with nothing after it', () => {
    expect(extractEmailDomain('usuario-sem-arroba')).toBeNull();
    expect(extractEmailDomain('usuario@')).toBeNull();
  });
});

describe('isFederatedSignInProvider', () => {
  it('accepts saml.*/oidc.* provider ids', () => {
    expect(isFederatedSignInProvider('saml.connection-1')).toBe(true);
    expect(isFederatedSignInProvider('oidc.connection-1')).toBe(true);
  });

  it('rejects password/google.com/undefined', () => {
    expect(isFederatedSignInProvider('password')).toBe(false);
    expect(isFederatedSignInProvider('google.com')).toBe(false);
    expect(isFederatedSignInProvider(undefined)).toBe(false);
  });
});

describe('buildProviderId', () => {
  it('prefixes the connection id per Identity Platform\'s own requirement', () => {
    expect(buildProviderId('saml', 'abc123')).toBe('saml.abc123');
    expect(buildProviderId('oidc', 'abc123')).toBe('oidc.abc123');
  });
});

describe('validateSamlInput', () => {
  const validInput = {
    idpEntityId: 'https://idp.malwee.com.br/entity',
    ssoURL: 'https://idp.malwee.com.br/sso',
    rpEntityId: 'https://vestipro.app/entity',
    x509Certificates: ['CERT-DATA'],
  };

  it('accepts a fully populated request', () => {
    expect(validateSamlInput(validInput)).toEqual({ ...validInput, callbackURL: undefined });
  });

  it('accepts an optional callbackURL', () => {
    expect(
      validateSamlInput({ ...validInput, callbackURL: 'https://vestipro.app/callback' }).callbackURL,
    ).toBe('https://vestipro.app/callback');
  });

  it.each(['idpEntityId', 'ssoURL', 'rpEntityId'])('rejects a missing %s', (field) => {
    const rest: Record<string, unknown> = { ...validInput };
    delete rest[field];
    expect(() => validateSamlInput(rest)).toThrow(HttpsError);
  });

  it('rejects a missing/empty x509Certificates', () => {
    expect(() => validateSamlInput({ ...validInput, x509Certificates: [] })).toThrow(HttpsError);
    expect(() =>
      validateSamlInput({ ...validInput, x509Certificates: ['   '] }),
    ).toThrow(HttpsError);
    expect(() =>
      validateSamlInput({ ...validInput, x509Certificates: undefined }),
    ).toThrow(HttpsError);
  });
});

describe('validateOidcInput', () => {
  it('accepts a request with clientId/issuer, clientSecret optional', () => {
    expect(validateOidcInput({ clientId: 'client-1', issuer: 'https://issuer.example.com' })).toEqual(
      { clientId: 'client-1', issuer: 'https://issuer.example.com', clientSecret: undefined },
    );
    expect(
      validateOidcInput({
        clientId: 'client-1',
        issuer: 'https://issuer.example.com',
        clientSecret: 'shh',
      }).clientSecret,
    ).toBe('shh');
  });

  it.each(['clientId', 'issuer'])('rejects a missing %s', (field) => {
    const body: Record<string, unknown> = { clientId: 'client-1', issuer: 'https://issuer.example.com' };
    delete body[field];
    expect(() => validateOidcInput(body)).toThrow(HttpsError);
  });
});
