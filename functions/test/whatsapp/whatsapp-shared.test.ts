import { createHmac } from 'node:crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  assertOptInTransition,
  resolveDeliveryStatus,
  sendMetaTemplateMessage,
  verifyWebhookSignature,
} from '../../src/whatsapp/whatsapp-shared';

describe('WhatsApp opt-in transitions', () => {
  it('supports request, acceptance and immediate revocation', () => {
    expect(() => assertOptInTransition(null, 'requested')).not.toThrow();
    expect(() => assertOptInTransition('requested', 'accepted')).not.toThrow();
    expect(() => assertOptInTransition('accepted', 'revoked')).not.toThrow();
    expect(() => assertOptInTransition('revoked', 'accepted')).toThrow(HttpsError);
  });

  it('allows a new request after refusal or revocation', () => {
    expect(() => assertOptInTransition('refused', 'requested')).not.toThrow();
    expect(() => assertOptInTransition('revoked', 'requested')).not.toThrow();
  });
});

describe('WhatsApp webhook signature', () => {
  it('accepts only the HMAC-SHA256 generated with the app secret', () => {
    const body = Buffer.from('{"entry":[]}');
    const signature = createHmac('sha256', 'app-secret').update(body).digest('hex');
    expect(verifyWebhookSignature(body, `sha256=${signature}`, 'app-secret')).toBe(true);
    expect(verifyWebhookSignature(body, `sha256=${signature}`, 'wrong-secret')).toBe(false);
  });
});

describe('WhatsApp delivery ordering', () => {
  it('does not regress read messages when an older delivered event arrives', () => {
    expect(resolveDeliveryStatus('read', 'delivered')).toBe('read');
    expect(resolveDeliveryStatus('sent', 'read')).toBe('read');
  });
});

describe('Meta Cloud API adapter', () => {
  const request = {
    phoneNumberId: 'phone-id',
    accessToken: 'secret',
    to: '5511999999999',
    templateName: 'catalogo',
    language: 'pt_BR',
    variables: ['Ana', 'https://catalogo'],
  };

  it('returns the Meta message id on success without exposing the token in the body', async () => {
    const fetcher = jest.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      expect(init?.headers).toMatchObject({ authorization: 'Bearer secret' });
      expect(init?.body).not.toContain('secret');
      return new Response(JSON.stringify({ messages: [{ id: 'wamid.1' }] }), { status: 200 });
    }) as typeof fetch;
    await expect(sendMetaTemplateMessage(request, fetcher)).resolves.toBe('wamid.1');
  });

  it.each([
    [401, 'failed-precondition'],
    [429, 'resource-exhausted'],
  ])('maps HTTP %s to a comprehensible callable error', async (status, code) => {
    const fetcher = jest.fn(async () => new Response(JSON.stringify({ error: { message: 'Meta failure' } }), { status })) as typeof fetch;
    await expect(sendMetaTemplateMessage(request, fetcher)).rejects.toMatchObject({ code });
  });
});
