import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/entities/return_request.dart';
import '../../domain/usecases/resolve_return_request_use_case.dart';
import '../../domain/usecases/watch_return_request_queue_use_case.dart';
import '../../domain/value_objects/return_request_status.dart';
import 'return_request_queue_state.dart';

/// Drives the devolução analysis queue (TASK-199, EPIC-30) — every
/// [ReturnRequestStatus.requested] request the caller may decide (
/// [WatchReturnRequestQueueUseCase]'s own visibility scope, reused from
/// pedidos, TASK-102), combined with [ResolveReturnRequestUseCase] for the
/// aprovar/rejeitar action itself.
@injectable
final class ReturnRequestQueueCubit extends Cubit<ReturnRequestQueueState> {
  ReturnRequestQueueCubit(
    this._watchQueue,
    this._resolveReturnRequest,
    this._analyticsService,
  ) : super(const ReturnRequestQueueState());

  final WatchReturnRequestQueueUseCase _watchQueue;
  final ResolveReturnRequestUseCase _resolveReturnRequest;
  final AnalyticsService _analyticsService;

  StreamSubscription<Object?>? _subscription;
  String _organizationId = '';
  String _companyId = '';
  String _userId = '';

  Future<void> watch({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    _organizationId = organizationId;
    _companyId = companyId;
    _userId = userId;
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: ReturnRequestQueueStatus.loading,
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchQueue(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ).listen((result) {
          result.fold(
            onSuccess: (returnRequests) => emit(
              state.copyWith(
                status: returnRequests.isEmpty
                    ? ReturnRequestQueueStatus.empty
                    : ReturnRequestQueueStatus.ready,
                returnRequests: returnRequests,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: ReturnRequestQueueStatus.error,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  Future<void> decide({
    required ReturnRequest returnRequest,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) async {
    emit(
      state.copyWith(
        decisionStatus: ReturnRequestDecisionStatus.deciding,
        decidingReturnRequestId: returnRequest.id,
        clearDecisionFailureMessage: true,
      ),
    );
    final result = await _resolveReturnRequest(
      organizationId: _organizationId,
      companyId: _companyId,
      userId: _userId,
      returnRequestId: returnRequest.id,
      decision: decision,
      reason: reason,
    );
    result.fold(
      onSuccess: (decisionResult) {
        emit(
          state.copyWith(
            decisionStatus: ReturnRequestDecisionStatus.success,
            clearDecidingReturnRequestId: true,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            decision == ReturnRequestDecisionValue.approved
                ? AnalyticsEvents.returnApproved
                : AnalyticsEvents.returnRejected,
            parameters: <String, Object?>{
              'organization_id': _organizationId,
              'order_id': returnRequest.orderId,
              if (decisionResult.resultingOrderStatusLabel != null)
                'resulting_order_status':
                    decisionResult.resultingOrderStatusLabel,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          decisionStatus: ReturnRequestDecisionStatus.failure,
          decisionFailureMessage: failure.message,
          clearDecidingReturnRequestId: true,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
