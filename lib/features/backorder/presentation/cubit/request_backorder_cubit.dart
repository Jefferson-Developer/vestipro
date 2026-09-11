import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/usecases/backorder_use_cases.dart';
import '../../domain/value_objects/backorder_origin.dart';
import '../../domain/value_objects/backorder_priority.dart';
import 'request_backorder_state.dart';

/// Drives [RequestBackorderSheet] (TASK-215, EPIC-32) — opens a
/// `BackorderRequest` when a produto/variante does not have enough estoque
/// pronta entrega, always via the `createBackorderRequest` Cloud Function
/// (never a direct Firestore write, `AGENTS.md`).
@injectable
final class RequestBackorderCubit extends Cubit<RequestBackorderState> {
  RequestBackorderCubit(this._createBackorderRequest, this._analyticsService)
    : super(const RequestBackorderState());

  final CreateBackorderRequestUseCase _createBackorderRequest;
  final AnalyticsService _analyticsService;

  Future<void> submit({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required BackorderOrigin origin,
    BackorderPriority priority = BackorderPriority.normal,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    DateTime? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  }) async {
    emit(
      state.copyWith(
        status: RequestBackorderStatus.submitting,
        clearFailureMessage: true,
      ),
    );

    final backorderId = const Uuid().v4();
    final result = await _createBackorderRequest(
      organizationId: organizationId,
      companyId: companyId,
      backorderId: backorderId,
      customerId: customerId,
      productId: productId,
      variantId: variantId,
      sku: sku,
      quantity: quantity,
      origin: origin,
      priority: priority,
      sellerId: sellerId,
      relatedOrderId: relatedOrderId,
      relatedOrderItemId: relatedOrderItemId,
      requestedDeliveryDate: requestedDeliveryDate,
      estimatedUnitPrice: estimatedUnitPrice,
      notes: notes,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            status: RequestBackorderStatus.success,
            lastBackorderId: backorderId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.backorderRequested,
            parameters: <String, Object?>{
              'origin': origin.code,
              'priority': priority.code,
              'quantity': quantity,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: RequestBackorderStatus.failure,
          failureMessage: failure.message,
        ),
      ),
    );
  }
}
