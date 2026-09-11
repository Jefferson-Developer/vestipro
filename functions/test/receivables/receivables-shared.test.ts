import { Timestamp } from 'firebase-admin/firestore';

import {
  classifyReceivableReminder,
  computeAgingBucket,
  computeBillingStatus,
  computeExternalEntityId,
  computeInvoiceStatus,
  computeOutstandingAmount,
  computeReceivableStatus,
  describeBillingStatus,
  type Receivable,
} from '../../src/receivables/receivables-shared';

const NOW = Timestamp.fromDate(new Date('2026-06-15T12:00:00.000Z'));

function daysFromNow(days: number): Timestamp {
  return Timestamp.fromMillis(NOW.toMillis() + days * 24 * 60 * 60 * 1000);
}

describe('computeReceivableStatus', () => {
  it('is open when not due yet and nothing paid', () => {
    const status = computeReceivableStatus({
      amount: 100,
      paidAmount: 0,
      dueDate: daysFromNow(5),
      cancelled: false,
      now: NOW,
    });
    expect(status).toBe('open');
  });

  it('is overdue when past due and nothing paid', () => {
    const status = computeReceivableStatus({
      amount: 100,
      paidAmount: 0,
      dueDate: daysFromNow(-1),
      cancelled: false,
      now: NOW,
    });
    expect(status).toBe('overdue');
  });

  it('is partially_paid even when also past due', () => {
    const status = computeReceivableStatus({
      amount: 100,
      paidAmount: 40,
      dueDate: daysFromNow(-10),
      cancelled: false,
      now: NOW,
    });
    expect(status).toBe('partially_paid');
  });

  it('is paid once paidAmount reaches amount', () => {
    const status = computeReceivableStatus({
      amount: 100,
      paidAmount: 100,
      dueDate: daysFromNow(-10),
      cancelled: false,
      now: NOW,
    });
    expect(status).toBe('paid');
  });

  it('is cancelled regardless of paidAmount/dueDate', () => {
    const status = computeReceivableStatus({
      amount: 100,
      paidAmount: 100,
      dueDate: daysFromNow(-10),
      cancelled: true,
      now: NOW,
    });
    expect(status).toBe('cancelled');
  });
});

describe('computeOutstandingAmount', () => {
  it('is the difference between amount and paidAmount', () => {
    expect(computeOutstandingAmount({ amount: 100, paidAmount: 40 })).toBe(60);
  });

  it('never goes negative on an overpayment', () => {
    expect(computeOutstandingAmount({ amount: 100, paidAmount: 150 })).toBe(0);
  });
});

describe('computeAgingBucket', () => {
  it('is current for a paid/cancelled receivable regardless of due date', () => {
    expect(computeAgingBucket({ dueDate: daysFromNow(-200), status: 'paid' }, NOW)).toBe('current');
    expect(computeAgingBucket({ dueDate: daysFromNow(-200), status: 'cancelled' }, NOW)).toBe('current');
  });

  it('buckets days past due into the correct range', () => {
    expect(computeAgingBucket({ dueDate: daysFromNow(-5), status: 'overdue' }, NOW)).toBe('d1_30');
    expect(computeAgingBucket({ dueDate: daysFromNow(-45), status: 'overdue' }, NOW)).toBe('d31_60');
    expect(computeAgingBucket({ dueDate: daysFromNow(-75), status: 'overdue' }, NOW)).toBe('d61_90');
    expect(computeAgingBucket({ dueDate: daysFromNow(-120), status: 'overdue' }, NOW)).toBe('d90_plus');
  });

  it('is current for a not-yet-due open receivable', () => {
    expect(computeAgingBucket({ dueDate: daysFromNow(5), status: 'open' }, NOW)).toBe('current');
  });
});

