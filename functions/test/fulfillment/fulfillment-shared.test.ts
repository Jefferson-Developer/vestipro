import {
  applyDeliveredItems,
  buildShipmentPackages,
  computeTrackingEventId,
  isShipmentEligibleOrderStatus,
  requireLogisticsIssueType,
  requireTrackingEventType,
  resolveDeliveryStatus,
  resolveOrderStatusForTrackingEvent,
  shipmentStatusForMilestone,
  sumShippedQuantities,
  totalQuantityByOrderItem,
  type ShipmentPackageInput,
  type ShipmentPackageRecord,
} from '../../src/fulfillment/fulfillment-shared';
import type { ReturnRequestOrder } from '../../src/returns/return-shared';

function buildOrder(overrides: Partial<ReturnRequestOrder> = {}): ReturnRequestOrder {
  return {
    id: 'order-1',
    organizationId: 'org-a',
    companyId: 'company-a',
    customerId: 'customer-a',
    sellerId: 'seller-a',
    orderNumber: '1001',
    currency: 'BRL',
    status: 'invoiced',
    items: [
      { id: 'item-1', productId: 'product-1', variantId: 'variant-1', quantity: 10, unitPrice: 50, warehouseId: null },
      { id: 'item-2', productId: 'product-2', variantId: 'variant-2', quantity: 5, unitPrice: 30, warehouseId: null },
    ],
    ...overrides,
  };
}

describe('isShipmentEligibleOrderStatus', () => {
  it('accepts invoiced and partially_invoiced', () => {
    expect(isShipmentEligibleOrderStatus('invoiced')).toBe(true);
    expect(isShipmentEligibleOrderStatus('partially_invoiced')).toBe(true);
  });

  it('rejects every other order status', () => {
    for (const status of ['draft', 'submitted', 'processing', 'shipped', 'delivered', 'cancelled']) {
      expect(isShipmentEligibleOrderStatus(status)).toBe(false);
    }
  });
});

describe('requireTrackingEventType / requireLogisticsIssueType', () => {
  it('accepts every known code', () => {
    for (const type of [
      'picking_started',
      'packed',
      'shipped',
      'in_transit',
      'out_for_delivery',
      'delivered',
      'partially_delivered',
      'returned_to_carrier',
      'adjustment',
    ]) {
      expect(requireTrackingEventType(type)).toBe(type);
    }
  });

  it('rejects an unknown tracking event type', () => {
    expect(() => requireTrackingEventType('teleported')).toThrow();
  });

  it('accepts every known logistics issue type and rejects garbage', () => {
    for (const type of ['delay', 'damage', 'volume_divergence', 'invalid_address', 'carrier_return', 'other']) {
      expect(requireLogisticsIssueType(type)).toBe(type);
    }
    expect(() => requireLogisticsIssueType('lost_in_space')).toThrow();
  });
});

describe('resolveOrderStatusForTrackingEvent', () => {
  it('advances invoiced/partially_invoiced to shipped on a shipped event', () => {
    expect(resolveOrderStatusForTrackingEvent('invoiced', 'shipped')).toBe('shipped');
    expect(resolveOrderStatusForTrackingEvent('partially_invoiced', 'shipped')).toBe('shipped');
  });

  it('advances shipped to delivered on a delivered event', () => {
    expect(resolveOrderStatusForTrackingEvent('shipped', 'delivered')).toBe('delivered');
  });

  it('never advances the order from an ineligible status', () => {
    expect(resolveOrderStatusForTrackingEvent('processing', 'shipped')).toBeNull();
    expect(resolveOrderStatusForTrackingEvent('draft', 'shipped')).toBeNull();
    expect(resolveOrderStatusForTrackingEvent('invoiced', 'delivered')).toBeNull();
  });

  it('never advances the order on a partial delivery (no partial OrderStatus exists)', () => {
    expect(resolveOrderStatusForTrackingEvent('shipped', 'partially_delivered')).toBeNull();
  });

  it('never advances the order on non-milestone events', () => {
    expect(resolveOrderStatusForTrackingEvent('invoiced', 'picking_started')).toBeNull();
    expect(resolveOrderStatusForTrackingEvent('shipped', 'adjustment')).toBeNull();
  });
});

