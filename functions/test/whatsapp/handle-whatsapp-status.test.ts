import { extractWhatsAppStatusEvents } from '../../src/whatsapp/handle-whatsapp-status';
import { resolveDeliveryStatus } from '../../src/whatsapp/whatsapp-shared';

describe('WhatsApp status webhook', () => {
  it('extracts the message id and delivery status from Meta envelopes', () => {
    const events = extractWhatsAppStatusEvents({
      entry: [{
        changes: [{
          value: { statuses: [{ id: 'wamid.1', status: 'delivered' }] },
        }],
      }],
    });
    expect(events).toEqual([{ id: 'wamid.1', status: 'delivered' }]);
  });

  it('keeps each history message independent and ignores out-of-order regression', () => {
    const history: Record<string, 'sent' | 'delivered' | 'read' | 'failed'> = {
      'wamid.1': 'read',
      'wamid.2': 'sent',
    };
    history['wamid.1'] = resolveDeliveryStatus(history['wamid.1'], 'delivered');
    expect(history).toEqual({ 'wamid.1': 'read', 'wamid.2': 'sent' });
  });
});
