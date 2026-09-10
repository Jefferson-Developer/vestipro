import { resolveNpsSurveyTrigger } from '../../src/nps/trigger-nps-survey';

describe('resolveNpsSurveyTrigger', () => {
  const validEventData = {
    type: 'delivered',
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    orderNumber: 'PED-001',
    customerId: 'customer-1',
    sellerId: 'seller-1',
  };

  it('resolves a trigger for a "delivered" milestone', () => {
    expect(resolveNpsSurveyTrigger(validEventData)).toEqual({
      organizationId: 'org-1',
      companyId: 'company-1',
      orderId: 'order-1',
      orderNumber: 'PED-001',
      customerId: 'customer-1',
      sellerId: 'seller-1',
      milestoneType: 'delivered',
    });
  });

  it('resolves a trigger for a "resolved" milestone', () => {
    expect(
      resolveNpsSurveyTrigger({ ...validEventData, type: 'resolved' })?.milestoneType,
    ).toBe('resolved');
  });

  it('tolerates a missing orderNumber (null, never throws)', () => {
    const withoutOrderNumber: Record<string, unknown> = { ...validEventData };
    delete withoutOrderNumber.orderNumber;
    expect(resolveNpsSurveyTrigger(withoutOrderNumber)?.orderNumber).toBeNull();
  });

  it.each([
    'dispatched',
    'in_transit',
    'problem_reported',
    'in_resolution',
    'return_requested',
    'return_resolved',
    'exchange_requested',
    'exchange_resolved',
  ])('never triggers for the "%s" milestone', (type) => {
    expect(resolveNpsSurveyTrigger({ ...validEventData, type })).toBeNull();
  });

  it('returns null for an undefined document', () => {
    expect(resolveNpsSurveyTrigger(undefined)).toBeNull();
  });

  it.each([
    'organizationId',
    'companyId',
    'orderId',
    'customerId',
    'sellerId',
  ])('returns null when "%s" is missing', (field) => {
    const malformed = { ...validEventData } as Record<string, unknown>;
    delete malformed[field];
    expect(resolveNpsSurveyTrigger(malformed)).toBeNull();
  });
});
