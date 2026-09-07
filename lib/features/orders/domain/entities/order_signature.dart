import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/order_signature_method.dart';
import '../value_objects/order_signature_status.dart';
import '../value_objects/order_signature_sync_status.dart';
import '../value_objects/order_signer_role.dart';

part 'order_signature.freezed.dart';

/// Electronic signature captured for one `Order` (EPIC-13, TASK-180) —
/// "assinatura eletrônica de pedido": an immutable evidence attachment of
/// the pedido's own closing, never a mutation of `Order` itself (the `Order`
/// aggregate is deliberately left untouched by this task — see the
/// CONCLUIDA doc's "Decisões técnicas" for why — this is a sibling record
/// referencing it by [orderId]).
///
/// [organizationId]/[companyId] are resolved from the authenticated
/// session/active organization context, never trusted from a form field —
/// same contract every other tenant-scoped entity in this codebase already
/// follows; the `signOrder` Cloud Function re-validates both server-side
/// before ever persisting this record.
///
/// Immutability contract (`tasks.md`'s own "assinatura nunca pode ser
/// removida ou substituída"): once [status] is [OrderSignatureStatus.valid],
/// nothing in this codebase ever overwrites [imageBytes]/[contentHash]/
/// [signedAt] in place — the only further transition allowed is to
/// [OrderSignatureStatus.invalidated], always with a rastro
/// ([invalidatedAt]/[invalidatedReason]), never a physical delete.
///
/// [contentHash] is the SHA-256 (`OrderContentHasher`) of the signed Order's
/// own canonical content *at the moment of signing* — captured client-side
/// and always re-verified against the Order document's own current state by
/// `signOrder` before this record is ever persisted, so it can later prove
/// the pedido's content was not altered after the signature (or, if the
/// order itself changed since, prove exactly that instead).
///
/// [signedAt] is the *client-captured* instant the signer actually drew the
/// signature — the legally meaningful moment for the commercial process, but
/// not itself server-verifiable (a device clock can be wrong/manipulated).
/// [serverReceivedAt] is the Firestore server timestamp `signOrder` stamps
/// when it *processed* this signature — the authoritative, tamper-proof
/// instant this record answers "when did the platform receive this
/// evidence" with. Both are kept (see the CONCLUIDA doc's "validade
/// jurídica" section for how each is meant to be used).
@freezed
abstract class OrderSignature with _$OrderSignature {
  const OrderSignature._();

  const factory OrderSignature({
    // Client-generated uuid — doubles as this signature's own idempotency
    // key and Firestore document id, same "`Order.id`-as-doc-id" precedent
    // `submitOrder` already established for the order itself.
    required String id,
    required String organizationId,
    required String companyId,
    required String orderId,
    // Denormalized purely for display (receipt/PDF, history screen) — never
    // re-derived from it for any business decision.
    String? orderNumber,
    required OrderSignerRole signerRole,
    // The authenticated seller operating the device the canvas was drawn on
    // — *not* necessarily who [signerRole]/[signedByName] says physically
    // signed (a customer draws on the seller's own device).
    required String signedByUserId,
    required String signedByName,
    required OrderSignatureMethod method,
    // PNG bytes of the canvas capture — kept locally even after a successful
    // sync (never purged), so the comprovante/PDF can always be rendered
    // offline, on this same device, regardless of connectivity.
    required Uint8List imageBytes,
    required String contentHash,
    // `Order.version` at the moment of signing — lets a later reader tell
    // apart "the order changed after this signature" from "this signature
    // still matches the order's current content" without recomputing
    // [contentHash] against historical data it may no longer have.
    required int orderVersionAtSignature,
    required DateTime signedAt,
    // Both `null` until `signOrder` confirms the sync — server-authoritative
    // metadata, never trusted from (or set by) the client itself.
    String? deviceInfo,
    String? ipAddress,
    DateTime? serverReceivedAt,
    String? remoteImageStoragePath,
    @Default(OrderSignatureStatus.valid) OrderSignatureStatus status,
    DateTime? invalidatedAt,
    String? invalidatedReason,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    required int version,
    required OrderSignatureSyncStatus syncStatus,
  }) = _OrderSignature;

  bool get isValid => status == OrderSignatureStatus.valid;
}
