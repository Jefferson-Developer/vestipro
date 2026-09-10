import type { Firestore } from 'firebase-admin/firestore';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  type AdminPortalOperatorSession,
  recordAdminPortalOperatorAudit,
  requireAdminPortalReason,
  requireVestiProOperator,
  sanitizeAdminPortalAuditMetadata,
  scrubAdminPortalLogMessage,
} from '../../src/admin/admin-portal';

type AdminPortalData = {
  _meta?: { correlationId?: string };
  reason?: string;
};

function buildRequest(
  data: AdminPortalData,
  auth?: CallableRequest<AdminPortalData>['auth'],
): CallableRequest<AdminPortalData> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<AdminPortalData>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<AdminPortalData>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<AdminPortalData>['auth'];
}

describe('admin portal callable guards', () => {
  it('denies regular organization users before any data access', () => {
    expect(() =>
      requireVestiProOperator(
        buildRequest({}, authFor('user-1', { email: 'user@test.com' })),
      ),
    ).toThrow('Apenas operadores VestiPro podem acessar este portal.');
  });

  it('requires the requested internal permission', () => {
    expect(() =>
      requireVestiProOperator(
        buildRequest(
          {},
          authFor('operator-1', {
            vestiproOperator: true,
            vestiproOperatorPermissions: ['adminPortal.view'],
          }),
        ),
        'adminPortal.viewSensitiveData',
      ),
    ).toThrow('Operador VestiPro sem permissao para esta acao.');
  });

  it('normalizes support reasons before sensitive access', () => {
    expect(() => requireAdminPortalReason('curto')).toThrow(
      'Informe uma justificativa de suporte',
    );
    expect(requireAdminPortalReason(' SUP-203 investigacao ')).toBe(
      'SUP-203 investigacao',
    );
  });

  it('sanitizes log messages and audit metadata', () => {
    expect(
      scrubAdminPortalLogMessage(
        'Falha para comprador@acme.test cpf 123.456.789-10 cnpj 12.345.678/0001-99',
      ),
    ).toBe('Falha para [email] cpf [cpf] cnpj [cnpj]');

    expect(
      sanitizeAdminPortalAuditMetadata({
        query: 'acme',
        token: 'secret-token',
        cpf: '123',
      }),
    ).toEqual({ query: 'acme' });
  });

  it('records audited operator access with reason and no sensitive metadata', async () => {
    const fakeFirestore = new FakeFirestore();
    const operator: AdminPortalOperatorSession = {
      uid: 'operator-1',
      displayName: 'Operador',
      permissions: ['adminPortal.view', 'adminPortal.viewSensitiveData'],
    };

    const auditLogId = await recordAdminPortalOperatorAudit({
      db: fakeFirestore as unknown as Firestore,
      organizationId: 'org-1',
      operator,
      action: 'vestiproAdmin.diagnosticViewed',
      entityType: 'syncDevice',
      entityId: 'device-1',
      reason: 'SUP-203 investigacao',
      ticketId: 'SUP-203',
      metadata: { targetUserId: 'user-1', token: 'must-not-persist' },
    });

    expect(auditLogId).toBe('audit-1');
    expect(fakeFirestore.lastPath).toEqual([
      'organizations',
      'org-1',
      'auditLogs',
      'audit-1',
    ]);
    expect(fakeFirestore.lastPayload).toMatchObject({
      organizationId: 'org-1',
      actorUserId: 'operator-1',
      action: 'vestiproAdmin.diagnosticViewed',
      entityType: 'syncDevice',
      entityId: 'device-1',
      newValue: {
        reason: 'SUP-203 investigacao',
        ticketId: 'SUP-203',
        targetUserId: 'user-1',
      },
    });
    expect(fakeFirestore.lastPayload?.newValue).not.toHaveProperty('token');
  });
});

class FakeFirestore {
  lastPath: string[] = [];
  lastPayload?: { newValue?: Record<string, unknown> } & Record<
    string,
    unknown
  >;

  collection(path: string): FakeCollectionReference {
    return new FakeCollectionReference(this, [path]);
  }
}

class FakeCollectionReference {
  constructor(
    private readonly db: FakeFirestore,
    private readonly path: string[],
  ) {}

  doc(id = 'audit-1'): FakeDocumentReference {
    return new FakeDocumentReference(this.db, [...this.path, id], id);
  }
}

class FakeDocumentReference {
  constructor(
    private readonly db: FakeFirestore,
    private readonly path: string[],
    readonly id: string,
  ) {}

  collection(path: string): FakeCollectionReference {
    return new FakeCollectionReference(this.db, [...this.path, path]);
  }

  async set(payload: Record<string, unknown>): Promise<void> {
    this.db.lastPath = this.path;
    this.db.lastPayload = payload;
  }
}
