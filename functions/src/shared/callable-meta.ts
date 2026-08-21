import { randomUUID } from 'node:crypto';

/**
 * Metadata `CloudFunctionsService` (the Flutter client wrapper, TASK-015)
 * attaches to every callable request under the reserved `_meta` key —
 * correlation id, app version/build and platform — kept out of each
 * function's own request fields to avoid collisions.
 */
export interface CallableMeta {
  correlationId?: string;
  appVersion?: string;
  buildNumber?: string;
  platform?: string;
}

export interface RequestWithMeta {
  _meta?: CallableMeta;
}

/** The caller's correlation id, or a new one when it sent none. */
export function resolveCorrelationId(meta?: CallableMeta): string {
  return meta?.correlationId?.trim() || randomUUID();
}
