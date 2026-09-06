/**
 * Intentional TypeScript port of `ConflictFieldMerge`
 * (`lib/core/sync/domain/conflict_field_merge.dart`, TASK-110) — this Cloud
 * Functions runtime cannot import Dart code directly, so this is a
 * deliberate, documented duplication kept algorithm-for-algorithm identical
 * (same three-way base/local/remote comparison, same "any single conflicting
 * field blocks the whole merge" behaviour) so an ERP inbound customer update
 * is resolved by the exact same rule TASK-110 already defined and tested for
 * `OutboxEntityType.customer` (TASK-169: "aplicar a mesma política de
 * resolução de conflito já definida no motor de sincronização existente").
 * Any future change to the Dart algorithm must be mirrored here by hand.
 */
export interface ErpFieldMergeResult {
  mergedData: Record<string, unknown>;
  mergedFields: Set<string>;
  conflictingFields: Set<string>;
}

export function computeErpFieldMerge(params: {
  base: Record<string, unknown>;
  local: Record<string, unknown>;
  remote: Record<string, unknown>;
}): ErpFieldMergeResult {
  const { base, local, remote } = params;
  const allKeys = new Set<string>([
    ...Object.keys(base),
    ...Object.keys(local),
    ...Object.keys(remote),
  ]);

  const localChanged = new Set<string>();
  const remoteChanged = new Set<string>();
  for (const key of allKeys) {
    const baseValue = base[key];
    if (!Object.is(local[key], baseValue) && local[key] !== baseValue) {
      localChanged.add(key);
    }
    if (!Object.is(remote[key], baseValue) && remote[key] !== baseValue) {
      remoteChanged.add(key);
    }
  }

  const conflicting = new Set<string>();
  for (const key of localChanged) {
    if (remoteChanged.has(key) && local[key] !== remote[key]) {
      conflicting.add(key);
    }
  }

  if (conflicting.size > 0) {
    return {
      mergedData: {},
      mergedFields: new Set<string>(),
      conflictingFields: conflicting,
    };
  }

  const merged: Record<string, unknown> = { ...remote };
  const mergedFromLocal = new Set<string>();
  for (const key of localChanged) {
    merged[key] = local[key];
    mergedFromLocal.add(key);
  }

  return {
    mergedData: merged,
    mergedFields: mergedFromLocal,
    conflictingFields: new Set<string>(),
  };
}
