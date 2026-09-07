import 'dart:typed_data';

import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent
// `OrderDraftBloc` already follows.
import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_signature.dart';
import '../../domain/usecases/capture_order_signature_use_case.dart';
import '../../domain/usecases/get_order_signature_use_case.dart';
import '../../domain/usecases/submit_order_signature_use_case.dart';
import '../../domain/value_objects/order_signer_role.dart';
import 'order_signature_state.dart';

/// Drives the "Assinar pedido" flow (EPIC-13, TASK-180): loads whatever
/// signature already exists locally for the order in scope, captures a new
/// one (100% offline) and, connectivity permitting, immediately syncs it —
/// mirrors `OrderDuplicationCubit`'s own single-purpose shape.
///
/// A capture that cannot sync right away (no connectivity) is never treated
/// as a failure of the *capture* itself: [state] still reports
/// [OrderSignatureFlowStatus.captured] with the local, [OrderSignatureSyncStatus
/// .pendingSync] signature — only the sync step's own outcome is separately
/// surfaced, same "pedido continua salvo localmente... pode ser enviado
/// quando a conexão voltar" precedent `submitOrderFromDraft` already
/// established for `Order` itself.
@injectable
final class OrderSignatureCubit extends Cubit<OrderSignatureState> {
  OrderSignatureCubit(
    this._captureOrderSignature,
    this._submitOrderSignature,
    this._getOrderSignature,
    this._analyticsService,
  ) : super(const OrderSignatureState());

  final CaptureOrderSignatureUseCase _captureOrderSignature;
  final SubmitOrderSignatureUseCase _submitOrderSignature;
  final GetOrderSignatureUseCase _getOrderSignature;
  final AnalyticsService _analyticsService;

  final Uuid _uuid = const Uuid();

  Future<void> loadForOrder({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) async {
    emit(
      state.copyWith(
        status: OrderSignatureFlowStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _getOrderSignature(
      organizationId: organizationId,
      companyId: companyId,
      orderId: orderId,
    );
    switch (result) {
      case AppSuccess<OrderSignature?>(value: final signature):
        emit(
          OrderSignatureState(
            status: OrderSignatureFlowStatus.idle,
            signature: signature,
          ),
        );
      case AppFailure<OrderSignature?>(failure: final failure):
        emit(
          state.copyWith(
            status: OrderSignatureFlowStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> captureAndSync({
    required Order order,
    required OrderSignerRole signerRole,
    required String signedByUserId,
    required String signedByName,
    required Uint8List imageBytes,
  }) async {
    emit(
      state.copyWith(
        status: OrderSignatureFlowStatus.capturing,
        clearFailure: true,
      ),
    );
    final captureResult = await _captureOrderSignature(
      id: _uuid.v4(),
      order: order,
      signerRole: signerRole,
      signedByUserId: signedByUserId,
      signedByName: signedByName,
      imageBytes: imageBytes,
    );
    if (captureResult case AppFailure<OrderSignature>(failure: final failure)) {
      emit(
        state.copyWith(
          status: OrderSignatureFlowStatus.failure,
          failure: failure,
        ),
      );
      return;
    }
    final captured = (captureResult as AppSuccess<OrderSignature>).value;
    emit(
      OrderSignatureState(
        status: OrderSignatureFlowStatus.captured,
        signature: captured,
      ),
    );

    emit(state.copyWith(status: OrderSignatureFlowStatus.syncing));
    final submitResult = await _submitOrderSignature(signature: captured);
    switch (submitResult) {
      case AppSuccess<OrderSignature>(value: final synced):
        emit(
          OrderSignatureState(
            status: OrderSignatureFlowStatus.synced,
            signature: synced,
          ),
        );
      case AppFailure<OrderSignature>(failure: final failure):
        // The capture itself already succeeded and is safely persisted
        // locally (`captured`, above) — a sync failure here (most commonly
        // `ConnectivityFailure`) never rolls that back, it only means the
        // signature stays `pendingSync` until a later retry.
        emit(
          OrderSignatureState(
            status: OrderSignatureFlowStatus.captured,
            signature: captured,
            failure: failure is ConnectivityFailure ? null : failure,
          ),
        );
    }
  }

  /// Logs "Ver comprovante" (TASK-180) — kept here (not in the widget layer)
  /// same "no `AnalyticsService` call directly from a widget" convention
  /// every other analytics event in this codebase already follows.
  Future<void> logReceiptViewed({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) {
    return _analyticsService.logEvent(
      AnalyticsEvents.orderReceiptViewed,
      parameters: <String, Object?>{
        'organization_id': organizationId,
        'company_id': companyId,
        'order_id': orderId,
      },
    );
  }
}