describe('shipmentStatusForMilestone', () => {
  it('maps every non-delivery milestone to its shipment status', () => {
    expect(shipmentStatusForMilestone('picking_started')).toBe('picking');
    expect(shipmentStatusForMilestone('packed')).toBe('packed');
    expect(shipmentStatusForMilestone('shipped')).toBe('shipped');
    expect(shipmentStatusForMilestone('in_transit')).toBe('in_transit');
    expect(shipmentStatusForMilestone('out_for_delivery')).toBe('out_for_delivery');
    expect(shipmentStatusForMilestone('returned_to_carrier')).toBe('returned');
  });

  it('never resolves a status for delivery outcomes or adjustment', () => {
    expect(shipmentStatusForMilestone('delivered')).toBeNull();
    expect(shipmentStatusForMilestone('partially_delivered')).toBeNull();
    expect(shipmentStatusForMilestone('adjustment')).toBeNull();
  });
});

describe('buildShipmentPackages', () => {
  const order = buildOrder();

  it('builds valid package records from input', () => {
    const input: ShipmentPackageInput[] = [
      { packageNumber: 1, weightKg: 2.5, items: [{ orderItemId: 'item-1', quantity: 4 }] },
      { packageNumber: 2, items: [{ orderItemId: 'item-2', quantity: 5 }] },
    ];
    const packages = buildShipmentPackages(input, order, new Map());
    expect(packages).toHaveLength(2);
    expect(packages[0]).toEqual({
      packageNumber: 1,
      weightKg: 2.5,
      items: [{ orderItemId: 'item-1', productId: 'product-1', variantId: 'variant-1', quantity: 4 }],
    });
    expect(packages[1].weightKg).toBeNull();
  });

  it('rejects an item that does not belong to the order', () => {
    const input: ShipmentPackageInput[] = [
      { packageNumber: 1, items: [{ orderItemId: 'item-unknown', quantity: 1 }] },
    ];
    expect(() => buildShipmentPackages(input, order, new Map())).toThrow();
  });

  it('rejects a duplicated package number', () => {
    const input: ShipmentPackageInput[] = [
      { packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 1 }] },
      { packageNumber: 1, items: [{ orderItemId: 'item-2', quantity: 1 }] },
    ];
    expect(() => buildShipmentPackages(input, order, new Map())).toThrow();
  });

  it('rejects a quantity exceeding the order item balance across shipments', () => {
    const alreadyShipped = new Map([['item-1', 8]]);
    const input: ShipmentPackageInput[] = [
      { packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 3 }] },
    ];
    expect(() => buildShipmentPackages(input, order, alreadyShipped)).toThrow();
  });

  it('allows shipping exactly the remaining balance across two shipments', () => {
    const alreadyShipped = new Map([['item-1', 6]]);
    const input: ShipmentPackageInput[] = [
      { packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 4 }] },
    ];
    expect(() => buildShipmentPackages(input, order, alreadyShipped)).not.toThrow();
  });

  it('rejects empty packages', () => {
    expect(() => buildShipmentPackages([], order, new Map())).toThrow();
  });
});

describe('sumShippedQuantities', () => {
  it('sums quantities across every non-cancelled shipment', () => {
    const totals = sumShippedQuantities([
      { status: 'shipped', packages: [{ items: [{ orderItemId: 'item-1', quantity: 4 }] }] },
      { status: 'delivered', packages: [{ items: [{ orderItemId: 'item-1', quantity: 2 }] }] },
      { status: 'cancelled', packages: [{ items: [{ orderItemId: 'item-1', quantity: 100 }] }] },
    ]);
    expect(totals.get('item-1')).toBe(6);
  });

  it('returns an empty map for no shipments', () => {
    expect(sumShippedQuantities([]).size).toBe(0);
  });
});

