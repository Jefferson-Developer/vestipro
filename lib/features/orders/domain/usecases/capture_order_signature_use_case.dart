import 'dart:typed_data';

// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent
// `StartOrderDraftForCustomerUseCase` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_signature.dart';
import '../repositories/order_signature_draft_repository.dart';
import '../services/order_content_hasher.dart';
import '../value_objects/order_signature_method.dart';
import '../value_objects/order_signature_status.dart';
import '../value_objects/order_signature_sync_status.dart';
import '../value_objects/order_signer_role.dart';
import '../value_objects/order_status.dart';

/// The [OrderStatus] values a pedido can be in for it to still make sense to
/// sign it (EPIC-13, TASK-180): a `draft`/`pendingSync` order has not even
/// reached the backend yet (this task's own "a assinatura é uma etapa
/// adicional sobre o pedido já submetido/formalizado" precondition), and a
/// `cancelled`/`rejected` order no longer represents a live commercial
/// agreement worth attaching evidence to.
const kSignableOrderStatuses = <OrderStatus>{
  OrderStatus.submitted,
  OrderStatus.underReview,
  OrderStatus.approved,
  OrderStatus.processing,
  OrderStatus.invoiced,
  OrderStatus.partiallyInvoiced,
  OrderStatus.shipped,
  OrderStatus.delivered,
};

/// Captures (and persists 100% offline) the electronic signature closing
/// [order] (EPIC-13, TASK-180) — the seller-facing entry point
/// `OrderSignatureCubit` calls the moment the signer lifts their finger off
/// `OrderSignaturePad`.
///
/// Composes every business rule the task requires instead of letting the
/// BLoC/UI apply any of them ad hoc:
/// 1. [order] must be in one of [kSignableOrderStatuses] — never a
///    `draft`/`pendingSync`/`cancelled`/`rejected` one.
/// 2. This device must not already hold a *valid* signature for this same
///    order ("assinatura nunca pode ser removida ou substituída" — signing
///    twice is rejected outright, never silently overwritten).
/// 3. [OrderContentHasher] stamps the pedido's own content hash *at this
///    exact moment*, so the resulting evidence can later prove what was
///    actually agreed to.
/// 4. Persists the resulting `OrderSignature`
///    ([OrderSignatureSyncStatus.pendingSync]) through
///    [OrderSignatureDraftRepository] — no network call happens anywhere in
///    this call graph; syncing it to `signOrder` is
///    `SubmitOrderSignatureUseCase`'s separate concern, exactly like
///    `Order` itself splits draft-persistence from submission.
@injectable
class CaptureOrderSignatureUseCase {
  const CaptureOrderSignatureUseCase(
    this._repository,
    this._contentHasher,
    this._analyticsService,
  );

  final OrderSignatureDraftRepository _repository;
  final OrderContentHasher _contentHasher;
  final AnalyticsService _analyticsService;

  Future<AppResult<OrderSignature>> call({
    required String id,
    required Order order,
    required OrderSignerRole signerRole,
    required String signedByUserId,
    required String signedByName,
    required Uint8List imageBytes,
    DateTime? now,
  }) async {
    final trimmedSignedByName = signedByName.trim();
    final fieldErrors = <String, String>{};

    if (!kSignableOrderStatuses.contains(order.status)) {
      return AppFailure<OrderSignature>(
        ValidationFailure(
          'This order cannot be signed in its current status.',
          code: 'order_signature_not_signable_status',
          fieldErrors: <String, String>{'status': order.status.name},
        ),
      );
    }
    if (trimmedSignedByName.isEmpty) {
      fieldErrors['signedByName'] = 'SignedByName is required.';
    }
    if (imageBytes.isEmpty) {
      fieldErrors['imageBytes'] = 'A captured signature stroke is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<OrderSignature>(
        ValidationFailure(
          'Invalid order signature capture payload.',
          code: 'invalid_order_signature_capture_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final existingResult = await _repository.getByOrderId(
      organizationId: order.organizationId,
      companyId: order.companyId,
      orderId: order.id,
    );
    if (existingResult case AppFailure<OrderSignature?>(
      failure: final failure,
    )) {
      return AppFailure<OrderSignature>(failure);
    }
    final existing = (existingResult as AppSuccess<OrderSignature?>).value;
    if (existing != null && existing.isValid) {
      return const AppFailure<OrderSignature>(
        ConflictFailure(
          'This order has already been signed. Duplicate the order for a '
          'new version instead of signing it again.',
          code: 'order_signature_already_signed',
        ),
      );
    }

    final resolvedNow = (now ?? DateTime.now()).toUtc();
    final signature = OrderSignature(
      id: id,
      organizationId: order.organizationId,
      companyId: order.companyId,
      orderId: order.id,
      orderNumber: order.orderNumber,
      signerRole: signerRole,
      signedByUserId: signedByUserId,
      signedByName: trimmedSignedByName,
      method: OrderSignatureMethod.canvasDrawn,
      imageBytes: imageBytes,
      contentHash: _contentHasher.hash(order),
      orderVersionAtSignature: order.version,
      signedAt: resolvedNow,
      status: OrderSignatureStatus.valid,
      createdAt: resolvedNow,
      createdBy: signedByUserId,
      updatedAt: resolvedNow,
      updatedBy: signedByUserId,
      version: 1,
      syncStatus: OrderSignatureSyncStatus.pendingSync,
    );

    final saveResult = await _repository.saveLocal(signature: signature);
    if (saveResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<OrderSignature>(failure);
    }

    await _analyticsService.logEvent(
      AnalyticsEvents.orderSignatureCaptured,
      parameters: <String, Object?>{
        'organization_id': signature.organizationId,
        'company_id': signature.companyId,
        'order_id': signature.orderId,
        'signer_role': signature.signerRole.name,
        'method': signature.method.name,
      },
    );
    return AppSuccess<OrderSignature>(signature);
  }
}
