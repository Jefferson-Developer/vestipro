import express, { type NextFunction, type Request, type Response } from 'express';
import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';

import { asyncHandler, authenticateApiKey, requireScope } from './middleware';
import { getCustomerById, listCustomers } from './customers';
import { getProductById, listProducts } from './products';
import { createOrder, getOrderById, listOrders } from './orders';

/**
 * VestiPro's public REST API (TASK-171, EPIC-22) — versioned, API-key-
 * authenticated HTTPS endpoints for partners/external systems to
 * consult/integrate `Customer`/`Product`/`Order` data without going through
 * the app. Deployed as a single Cloud Functions v2 HTTPS function
 * (`publicApiV1`) fronting a small Express router — every route after
 * `authenticateApiKey` only ever sees requests already resolved to a real,
 * active `apiKeys` document and past this minute's rate-limit budget.
 *
 * OAuth 2.0 client-credentials support (marked "opcionalmente" in this
 * task's own backlog) is deliberately out of scope for this pass — API-key
 * auth alone satisfies every "Critério de aceite" this task lists; adding a
 * second auth scheme is a follow-up, not a blocker (see
 * `docs/tasks/TASK-171-implementar-api-publica-CONCLUIDA.md`).
 */
const app = express();
app.use(express.json());
app.use(authenticateApiKey);

app.get('/v1/customers', requireScope('customers:read'), asyncHandler(listCustomers));
app.get('/v1/customers/:id', requireScope('customers:read'), asyncHandler(getCustomerById));

app.get('/v1/products', requireScope('products:read'), asyncHandler(listProducts));
app.get('/v1/products/:id', requireScope('products:read'), asyncHandler(getProductById));

app.get('/v1/orders', requireScope('orders:read'), asyncHandler(listOrders));
app.get('/v1/orders/:id', requireScope('orders:read'), asyncHandler(getOrderById));
app.post('/v1/orders', requireScope('orders:write'), asyncHandler(createOrder));

app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: { code: 'not_found', message: 'Endpoint não encontrado.' } });
});

/* Express only recognizes a 4-argument function as an error-handling
 * middleware; `next` must stay in the signature even though this handler
 * never calls it. */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
  logger.error('publicApiV1 unhandled error', { error });
  if (!res.headersSent) {
    res.status(500).json({ error: { code: 'internal', message: 'Erro interno.' } });
  }
});

export const publicApiV1 = onRequest(app);