describe('totalQuantityByOrderItem / applyDeliveredItems / resolveDeliveryStatus', () => {
  const packages: ShipmentPackageRecord[] = [
    {
      packageNumber: 1,
      weightKg: null,
      items: [{ orderItemId: 'item-1', productId: 'product-1', variantId: 'variant-1', quantity: 10 }],
    },
    {
      packageNumber: 2,
      weightKg: null,
      items: [{ orderItemId: 'item-2', productId: 'product-2', variantId: 'variant-2', quantity: 5 }],
    },
  ];

  it('totals quantity per order item across packages', () => {
    const totals = totalQuantityByOrderItem(packages);
    expect(totals.get('item-1')).toBe(10);
    expect(totals.get('item-2')).toBe(5);
  });

  it('resolves partially_delivered when at least one item is short', () => {
    const totals = totalQuantityByOrderItem(packages);
    const delivered = applyDeliveredItems([{ orderItemId: 'item-1', quantity: 10 }], totals, new Map());
    expect(resolveDeliveryStatus(totals, delivered)).toBe('partially_delivered');
  });

  it('resolves delivered only once every item reaches its packaged total', () => {
    const totals = totalQuantityByOrderItem(packages);
    let delivered = applyDeliveredItems([{ orderItemId: 'item-1', quantity: 10 }], totals, new Map());
    delivered = applyDeliveredItems([{ orderItemId: 'item-2', quantity: 5 }], totals, delivered);
    expect(resolveDeliveryStatus(totals, delivered)).toBe('delivered');
  });

  it('accumulates delivered quantity across multiple partial delivery events', () => {
    const totals = totalQuantityByOrderItem(packages);
    let delivered = applyDeliveredItems([{ orderItemId: 'item-1', quantity: 4 }], totals, new Map());
    expect(delivered.get('item-1')).toBe(4);
    delivered = applyDeliveredItems([{ orderItemId: 'item-1', quantity: 6 }], totals, delivered);
    expect(delivered.get('item-1')).toBe(10);
  });

  it('never allows delivered quantity to exceed the packaged total', () => {
    const totals = totalQuantityByOrderItem(packages);
    expect(() =>
      applyDeliveredItems([{ orderItemId: 'item-1', quantity: 11 }], totals, new Map()),
    ).toThrow();
  });

  it('rejects a delivered item that was never actually packaged in this shipment', () => {
    const totals = totalQuantityByOrderItem(packages);
    expect(() =>
      applyDeliveredItems([{ orderItemId: 'item-unknown', quantity: 1 }], totals, new Map()),
    ).toThrow();
  });

  it('never mutates the previouslyDelivered map passed in', () => {
    const totals = totalQuantityByOrderItem(packages);
    const previously = new Map([['item-1', 2]]);
    applyDeliveredItems([{ orderItemId: 'item-1', quantity: 3 }], totals, previously);
    expect(previously.get('item-1')).toBe(2);
  });
});

describe('computeTrackingEventId', () => {
  it('is deterministic for the same carrier/shipment/external event tuple', () => {
    const a = computeTrackingEventId('correios', 'shipment-1', 'ext-1');
    const b = computeTrackingEventId('correios', 'shipment-1', 'ext-1');
    expect(a).toBe(b);
  });

  it('differs when any part of the tuple changes', () => {
    const base = computeTrackingEventId('correios', 'shipment-1', 'ext-1');
    expect(computeTrackingEventId('jadlog', 'shipment-1', 'ext-1')).not.toBe(base);
    expect(computeTrackingEventId('correios', 'shipment-2', 'ext-1')).not.toBe(base);
    expect(computeTrackingEventId('correios', 'shipment-1', 'ext-2')).not.toBe(base);
  });
});