describe('computeInvoiceStatus', () => {
  it('defaults to open with no receivables', () => {
    expect(computeInvoiceStatus([])).toBe('open');
  });

  it('is cancelled only when every installment is cancelled', () => {
    expect(computeInvoiceStatus(['cancelled', 'cancelled'])).toBe('cancelled');
  });

  it('ignores cancelled installments when aggregating the rest', () => {
    expect(computeInvoiceStatus(['cancelled', 'paid'])).toBe('paid');
  });

  it('is paid only once every non-cancelled installment is paid', () => {
    expect(computeInvoiceStatus(['paid', 'paid'])).toBe('paid');
    expect(computeInvoiceStatus(['paid', 'open'])).toBe('open');
  });

  it('is overdue when any installment is overdue, ranked above partially_paid', () => {
    expect(computeInvoiceStatus(['partially_paid', 'overdue'])).toBe('overdue');
  });

  it('is partially_paid when any installment is, and none overdue', () => {
    expect(computeInvoiceStatus(['open', 'partially_paid'])).toBe('partially_paid');
  });
});

describe('classifyReceivableReminder', () => {
  function receivable(overrides: Partial<Receivable>): Receivable {
    return {
      id: 'r1',
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      invoiceId: 'invoice-1',
      orderId: 'order-1',
      sellerId: 'seller-1',
      externalId: null,
      installmentNumber: 1,
      dueDate: daysFromNow(0),
      amount: 100,
      paidAmount: 0,
      currency: 'BRL',
      status: 'open',
      cancelledReason: null,
      version: 1,
      ...overrides,
    };
  }

  it('never reminds a paid or cancelled receivable', () => {
    expect(classifyReceivableReminder(receivable({ status: 'paid' }), NOW)).toBe('none');
    expect(classifyReceivableReminder(receivable({ status: 'cancelled' }), NOW)).toBe('none');
  });

  it('classifies an overdue receivable as overdue', () => {
    expect(
      classifyReceivableReminder(receivable({ status: 'overdue', dueDate: daysFromNow(-2) }), NOW),
    ).toBe('overdue');
  });

  it('classifies a receivable due within the window as dueSoon', () => {
    expect(
      classifyReceivableReminder(receivable({ status: 'open', dueDate: daysFromNow(2) }), NOW),
    ).toBe('dueSoon');
  });

  it('does not remind a receivable due far in the future', () => {
    expect(
      classifyReceivableReminder(receivable({ status: 'open', dueDate: daysFromNow(30) }), NOW),
    ).toBe('none');
  });
});

describe('computeBillingStatus / describeBillingStatus', () => {
  it('is up_to_date with no open/overdue receivables', () => {
    expect(computeBillingStatus(['paid', 'paid'])).toBe('up_to_date');
    expect(describeBillingStatus('up_to_date')).not.toContain('R$');
  });

  it('is has_open when something is open/partially_paid but nothing overdue', () => {
    expect(computeBillingStatus(['paid', 'open'])).toBe('has_open');
    expect(computeBillingStatus(['partially_paid'])).toBe('has_open');
  });

  it('is has_overdue whenever anything is overdue, even alongside open ones', () => {
    expect(computeBillingStatus(['open', 'overdue'])).toBe('has_overdue');
  });

  it('never mentions a monetary figure in any masked message', () => {
    for (const status of ['up_to_date', 'has_open', 'has_overdue'] as const) {
      expect(describeBillingStatus(status)).not.toMatch(/\d/);
    }
  });
});

describe('computeExternalEntityId', () => {
  it('is deterministic for the same inputs (idempotent import)', () => {
    const first = computeExternalEntityId('org-1', 'invoice', 'ERP-000123');
    const second = computeExternalEntityId('org-1', 'invoice', 'ERP-000123');
    expect(first).toBe(second);
  });

  it('never collides an invoice and a receivable sharing the same raw externalId', () => {
    const invoiceId = computeExternalEntityId('org-1', 'invoice', 'X-1');
    const receivableId = computeExternalEntityId('org-1', 'receivable', 'X-1');
    expect(invoiceId).not.toBe(receivableId);
  });

  it('never collides the same externalId across two different organizations', () => {
    const first = computeExternalEntityId('org-1', 'invoice', 'X-1');
    const second = computeExternalEntityId('org-2', 'invoice', 'X-1');
    expect(first).not.toBe(second);
  });
});
