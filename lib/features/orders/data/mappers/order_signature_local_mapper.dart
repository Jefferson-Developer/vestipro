import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/order_signature.dart';
import 'order_signature_codec.dart';

/// Maps `OrderSignature` to/from the Drift row backing its offline cache
/// (`OrderSignaturesTable`, TASK-180) — mirrors `OrderLocalMapper`'s own
/// shape for `Order` itself.
@lazySingleton
final class OrderSignatureLocalMapper {
  const OrderSignatureLocalMapper(this._codec);

  final OrderSignatureCodec _codec;

  OrderSignaturesTableCompanion toRow(OrderSignature signature) {
    return OrderSignaturesTableCompanion.insert(
      id: signature.id,
      organizationId: signature.organizationId,
      companyId: signature.companyId,
      orderId: signature.orderId,
      orderNumber: Value(signature.orderNumber),
      signerRole: _codec.signerRoleToCode(signature.signerRole),
      signedByUserId: signature.signedByUserId,
      signedByName: signature.signedByName,
      method: _codec.methodToCode(signature.method),
      imageBytes: signature.imageBytes,
      contentHash: signature.contentHash,
      orderVersionAtSignature: signature.orderVersionAtSignature,
      signedAt: signature.signedAt.toUtc(),
      deviceInfo: Value(signature.deviceInfo),
      ipAddress: Value(signature.ipAddress),
      serverReceivedAt: Value(signature.serverReceivedAt?.toUtc()),
      remoteImageStoragePath: Value(signature.remoteImageStoragePath),
      status: _codec.statusToCode(signature.status),
      invalidatedAt: Value(signature.invalidatedAt?.toUtc()),
      invalidatedReason: Value(signature.invalidatedReason),
      createdAt: signature.createdAt.toUtc(),
      createdBy: signature.createdBy,
      updatedAt: signature.updatedAt.toUtc(),
      updatedBy: signature.updatedBy,
      version: signature.version,
      syncStatus: _codec.syncStatusToCode(signature.syncStatus),
    );
  }

  OrderSignature fromRow(OrderSignaturesTableData row) {
    return OrderSignature(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      orderId: row.orderId,
      orderNumber: row.orderNumber,
      signerRole: _codec.signerRoleFromCode(row.signerRole),
      signedByUserId: row.signedByUserId,
      signedByName: row.signedByName,
      method: _codec.methodFromCode(row.method),
      imageBytes: row.imageBytes,
      contentHash: row.contentHash,
      orderVersionAtSignature: row.orderVersionAtSignature,
      signedAt: row.signedAt.toUtc(),
      deviceInfo: row.deviceInfo,
      ipAddress: row.ipAddress,
      serverReceivedAt: row.serverReceivedAt?.toUtc(),
      remoteImageStoragePath: row.remoteImageStoragePath,
      status: _codec.statusFromCode(row.status),
      invalidatedAt: row.invalidatedAt?.toUtc(),
      invalidatedReason: row.invalidatedReason,
      createdAt: row.createdAt.toUtc(),
      createdBy: row.createdBy,
      updatedAt: row.updatedAt.toUtc(),
      updatedBy: row.updatedBy,
      version: row.version,
      syncStatus: _codec.syncStatusFromCode(row.syncStatus),
    );
  }
}
