import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/value_objects/order_signature_method.dart';
import '../../domain/value_objects/order_signature_status.dart';
import '../../domain/value_objects/order_signature_sync_status.dart';
import '../../domain/value_objects/order_signer_role.dart';

/// The single place `OrderSignature`'s own value objects convert to/from
/// their wire/storage codes (EPIC-13, TASK-180) — mirrors `OrderMapper`'s
/// own "one place decides the codes" precedent for `Order.status`/
/// `syncStatus`, shared here by both the local (Drift) and remote (Cloud
/// Function) mappers so neither reimplements them.
@lazySingleton
final class OrderSignatureCodec {
  const OrderSignatureCodec();

  String signerRoleToCode(OrderSignerRole role) {
    return switch (role) {
      OrderSignerRole.customer => 'customer',
      OrderSignerRole.seller => 'seller',
    };
  }

  OrderSignerRole signerRoleFromCode(String raw) {
    return switch (raw) {
      'customer' => OrderSignerRole.customer,
      'seller' => OrderSignerRole.seller,
      _ => throw ValidationException(
        'Invalid order signature signerRole "$raw".',
        code: 'invalid_order_signature_signer_role',
      ),
    };
  }

  String methodToCode(OrderSignatureMethod method) {
    return switch (method) {
      OrderSignatureMethod.canvasDrawn => 'canvas_drawn',
      OrderSignatureMethod.externalProvider => 'external_provider',
    };
  }

  OrderSignatureMethod methodFromCode(String raw) {
    return switch (raw) {
      'canvas_drawn' => OrderSignatureMethod.canvasDrawn,
      'external_provider' => OrderSignatureMethod.externalProvider,
      _ => throw ValidationException(
        'Invalid order signature method "$raw".',
        code: 'invalid_order_signature_method',
      ),
    };
  }

  String statusToCode(OrderSignatureStatus status) {
    return switch (status) {
      OrderSignatureStatus.valid => 'valid',
      OrderSignatureStatus.invalidated => 'invalidated',
    };
  }

  OrderSignatureStatus statusFromCode(String raw) {
    return switch (raw) {
      'valid' => OrderSignatureStatus.valid,
      'invalidated' => OrderSignatureStatus.invalidated,
      _ => throw ValidationException(
        'Invalid order signature status "$raw".',
        code: 'invalid_order_signature_status',
      ),
    };
  }

  String syncStatusToCode(OrderSignatureSyncStatus syncStatus) {
    return switch (syncStatus) {
      OrderSignatureSyncStatus.pendingSync => 'pending_sync',
      OrderSignatureSyncStatus.syncing => 'syncing',
      OrderSignatureSyncStatus.synced => 'synced',
      OrderSignatureSyncStatus.failed => 'failed',
    };
  }

  OrderSignatureSyncStatus syncStatusFromCode(String raw) {
    return switch (raw) {
      'pending_sync' => OrderSignatureSyncStatus.pendingSync,
      'syncing' => OrderSignatureSyncStatus.syncing,
      'synced' => OrderSignatureSyncStatus.synced,
      'failed' => OrderSignatureSyncStatus.failed,
      _ => throw ValidationException(
        'Invalid order signature syncStatus "$raw".',
        code: 'invalid_order_signature_sync_status',
      ),
    };
  }
}
