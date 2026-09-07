import { validateWhatsAppSendContext } from '../../src/whatsapp/whatsapp-shared';

describe('sendWhatsAppMessage server-side policy', () => {
  it('accepts only an approved template for an opted-in customer', () => {
    expect(() => validateWhatsAppSendContext('accepted', 'approved', 1, ['Ana'])).not.toThrow();
  });

  it.each([undefined, 'revoked'])('blocks sending when opt-in is %s', (status) => {
    expect(() => validateWhatsAppSendContext(status, 'approved', 1, ['Ana'])).toThrow(
      expect.objectContaining({ code: 'failed-precondition' }),
    );
  });

  it('rejects a template that is not approved', () => {
    expect(() => validateWhatsAppSendContext('accepted', 'paused', 1, ['Ana'])).toThrow(
      expect.objectContaining({ code: 'failed-precondition' }),
    );
  });

  it('rejects missing template variables', () => {
    expect(() => validateWhatsAppSendContext('accepted', 'approved', 2, ['Ana'])).toThrow(
      expect.objectContaining({ code: 'invalid-argument' }),
    );
  });
});
